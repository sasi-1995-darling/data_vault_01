#!/usr/bin/env bash
#
# cache_hit_check.sh — read prompt-cache hit rate and effective token cost off a
# VS Code Copilot agent session log. Zero-dependency (bash + awk), no LLM, no network.
#
# Usage:
#   bash scripts/automation/cache_hit_check.sh                       # newest session log
#   bash scripts/automation/cache_hit_check.sh path/to/main.jsonl    # a specific log file
#   bash scripts/automation/cache_hit_check.sh path/to/session-dir   # dir holding main.jsonl
#
# Reads per-call "inputTokens"/"cachedTokens"/"outputTokens"/"ts" fields from the log.
# Effective-cost model: uncached billed at 1x, cached at 0.1x (Anthropic cache-read is
# ~10x cheaper). Cache-write (~1.25x) is ignored, so the effective % UNDERstates
# slightly. A "cold start" = a call with cachedTokens == 0 (whole prompt reprocessed
# at full price because the prompt cache went cold — idle or dispatch exceeded the
# cache window; measured warm window ~3.8-6.5 min, not a pinned TTL).
#
# Missing cachedTokens field: some model telemetries (e.g. Opus) OMIT cachedTokens
# instead of writing an explicit 0 — verified across logs: sessions that report the
# field never emit cachedTokens:0, and the omitted lines are large full-context calls.
# So an absent field is read as zero cache (a full-price cold read). If NO call in a
# log reports the field, the cache split is UNKNOWN and the effective % is only an
# upper bound (a caveat is printed at the end for that case).
set -euo pipefail

log="${1:-}"

if [[ -z "$log" ]]; then
  # newest main.jsonl across ALL VS Code installs (desktop macOS / Linux / Windows,
  # plus Remote-WSL / SSH / devcontainer servers under ~/.vscode-server). Collect
  # candidates from every base, then pick the globally newest with a single `ls -t`
  # over the union — so a later base still wins if it holds a newer log (don't break
  # on the first base that merely has *a* log).
  shopt -s nullglob
  candidates=()
  for base in \
    "$HOME/Library/Application Support/Code/User/workspaceStorage" \
    "$HOME/Library/Application Support/Code - Insiders/User/workspaceStorage" \
    "$HOME/.config/Code/User/workspaceStorage" \
    "$HOME/.config/Code - Insiders/User/workspaceStorage" \
    "${APPDATA:-$HOME/AppData/Roaming}/Code/User/workspaceStorage" \
    "$HOME/.vscode-server/data/User/workspaceStorage" \
    "$HOME/.vscode-server-insiders/data/User/workspaceStorage"; do
    candidates+=( "$base"/*/GitHub.copilot-chat/debug-logs/*/main.jsonl )
  done
  shopt -u nullglob
  if [[ ${#candidates[@]} -gt 0 ]]; then
    # shellcheck disable=SC2012  # UUID paths (no special chars); one ls -t over all bases = global newest
    log="$(ls -t "${candidates[@]}" 2>/dev/null | head -1 || true)"
  fi
fi

if [[ -d "$log" ]]; then
  log="$log/main.jsonl"
fi

if [[ -z "$log" || ! -f "$log" ]]; then
  echo "No session log found. Pass a path to a main.jsonl file (or a directory containing one)." >&2
  echo "Auto-discovery looks under your VS Code User dir, e.g.:" >&2
  echo "  macOS: ~/Library/Application Support/Code/User/workspaceStorage/*/GitHub.copilot-chat/debug-logs/*/main.jsonl" >&2
  echo "  Linux: ~/.config/Code/User/workspaceStorage/*/GitHub.copilot-chat/debug-logs/*/main.jsonl" >&2
  echo "  Windows: %APPDATA%/Code/User/workspaceStorage/*/GitHub.copilot-chat/debug-logs/*/main.jsonl" >&2
  echo "  WSL/remote: ~/.vscode-server/data/User/workspaceStorage/*/GitHub.copilot-chat/debug-logs/*/main.jsonl" >&2
  exit 1
fi

echo "Analyzing: $log"
echo

awk '
/"inputTokens"/{
  it=ct=ot=ts=0; hascache=0
  if(match($0,/"inputTokens":[[:space:]]*[0-9]+/)){x=substr($0,RSTART,RLENGTH);gsub(/[^0-9]/,"",x);it=x+0}
  if(match($0,/"cachedTokens":[[:space:]]*[0-9]+/)){x=substr($0,RSTART,RLENGTH);gsub(/[^0-9]/,"",x);ct=x+0;hascache=1}
  if(match($0,/"outputTokens":[[:space:]]*[0-9]+/)){x=substr($0,RSTART,RLENGTH);gsub(/[^0-9]/,"",x);ot=x+0}
  if(match($0,/"ts":[[:space:]]*[0-9]+/)){x=substr($0,RSTART,RLENGTH);gsub(/[^0-9]/,"",x);ts=x+0}
  n++; SIT+=it; SCT+=ct; SOT+=ot; UNC+=(it-ct)
  if(hascache){have++}else{nocache++}
  gap=(prev>0&&ts>0)?(ts-prev)/1000.0:0; prev=ts
  tag=""
  if(ct==0){
    if(n==1){ tag="  <-- initial call (cache warm-up, expected; not counted below)" }
    else { tag="  <<< COLD START"; coldn++; coldunc+=it }
  }
  printf "%3d  gap=%6.0fs  in=%-8d cached=%-8d uncached=%-8d hit%%=%3.0f%s\n", n, gap, it, ct, it-ct, (it>0?100.0*ct/it:0), tag
}
END{
  if(n==0){ print "No per-call token records (inputTokens) found in this log."; exit }
  printf "\n=== TOTALS (%d calls) ===\n", n
  printf "input = %d   output = %d   input:output = %.1f : 1\n", SIT, SOT, (SOT>0?1.0*SIT/SOT:0)
  printf "cached = %.1f%% of input    uncached (full-price) = %d\n", (SIT>0?100.0*SCT/SIT:0), UNC
  printf "mid-session cold-starts = %d   (= %.0f%% of full-price input)\n", coldn, (UNC>0?100.0*coldunc/UNC:0)
  eff=UNC+0.1*SCT
  printf "effective input billed ~= uncached + 0.1*cached = %.0f   (%.1f%% of raw input)\n", eff, (SIT>0?100.0*eff/SIT:0)
  if(have==0){
    print ""
    print "  !! No call in this log reported a cachedTokens field, so the cache split is UNKNOWN."
    print "     All input is billed at full rate above -> read the effective % as an UPPER BOUND,"
    print "     not a measured cache hit rate (this model may not emit cache accounting)."
  }
  print ""
  print "Notes:"
  print "  - INPUT tokens only; output tokens are billed separately (and priced higher), so this is a"
  print "    prompt-cost proxy, not total cost."
  print "  - Assumes cache-read = 0.1x base input; ignores cache-write (~1.25x), so this UNDERstates slightly."
  if(nocache>0 && have>0){
    printf "  - %d of %d calls omitted the cachedTokens field; this telemetry omits it to mean zero\n", nocache, n
    print  "    cache read (it never writes an explicit cachedTokens:0), so those are counted as cold reads."
  }
  print "  - This report shows inter-call GAPS, not their cause. To classify a cold-start,"
  print "    check what filled the gap in the session log:"
  print "      * a long USER gap at a STOP gate -> likely idle-at-gate (fixable: respond within ~3 min);"
  print "      * a long subagent dispatch -> likely structural (dbt/Snowflake ran past the cache window)."
}' "$log"
