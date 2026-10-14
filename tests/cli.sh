#!/bin/bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd -P)
cli="$repo_root/agent-notify/agent-notify"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/agent-notify-cli.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

fake_bin="$test_root/bin"
mkdir -p "$fake_bin" "$test_root/home"
cat > "$fake_bin/terminal-notifier" <<'FAKE_TERMINAL'
#!/bin/bash
printf 'CALL\n' >> "$FAKE_TERMINAL_CALLS"
for arg in "$@"; do printf 'ARG:%s\n' "$arg" >> "$FAKE_TERMINAL_CALLS"; done
exit "${FAKE_TERMINAL_EXIT:-0}"
FAKE_TERMINAL
cat > "$fake_bin/curl" <<'FAKE_CURL'
#!/bin/bash
printf 'CALL\n' >> "$FAKE_CURL_CALLS"
for arg in "$@"; do printf 'ARG:%s\n' "$arg" >> "$FAKE_CURL_CALLS"; done
call_number=$(grep -Fc 'CALL' "$FAKE_CURL_CALLS")
cat > "${FAKE_CURL_CONFIG}.${call_number}"
cp "${FAKE_CURL_CONFIG}.${call_number}" "$FAKE_CURL_CONFIG"
if grep -Fq 'https://worker.example/' "${FAKE_CURL_CONFIG}.${call_number}"; then
  exit "${FAKE_CURL_WORKER_EXIT:-0}"
fi
exit "${FAKE_CURL_PUBLIC_EXIT:-0}"
FAKE_CURL
cat > "$fake_bin/less" <<'FAKE_LESS'
#!/bin/bash
printf 'CALL\n' >> "$FAKE_LESS_CALLS"
for arg in "$@"; do printf 'ARG:%s\n' "$arg" >> "$FAKE_LESS_CALLS"; done
FAKE_LESS
chmod +x "$fake_bin/terminal-notifier" "$fake_bin/curl" "$fake_bin/less"

export PATH="$fake_bin:$PATH"
export FAKE_TERMINAL_CALLS="$test_root/terminal-calls"
export FAKE_CURL_CALLS="$test_root/curl-calls"
export FAKE_CURL_CONFIG="$test_root/curl-config"
export FAKE_LESS_CALLS="$test_root/less-calls"
export AGENT_NOTIFY_ENV_FILE="$test_root/bark.env"
export AGENT_NOTIFY_WORKER_ENV_FILE="$test_root/worker.env"
export HOME="$test_root/home"
printf 'BARK_KEY=test-public-key\n' > "$AGENT_NOTIFY_ENV_FILE"
: > "$FAKE_TERMINAL_CALLS"
: > "$FAKE_CURL_CALLS"
: > "$FAKE_LESS_CALLS"

default_log="$HOME/Library/Logs/agent-notifications.log"
"$cli" --title 'Codex test' 'Mac default at /tmp/report.zip'
[[ $(grep -Fc 'CALL' "$FAKE_TERMINAL_CALLS") -eq 1 ]]
[[ $(grep -Fc 'CALL' "$FAKE_CURL_CALLS") -eq 0 ]]
grep -Fq 'ARG:-title' "$FAKE_TERMINAL_CALLS"
grep -Fq 'ARG:-sound' "$FAKE_TERMINAL_CALLS"
grep -Fq 'ARG:default' "$FAKE_TERMINAL_CALLS"
grep -Fq 'ARG:Codex test' "$FAKE_TERMINAL_CALLS"
grep -Fq 'ARG:Mac default at /tmp/report.zip' "$FAKE_TERMINAL_CALLS"
grep -Fq 'Target: mac' "$default_log"
grep -Fq 'Working directory: '"$repo_root" "$default_log"
grep -Fq 'Message:' "$default_log"
grep -Fq 'Mac default at /tmp/report.zip' "$default_log"
grep -Fq 'Timestamp: 20' "$default_log"

"$cli" --target iphone --title 'Codex test' 'Public Bark route'
[[ $(grep -Fc 'CALL' "$FAKE_CURL_CALLS") -eq 1 ]]
grep -Fq 'url = "https://api.day.app/test-public-key"' "$FAKE_CURL_CONFIG.1"
grep -Fq 'ARG:--data-urlencode' "$FAKE_CURL_CALLS"
grep -Fq 'ARG:title=Codex test' "$FAKE_CURL_CALLS"
grep -Fq 'ARG:body=Public Bark route' "$FAKE_CURL_CALLS"
grep -Fq 'Target: iphone' "$default_log"
grep -Fq 'Public Bark route' "$default_log"
grep -Fq 'Result: api.day.app succeeded' "$default_log"
! grep -Fq 'test-public-key' "$default_log"
! grep -Fq 'test-public-key' "$FAKE_CURL_CALLS"

printf 'BARK_KEY=test-worker-key\nBARK_SERVER_URL=https://worker.example/\n' > "$AGENT_NOTIFY_WORKER_ENV_FILE"
"$cli" --target iphone --title 'Codex test' 'Worker route'
[[ $(grep -Fc 'CALL' "$FAKE_CURL_CALLS") -eq 2 ]]
grep -Fq 'url = "https://worker.example/test-worker-key"' "$FAKE_CURL_CONFIG.2"
grep -Fq 'Result: Worker succeeded' "$default_log"

if FAKE_CURL_WORKER_EXIT=6 FAKE_CURL_PUBLIC_EXIT=0 "$cli" --target iphone --title 'Codex test' 'Worker fallback'; then
  :
else
  printf 'expected public fallback to succeed after Worker failure\n' >&2
  exit 1
fi
[[ $(grep -Fc 'CALL' "$FAKE_CURL_CALLS") -eq 4 ]]
grep -Fq 'url = "https://worker.example/test-worker-key"' "$FAKE_CURL_CONFIG.3"
grep -Fq 'url = "https://api.day.app/test-public-key"' "$FAKE_CURL_CONFIG.4"
grep -Fq 'Result: Worker failed (curl exit 6); api.day.app fallback succeeded' "$default_log"
! grep -Fq 'test-worker-key' "$default_log"
! grep -Fq 'test-worker-key' "$FAKE_CURL_CALLS"

if FAKE_TERMINAL_EXIT=1 "$cli" --target both 'Independent target attempts' 2>/dev/null; then
  printf 'expected both-target command to report its Mac failure\n' >&2
  exit 1
fi
[[ $(grep -Fc 'CALL' "$FAKE_TERMINAL_CALLS") -eq 2 ]]
[[ $(grep -Fc 'CALL' "$FAKE_CURL_CALLS") -eq 5 ]]
grep -Fq 'Target: mac' "$default_log"
grep -Fq 'Result: command failed' "$default_log"
grep -Fq 'Target: iphone' "$default_log"
grep -Fq 'Independent target attempts' "$default_log"

if FAKE_CURL_WORKER_EXIT=7 FAKE_CURL_PUBLIC_EXIT=22 "$cli" --target iphone 'Bark failure is logged' 2>/dev/null; then
  printf 'expected the command to report both Bark routes failing\n' >&2
  exit 1
fi
[[ $(grep -Fc 'CALL' "$FAKE_CURL_CALLS") -eq 7 ]]
grep -Fq 'Bark failure is logged' "$default_log"
grep -Fq 'Result: Worker failed (curl exit 7); api.day.app fallback failed (curl exit 22)' "$default_log"
[[ $(grep -Fc -- '--- notification attempt ---' "$default_log") -eq 7 ]]

"$cli" logs
[[ $(grep -Fc 'CALL' "$FAKE_LESS_CALLS") -eq 1 ]]
grep -Fq 'ARG:+G' "$FAKE_LESS_CALLS"
grep -Fq "ARG:$default_log" "$FAKE_LESS_CALLS"

printf 'CLI verification passed: Mac sound, public Bark, Worker-first delivery, public fallback, independent both, append-only log, log viewer, and provider failures.\n'
exit 0
