# Rewrites nix/sources.json with the newest stable + nightly T3 Code .deb.
# Hashes come from electron-builder's update manifests, so no .deb download.
# Run via `nix run .#update` (expects curl, jq, yq-go on PATH).
# Optional: GITHUB_TOKEN to dodge API rate limits in CI.

repo="pingdotgg/t3code"
api="https://api.github.com/repos/$repo"
dl="https://github.com/$repo/releases/download"
out="${1:-nix/sources.json}"

gh_api() {
  curl -fsSL -H "Accept: application/vnd.github+json" \
    ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} "$api/$1"
}

# entry <tag> <manifest> -> {"version","url","hash"}
entry() {
  local tag="$1" manifest="$2" yml version deb sha512
  yml=$(curl -fsSL "$dl/$tag/$manifest")
  version=$(yq -r '.version' <<<"$yml")
  deb=$(yq -r '.files[] | select(.url | test("amd64\\.deb$")) | .url' <<<"$yml")
  sha512=$(yq -r '.files[] | select(.url | test("amd64\\.deb$")) | .sha512' <<<"$yml")
  [[ -n "$deb" && "$deb" != null ]] || { echo "no amd64 deb in $tag/$manifest" >&2; exit 1; }
  jq -n --arg v "$version" --arg u "$dl/$tag/$deb" --arg h "sha512-$sha512" \
    '{version: $v, url: $u, hash: $h}'
}

stable_tag=$(gh_api releases/latest | jq -r '.tag_name')
nightly_tag=$(gh_api "releases?per_page=30" |
  jq -r '[.[] | select(.draft | not) | select(.tag_name | test("-nightly\\."))][0].tag_name')

[[ -n "$stable_tag" && "$stable_tag" != null ]] || { echo "no stable release" >&2; exit 1; }
[[ -n "$nightly_tag" && "$nightly_tag" != null ]] || { echo "no nightly release" >&2; exit 1; }

jq -n --argjson s "$(entry "$stable_tag" latest-linux.yml)" \
      --argjson n "$(entry "$nightly_tag" nightly-linux.yml)" \
      '{stable: $s, nightly: $n}' > "$out.tmp"
mv "$out.tmp" "$out"

echo "stable  -> $stable_tag"
echo "nightly -> $nightly_tag"
