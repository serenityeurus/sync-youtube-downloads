#!/usr/bin/env bash
# Tests for sync-youtube-downloads. Usage: tests/test.sh [--help]
set -uo pipefail
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: tests/test.sh   Run the sync-youtube-downloads test suite (exit 1 on failure)"; exit 0
fi
Root=$(cd "$(dirname "$0")/.." && pwd)
S="$Root/sync-youtube-downloads"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
check() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); printf 'FAIL: %s\n  want: %s\n  got:  %s\n' "$1" "$3" "$2"; fi; }

Profile=$(sed -n 's/^PROFILE_MUSIC_VIDEOS=//p' "$Root/sync-youtube-downloads.example.env")
export SYD_ENV_FILE="$Root/sync-youtube-downloads.example.env"

cat > "$T/src.md" <<'X'
# Musicians

https://www.youtube.com/channel/UCaaa # Alpha
- https://www.youtube.com/channel/UCbbb # Beta [missing since 2026-11-01]
https://www.youtube.com/channel/UCccc
https://www.youtube.com/channel/UCaaa # Alpha again
  https://www.youtube.com/channel/UCddd   #  Delta  
some note
X
printf 'https://www.youtube.com/channel/UCccc/ | old # Gamma' > "$T/dest.txt"   # no trailing newline

"$S" "$T/src.md" "$T/dest.txt" music-videos 2>/dev/null
check "profile run exit" "$?" 0
check "line 1 kept" "$(sed -n 1p "$T/dest.txt")" "https://www.youtube.com/channel/UCccc/ | old # Gamma"
check "appended with profile" "$(sed -n 2p "$T/dest.txt")" "https://www.youtube.com/channel/UCaaa $Profile # Alpha"
check "missing marker kept, bullet dropped" "$(sed -n 3p "$T/dest.txt")" "https://www.youtube.com/channel/UCbbb $Profile # Beta [missing since 2026-11-01]"
check "trimmed comment" "$(sed -n 4p "$T/dest.txt")" "https://www.youtube.com/channel/UCddd $Profile #  Delta"
check "line count" "$(wc -l < "$T/dest.txt" | tr -d ' ')" 4
check "profile string literal" "$Profile" "| --no-match-filters --match-filter title~='(?i)music video|official video' --match-filter \"title!~='(?i)lyric video|visualizer|visualiser' & description~='(?i)music video|official video'\""

before=$(cksum < "$T/dest.txt")
"$S" "$T/src.md" "$T/dest.txt" music-videos 2>/dev/null
check "idempotent" "$(cksum < "$T/dest.txt")" "$before"

"$S" "$T/src.md" "$T/new.txt" 2>/dev/null
check "new dest created" "$(wc -l < "$T/new.txt" | tr -d ' ')" 4
check "no profile, no comment" "$(sed -n 3p "$T/new.txt")" "https://www.youtube.com/channel/UCccc"
check "no profile line" "$(sed -n 1p "$T/new.txt")" "https://www.youtube.com/channel/UCaaa # Alpha"

: > "$T/empty.txt"; "$S" "$T/src.md" "$T/empty.txt" 2>/dev/null
check "empty dest" "$(wc -l < "$T/empty.txt" | tr -d ' ')" 4

out=$("$S" --dry-run "$T/src.md" "$T/dry.txt" music-videos 2>/dev/null)
check "dry run prints" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')" 4
check "dry run writes nothing" "$([ -e "$T/dry.txt" ] && echo yes || echo no)" no

"$S" "$T/src.md" "$T/x.txt" nope 2>/dev/null; check "unknown profile exit" "$?" 2
"$S" "$T/missing" "$T/x.txt" 2>/dev/null; check "missing source exit" "$?" 1
"$S" "$T/src.md" 2>/dev/null; check "too few args exit" "$?" 2
SYD_ENV_FILE=/nonexistent "$S" "$T/src.md" "$T/x.txt" music-videos 2>/dev/null; check "missing env file exit" "$?" 2
SYD_ENV_FILE=/nonexistent "$S" "$T/src.md" "$T/y.txt" 2>/dev/null; check "no profile needs no env file" "$?" 0
"$S" --help >/dev/null; check "--help exit" "$?" 0

echo "passed $pass, failed $fail"
[ "$fail" -eq 0 ]
