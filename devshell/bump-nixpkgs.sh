# Bumps nixpkgs for everything:
# - this flake's nixpkgs
# - this flake's home-manager,
# - homelab-subflake base
# - homelab-subflake home-manager
#
# Then creates a commit with trailer `Updated-Inputs: nixpkgs`, old -> new per
# input in the body. Find past bumps with:
#
#   git log --date=short --format='%ad %h %s' --grep='Updated-Inputs: nixpkgs'
#
# `--release 26.11` also moves the release branches (nixpkgs, home-manager).

release=""
while [ $# -gt 0 ]; do
  case $1 in
    --release)
      release=${2:?--release needs a version, e.g. 26.11}
      shift 2
      ;;
    *)
      echo "Usage: bump-nixpkgs [--release YY.MM]" >&2
      exit 1
      ;;
  esac
done

cd "$(git rev-parse --show-toplevel)"
top_inputs=(nixpkgs nixpkgs-unstable nixpkgs-lib home-manager)
homelab_inputs=(base home-manager)
files=(flake.nix flake.lock homelab-subflake/flake.nix homelab-subflake/flake.lock)

if ! git diff --quiet HEAD -- "${files[@]}"; then
  echo "Uncommitted changes in ${files[*]}: commit or stash them first" >&2
  exit 1
fi

# `<rev> (<date>)` of a direct input in a lock file
describe() {
  jq -r --arg i "$2" '
    .nodes[.nodes.root.inputs[$i]].locked
    | "\(.rev[0:7]) (\(.lastModified | strftime("%Y-%m-%d")))"' "$1"
}

declare -A before
for i in "${top_inputs[@]}"; do before[$i]=$(describe flake.lock "$i"); done
before[homelab/home-manager]=$(describe homelab-subflake/flake.lock home-manager)

summary="chore: bump nixpkgs"
if [ -n "$release" ]; then
  current=$(grep -oP '^\s*nixpkgs\.url = "nixpkgs/nixos-\K[0-9]{2}\.[0-9]{2}' flake.nix)
  if [ "$current" = "$release" ]; then
    echo "Already on $release" >&2
    exit 1
  fi
  sed -i -E \
    -e "s|^(\s*nixpkgs\.url = \"nixpkgs/nixos-)$current\"|\1$release\"|" \
    -e "s|^(\s*home-manager\.url = \"github:rycee/home-manager/release-)$current\"|\1$release\"|" \
    flake.nix
  sed -i -E "s|(\"github:nix-community/home-manager/release-)$current\"|\1$release\"|" \
    homelab-subflake/flake.nix
  summary="chore: move to nixos-$release"
fi

nix flake update "${top_inputs[@]}"
(cd homelab-subflake && nix flake update "${homelab_inputs[@]}")

if git diff --quiet -- "${files[@]}"; then
  echo "✅ Nothing to bump"
  exit 0
fi

body=""
for i in "${top_inputs[@]}"; do
  after=$(describe flake.lock "$i")
  [ "${before[$i]}" = "$after" ] || body+="$i: ${before[$i]} -> $after"$'\n'
done
after=$(describe homelab-subflake/flake.lock home-manager)
[ "${before[homelab/home-manager]}" = "$after" ] ||
  body+="homelab/home-manager: ${before[homelab/home-manager]} -> $after"$'\n'

msg=$(git interpret-trailers --trailer "Updated-Inputs: nixpkgs" <<EOF
$summary

$body
EOF
)
git commit -m "$msg" -- "${files[@]}"
echo "✅ $(git log -1 --format='%h %s')"
echo "$body"
