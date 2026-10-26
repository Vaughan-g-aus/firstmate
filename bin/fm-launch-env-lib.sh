# shellcheck shell=bash
# Launch environment (config/launch-env-allowlist) and the codex model catalog
# that a launch reads through it. bin/fm-spawn.sh owns the launch itself; this
# library exists so the start-up check in bin/fm-bootstrap.sh answers "would
# fm-spawn pass codex max for this model?" with the launch's own code path
# instead of a second parser that drifts.
#
# fm_launch_env_load <config-dir>
#   Sets LAUNCH_ENV_ENABLED (1 when config/launch-env-allowlist is present, 0
#   otherwise) and LAUNCH_ENV_NAMES (one allowlisted environment name per
#   line). Returns non-zero with the error on stderr when the allowlist is not
#   a readable regular file or holds anything but names, blank lines, and
#   comments. Requires bin/fm-config-inherit-lib.sh for fm_config_source_present.
#
# codex_catalog_path
#   The models_cache.json the launched codex will read, from CODEX_HOME when
#   the launch passes it through and $HOME/.codex otherwise. Under
#   config/launch-env-allowlist the launch runs through `env -i`, so a
#   CODEX_HOME that is not allowlisted is unset there and codex falls back to
#   $HOME/.codex (HOME is in the fixed floor). Reads LAUNCH_ENV_ENABLED and
#   LAUNCH_ENV_NAMES as fm_launch_env_load left them.
#
# codex_catalog_usable <cache>
#   True when the catalog is readable, jq is available, and the catalog parses
#   with a models array, so its answer about any model is authoritative.
#
# codex_model_advertises_effort <cache> <model> <effort>
#   True when the usable catalog lists <effort> in the supported_reasoning_levels
#   of the model whose slug is <model>. An unusable catalog, an unlisted model,
#   or the default model answers false.
#
# codex_max_effort_launches <cache> <model>
#   The one decision rule for codex max: true when the model's catalog entry
#   advertises max, or when the model is gpt-5.6-luna and the catalog is
#   unusable, in which case Luna keeps its long-standing max as a fallback.
#   fm-spawn passes model_reasoning_effort="max" exactly when this is true, and
#   bootstrap accepts a codex max profile exactly when this is true.

fm_launch_env_load() { # <config-dir>
  local config=$1
  LAUNCH_ENV_ENABLED=$(fm_config_source_present "$config/launch-env-allowlist") || return 1
  LAUNCH_ENV_NAMES=
  [ "$LAUNCH_ENV_ENABLED" = 1 ] || return 0
  if [ ! -f "$config/launch-env-allowlist" ] || [ ! -r "$config/launch-env-allowlist" ]; then
    echo "error: config/launch-env-allowlist must be a readable regular file" >&2
    return 1
  fi
  if ! LAUNCH_ENV_NAMES=$(jq -Rrs '
    split("\n") | map(select(. != "" and (startswith("#") | not))) |
    if all(.[]; test("^[A-Za-z_][A-Za-z0-9_]*$")) then .[]
    else error("expected environment names only") end
  ' "$config/launch-env-allowlist" 2>/dev/null); then
    echo "error: config/launch-env-allowlist must contain one environment name per line, blank lines, or # comments" >&2
    return 1
  fi
}

codex_catalog_path() {
  local codex_home=${CODEX_HOME:-}
  if [ "${LAUNCH_ENV_ENABLED:-0}" = 1 ]; then
    case $'\n'"${LAUNCH_ENV_NAMES:-}"$'\n' in
    *$'\nCODEX_HOME\n'*) ;;
    *) codex_home= ;;
    esac
  fi
  printf '%s\n' "${codex_home:-${HOME:-}/.codex}/models_cache.json"
}

codex_catalog_usable() { # <cache>
  command -v jq >/dev/null 2>&1 && [ -r "$1" ] &&
    jq -e '.models | type == "array"' "$1" >/dev/null 2>&1
}

codex_model_advertises_effort() { # <cache> <model> <effort>
  local cache=$1 model=$2 effort=$3
  [ -n "$model" ] && [ "$model" != default ] || return 1
  codex_catalog_usable "$cache" || return 1
  jq -e --arg m "$model" --arg e "$effort" \
    'any(.models[]? | select(.slug == $m) | .supported_reasoning_levels[]?; (.effort? // .) == $e)' \
    "$cache" >/dev/null 2>&1
}

codex_max_effort_launches() { # <cache> <model>
  local cache=$1 model=$2
  codex_model_advertises_effort "$cache" "$model" max ||
    { [ "$model" = gpt-5.6-luna ] && ! codex_catalog_usable "$cache"; }
}
