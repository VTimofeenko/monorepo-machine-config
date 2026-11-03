# Bumps inputs across both flakes (this one and homelab-subflake, whose
# nixpkgs follow this one's through `base`) as one commit. The trailer
# `Updated-Inputs: <mode>` and an `old -> new` line per changed input in the
# body make bumps findable:
#
#   git log --date=short --format='%ad %h %s' --grep='^Updated-Inputs: nixpkgs$'
#
# Modes:
#   nixpkgs [--release YY.MM]  stable nixpkgs + home-manager; --release also
#                              moves their release branches
#   nixpkgs-unstable           nixpkgs-unstable (+ nixpkgs-lib), meant to run often
#   all                        every input in both flakes

mode=${1:?mode: nixpkgs, nixpkgs-unstable or all}
shift
release=""
while [ $# -gt 0 ]; do
  case $1 in
    --release)
      [ "$mode" = nixpkgs ] || { echo "--release is for the nixpkgs mode" >&2; exit 1; }
      release=${2:?--release needs a version, e.g. 26.11}
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# Inputs to update per flake; empty = all of them
case $mode in
  nixpkgs)
    top=(nixpkgs home-manager)
    homelab=(base home-manager)
    ;;
  nixpkgs-unstable)
    top=(nixpkgs-unstable nixpkgs-lib)
    homelab=(base)
    ;;
  all)
    top=()
    homelab=()
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    exit 1
    ;;
esac

cd "$(git rev-parse --show-toplevel)"
files=(flake.nix flake.lock homelab-subflake/flake.nix homelab-subflake/flake.lock)

if ! git diff --quiet HEAD -- "${files[@]}"; then
  echo "Uncommitted changes in ${files[*]}: commit or stash them first" >&2
  exit 1
fi

# `<flake>/<input>\t<rev> (<date>)` for every direct, non-path input
snapshot() {
  for lock in flake.lock homelab-subflake/flake.lock; do
    jq -r --arg flake "$(dirname "$lock")" '
      .nodes as $n
      | .nodes.root.inputs | to_entries[]
      | select(.value | type == "string")
      | .key as $k
      | $n[.value].locked
      | select(.type != "path")
      | "\($flake)/\($k)\t\((.rev // .narHash)[0:7]) (\(.lastModified | strftime("%Y-%m-%d")))"' "$lock"
  done
}

declare -A before
while IFS=$'\t' read -r input version; do before[$input]=$version; done < <(snapshot)

case $mode in
  nixpkgs) summary="chore: bump nixpkgs" ;;
  nixpkgs-unstable) summary="chore: bump nixpkgs-unstable" ;;
  all) summary="chore: bump all inputs" ;;
esac

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

nix flake update "${top[@]}"
(cd homelab-subflake && nix flake update "${homelab[@]}")

if git diff --quiet -- "${files[@]}"; then
  echo "✅ Nothing to bump"
  exit 0
fi

body=""
while IFS=$'\t' read -r input version; do
  [ "${before[$input]:-}" = "$version" ] || body+="${input#./}: ${before[$input]:-new} -> $version"$'\n'
done < <(snapshot)

msg=$(git interpret-trailers --trailer "Updated-Inputs: $mode" <<EOF
$summary

$body
EOF
)
git commit -m "$msg" -- "${files[@]}"
echo "✅ $(git log -1 --format='%h %s')"
echo "$body"
