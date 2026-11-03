/**
  CI script. Runs `nix-update` on one package of this flake, builds it and
  pushes the result to `bump/<package>`, opening (or refreshing) a PR against
  `$BASE_BRANCH`. A failed build still gets a PR, marked `WIP:` (Gitea draft
  marker) with the log tail, so the branch can be pulled and fixed by hand.

  The branch is left alone if it has commits not authored by the bot, so
  manual fixes on it are not force-pushed over. If it already holds exactly
  this bump on top of the current base and its PR isn't WIP, nothing is
  rebuilt.

  Without arguments, bumps every package in $TARGETS one by one, starting each
  from origin/$BASE_BRANCH (discards local changes to tracked files).

  ```
  Usage: package-bump [<flake attr> [extra nix-update args...]]
  Env: GITEA_TOKEN, GITEA_API_URL (<gitea>/api/v1/repos/<owner>/<repo>),
       BASE_BRANCH (default: master),
       TARGETS: nix file with { <attr> = { args ? [ ]; skipPatch ? false; }; },
                required without arguments. `args` go to nix-update;
                `skipPatch` ignores bumps that keep major.minor.
  ```
  Git identity must be configured.
*/
{
  writeShellApplication,
  nix-update,
  jq,
  curl,
  git,
  gnused,
  coreutils,
}:
writeShellApplication {
  name = "package-bump";
  runtimeInputs = [
    nix-update
    jq
    curl
    git
    gnused
    coreutils
  ];
  text = ''
    : "''${GITEA_TOKEN:?GITEA_TOKEN must be set}"
    : "''${GITEA_API_URL:?GITEA_API_URL must be set}"
    BASE="''${BASE_BRANCH:-master}"
    cd "$(git rev-parse --show-toplevel)"
    TARGETS_JSON="{}"
    if [ -n "''${TARGETS:-}" ]; then
      TARGETS_JSON=$(nix eval --json -f "$TARGETS")
    fi

    if [ "$#" -eq 0 ]; then
      : "''${TARGETS:?TARGETS must be set to bump all targets}"
      FAILED=()
      for P in $(jq -r 'keys[]' <<< "$TARGETS_JSON"); do
        echo "::group::$P"
        git checkout -q -f --detach "origin/$BASE"
        "$0" "$P" || FAILED+=("$P")
        echo "::endgroup::"
      done
      if [ "''${#FAILED[@]}" -gt 0 ]; then
        echo "Failed: ''${FAILED[*]}" >&2
        exit 1
      fi
      exit 0
    fi

    PKG="$1"
    shift
    mapfile -t TARGET_ARGS < <(jq -r --arg p "$PKG" '.[$p].args // [] | .[]' <<< "$TARGETS_JSON")
    SKIP_PATCH=$(jq -r --arg p "$PKG" '.[$p].skipPatch // false' <<< "$TARGETS_JSON")
    BRANCH="bump/$PKG"
    BOT_EMAIL=$(git config user.email)
    WORK=$(mktemp -d)
    trap 'rm -rf "$WORK"' EXIT

    src_ref() {
      nix eval --raw ".#$PKG.src" --apply \
        's: let t = s.tag or null; in if t != null then t else s.rev or ""' 2>/dev/null || true
    }

    # /nix/store/<hash>-source/flake-modules-prime/<mod>/package.nix:12
    MOD=$(nix eval --raw ".#$PKG.meta.position" | sed -nE 's|^/nix/store/[^/]+/flake-modules-prime/([^/]+)/.*|\1|p')
    if [ -z "$MOD" ]; then
      echo "$PKG does not live in flake-modules-prime/" >&2
      exit 1
    fi

    api() {
      curl -sSf -H "Authorization: token $GITEA_TOKEN" -H "Content-Type: application/json" "$@"
    }

    # Open PR for $BRANCH as JSON, or nothing
    find_pr() {
      api "$GITEA_API_URL/pulls?state=open&limit=50" \
        | jq -c --arg b "$BRANCH" 'map(select(.head.ref == $b)) | .[0] // empty'
    }

    REMOTE_SHA=""
    if git fetch -q origin "$BRANCH" 2>/dev/null; then
      REMOTE_SHA=$(git rev-parse FETCH_HEAD)
      if git log --format=%ae "origin/$BASE..$REMOTE_SHA" | grep -qvxF "$BOT_EMAIL"; then
        echo "$BRANCH has manual commits, not touching it"
        exit 0
      fi
    fi

    OLD_VERSION=$(nix eval --raw ".#$PKG.version")
    OLD_REF=$(src_ref)
    HOMEPAGE=$(nix eval --raw ".#$PKG.src.meta.homepage" 2>/dev/null || true)

    UPDATE_OK=true
    nix-update --flake "$PKG" "''${TARGET_ARGS[@]}" "$@" 2>&1 | tee "$WORK/update.log" || UPDATE_OK=false

    if git diff --quiet; then
      if $UPDATE_OK; then
        echo "$PKG is up to date"
        exit 0
      fi
      echo "nix-update failed without changes" >&2
      exit 1
    fi

    NEW_VERSION=$(nix eval --raw ".#$PKG.version")
    if [ "$SKIP_PATCH" = true ] && [ "$(cut -d. -f1-2 <<< "$OLD_VERSION")" = "$(cut -d. -f1-2 <<< "$NEW_VERSION")" ]; then
      echo "$PKG: ignoring patch release $NEW_VERSION"
      git checkout -q -f .
      exit 0
    fi

    # Same tree as the pushed branch => same inputs, same build result. Only
    # skip if that result was a success; a WIP may have been a flaky fetch.
    git add -A
    if [ -n "$REMOTE_SHA" ] && [ "$(git write-tree)" = "$(git rev-parse "$REMOTE_SHA^{tree}")" ]; then
      PR_TITLE=$(find_pr | jq -r '.title // empty')
      if [ -n "$PR_TITLE" ] && [[ "$PR_TITLE" != WIP:* ]]; then
        echo "$BRANCH already proposes this bump"
        exit 0
      fi
    fi

    NEW_REF=$(src_ref)

    BUILD_OK=false
    if $UPDATE_OK; then
      nix build ".#$PKG" -L --no-link 2>&1 | tee "$WORK/build.log" && BUILD_OK=true
    fi

    TITLE="chore(mod:$MOD): bump $PKG $OLD_VERSION -> $NEW_VERSION"
    git checkout -B "$BRANCH"
    git commit -q -m "$TITLE"
    git push -f origin "$BRANCH"

    if $BUILD_OK; then
      STATUS="✅ \`nix build .#$PKG\` succeeded."
    else
      TITLE="WIP: $TITLE"
      if $UPDATE_OK; then
        STATUS="❌ \`nix build .#$PKG\` failed."
        FAILED_LOG="$WORK/build.log"
      else
        STATUS="❌ \`nix-update\` failed; the branch has its partial changes."
        FAILED_LOG="$WORK/update.log"
      fi
    fi

    # Releases between the old and new ref; GitHub and Gitea share the shape
    NOTES=""
    if [[ "$HOMEPAGE" =~ ^https://([^/]+)/([^/]+/[^/]+)$ ]]; then
      HOST="''${BASH_REMATCH[1]}"
      REPO="''${BASH_REMATCH[2]}"
      if [ "$HOST" = github.com ]; then
        RELEASES_URL="https://api.github.com/repos/$REPO/releases?per_page=30"
      else
        RELEASES_URL="https://$HOST/api/v1/repos/$REPO/releases?limit=30"
      fi
      NOTES=$(curl -sSf "$RELEASES_URL" | jq -r --arg old "$OLD_REF" '
        (map(.tag_name) | index($old)) as $i
        | (if $i == null then .[:1] else .[:$i] end)[]
        | "### \(.name // .tag_name)\n\n\(.body // "")\n"' || true)
    fi

    {
      if [ -n "$HOMEPAGE" ] && [ -n "$OLD_REF" ] && [ -n "$NEW_REF" ]; then
        echo "\`$PKG\`: $OLD_VERSION → $NEW_VERSION ([compare]($HOMEPAGE/compare/$OLD_REF...$NEW_REF))"
      else
        echo "\`$PKG\`: $OLD_VERSION → $NEW_VERSION"
      fi
      echo
      echo "$STATUS"
      if [ -n "''${FAILED_LOG:-}" ]; then
        echo
        echo "<details><summary>Log (last 80 lines)</summary>"
        echo
        echo '```'
        tail -n 80 "$FAILED_LOG"
        echo '```'
        echo "</details>"
      fi
      if [ -n "$NOTES" ]; then
        echo
        echo "<details><summary>Release notes</summary>"
        echo
        echo "$NOTES"
        echo "</details>"
      fi
    } > "$WORK/body.md"

    PAYLOAD=$(jq -n \
      --arg title "$TITLE" \
      --arg head "$BRANCH" \
      --arg base "$BASE" \
      --rawfile body "$WORK/body.md" \
      '{title: $title, head: $head, base: $base, body: $body}')

    PR=$(find_pr | jq -r '.number // empty')
    if [ -n "$PR" ]; then
      api -X PATCH "$GITEA_API_URL/pulls/$PR" -d "$PAYLOAD" > /dev/null
      echo "Updated PR #$PR"
    else
      PR=$(api -X POST "$GITEA_API_URL/pulls" -d "$PAYLOAD" | jq -r .number)
      echo "Opened PR #$PR"
    fi
  '';
}
