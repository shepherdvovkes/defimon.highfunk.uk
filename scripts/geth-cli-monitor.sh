#!/usr/bin/env bash
set -euo pipefail

# Simple CLI monitor for Geth sync progress via JSON-RPC
# Requirements: curl, jq

RPC_URL="${RPC_URL:-http://localhost:8545}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-5}"
GETH_CONTAINER="${GETH_CONTAINER:-geth-full-node}"
ENABLE_SPLIT="${ENABLE_SPLIT:-1}"
LOG_PANE_LINES="${LOG_PANE_LINES:-auto}"
SESSION_NAME="${SESSION_NAME:-gethmon}"
KILL_EXISTING="${KILL_EXISTING:-1}"
TMUX_SOCKET="${TMUX_SOCKET:-gethmon}"

# Ensure TERM is sane for tmux
export TERM="${TERM:-xterm-256color}"

# Resolve script absolute path for tmux spawned pane
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"

# Resolve LOG_PANE_LINES when set to auto (default): use half of terminal height
if [ "${LOG_PANE_LINES}" = "auto" ]; then
  if command -v tput >/dev/null 2>&1; then
    total_lines=$(tput lines 2>/dev/null || echo 24)
  else
    total_lines=24
  fi
  case "$total_lines" in
    ''|*[!0-9]*) total_lines=24 ;;
  esac
  LOG_PANE_LINES=$(( total_lines / 2 ))
  [ "$LOG_PANE_LINES" -lt 10 ] && LOG_PANE_LINES=10
fi

# If split requested and tmux is available and we're not already inside tmux, launch split view
if [ "${MONITOR_ONLY:-0}" != "1" ] && [ "$ENABLE_SPLIT" = "1" ] && command -v tmux >/dev/null 2>&1 && [ -z "${TMUX:-}" ]; then
  # Wrap tmux operations to gracefully fallback on any error
  {
    # Kill existing session if requested
    if tmux -L "$TMUX_SOCKET" has-session -t "$SESSION_NAME" 2>/dev/null && [ "$KILL_EXISTING" = "1" ]; then
      tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION_NAME" || true
    fi

    # Ensure session exists (create if missing)
    if ! tmux -L "$TMUX_SOCKET" has-session -t "$SESSION_NAME" 2>/dev/null; then
      tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION_NAME" \
        "MONITOR_ONLY=1 RPC_URL=$RPC_URL INTERVAL_SECONDS=$INTERVAL_SECONDS GETH_CONTAINER=$GETH_CONTAINER ENABLE_SPLIT=0 LOG_PANE_LINES=$LOG_PANE_LINES SESSION_NAME=$SESSION_NAME KILL_EXISTING=$KILL_EXISTING TMUX_SOCKET=$TMUX_SOCKET bash -c '$SCRIPT_PATH'"
      tmux -L "$TMUX_SOCKET" split-window -t "$SESSION_NAME":0 -v -l "$LOG_PANE_LINES" \
        "docker logs -f --tail 200 $GETH_CONTAINER | sed -u -e 's/\x1b\[[0-9;]*[a-zA-Z]//g'"
      tmux -L "$TMUX_SOCKET" select-pane -t "$SESSION_NAME":0.0 || true
    fi

    # Attach (if fails due to no sessions, we fallback below)
    tmux -L "$TMUX_SOCKET" attach-session -t "$SESSION_NAME"
    exit 0
  } || {
    echo "[warn] tmux split failed (server may have exited unexpectedly). Falling back to single-pane monitor." >&2
    MONITOR_ONLY=1
    ENABLE_SPLIT=0
  }
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required. Please install curl." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Please install jq (e.g., sudo apt-get install -y jq)." >&2
  exit 1
fi

hex_to_dec() {
  local hex="$1"
  hex=${hex#0x}
  if [ -z "$hex" ]; then echo 0; return; fi
  printf "%d\n" $((16#$hex))
}

get_rpc() {
  local method="$1"; shift
  local params_json="$1"
  curl -s -X POST -H 'Content-Type: application/json' \
    --data "{\"jsonrpc\":\"2.0\",\"method\":\"${method}\",\"params\":${params_json},\"id\":1}" \
    "$RPC_URL"
}

# Safer formatting: passthrough unless numfmt is available
format_num() {
  local n="$1"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --grouping "$n" 2>/dev/null || echo "$n"
  else
    echo "$n"
  fi
}

human_time() {
  local seconds=$1
  if [ "$seconds" -le 0 ]; then echo "0s"; return; fi
  local d=$((seconds/86400))
  local h=$(( (seconds%86400)/3600 ))
  local m=$(( (seconds%3600)/60 ))
  local s=$(( seconds%60 ))
  local out=""
  [ $d -gt 0 ] && out+="${d}d "
  [ $h -gt 0 ] && out+="${h}h "
  [ $m -gt 0 ] && out+="${m}m "
  out+="${s}s"
  echo "$out"
}

previous_block=-1
previous_ts=0

trap 'tput cnorm 2>/dev/null || true; exit 0' INT TERM

while true; do
  now_ts=$(date +%s)

  syncing_json=$(get_rpc eth_syncing '[]')
  syncing_result=$(echo "$syncing_json" | jq -r '.result')

  chain_id_hex=$(get_rpc eth_chainId '[]' | jq -r '.result')
  chain_id=$(hex_to_dec "$chain_id_hex")

  peers_hex=$(get_rpc net_peerCount '[]' | jq -r '.result')
  peers=$(hex_to_dec "$peers_hex")

  gas_price_hex=$(get_rpc eth_gasPrice '[]' | jq -r '.result')
  gas_price_wei=$(hex_to_dec "$gas_price_hex")
  gas_price_gwei=$(awk -v w=$gas_price_wei 'BEGIN { printf("%.2f", w/1000000000) }')

  clear
  tput civis 2>/dev/null || true

  echo "Geth CLI Monitor (RPC: $RPC_URL)"
  echo "Chain ID: $chain_id | Peers: $peers | Gas Price: ${gas_price_gwei} gwei"
  echo "Time: $(date)"
  echo "------------------------------------------------------------"

  if [ "$syncing_result" = "false" ]; then
    head_hex=$(get_rpc eth_blockNumber '[]' | jq -r '.result')
    head_block=$(hex_to_dec "$head_hex")
    echo "Status: SYNCED"
    echo "Head Block: $head_block"
    echo "Lag Blocks: 0"
    echo "Speed: -"
    echo "ETA: -"
  else
    starting_hex=$(echo "$syncing_result" | jq -r '.startingBlock')
    current_hex=$(echo "$syncing_result" | jq -r '.currentBlock')
    highest_hex=$(echo "$syncing_result" | jq -r '.highestBlock')

    starting=$(hex_to_dec "$starting_hex")
    current=$(hex_to_dec "$current_hex")
    highest=$(hex_to_dec "$highest_hex")

    pulled_states_hex=$(echo "$syncing_result" | jq -r '.pulledStates // "0x0"')
    known_states_hex=$(echo "$syncing_result" | jq -r '.knownStates // "0x0"')
    pulled_states=$(hex_to_dec "$pulled_states_hex")
    known_states=$(hex_to_dec "$known_states_hex")

    lag_blocks=$(( highest > current ? highest - current : 0 ))

    speed_bps="-"
    eta_str="-"
    if [ $previous_block -ge 0 ]; then
      delta_blocks=$(( current - previous_block ))
      delta_time=$(( now_ts - previous_ts ))
      if [ $delta_time -gt 0 ] && [ $delta_blocks -ge 0 ]; then
        speed=$(awk -v b=$delta_blocks -v t=$delta_time 'BEGIN { if (t>0) printf("%.2f", b/t); else print 0 }')
        speed_bps="$speed blk/s"
        if [ $lag_blocks -gt 0 ]; then
          eta=$(awk -v lag=$lag_blocks -v s=$speed 'BEGIN { if (s>0) printf("%d", lag/s); else print -1 }')
          if [ "$eta" -ge 0 ] 2>/dev/null; then
            eta_str=$(human_time "$eta")
          else
            eta_str="-"
          fi
        fi
      fi
    fi

    previous_block=$current
    previous_ts=$now_ts

    progress="-"
    if [ $highest -gt 0 ]; then
      progress=$(awk -v c=$current -v h=$highest 'BEGIN { if (h>0) printf("%.2f", (c*100.0)/h); else print 0 }')
    fi

    echo "Status: SYNCING"
    echo "Starting Block: $starting"
    echo "Current Block:  $current"
    echo "Highest Block:  $highest"
    echo "Lag Blocks:     $lag_blocks"
    echo "Progress:       ${progress}%"
    echo "Speed:          $speed_bps"
    echo "ETA:            $eta_str"
    if [ $known_states -gt 0 ]; then
      states_progress=$(awk -v p=$pulled_states -v k=$known_states 'BEGIN { if (k>0) printf("%.2f", (p*100.0)/k); else print 0 }')
      echo "State Sync:     $pulled_states / $known_states (${states_progress}%)"
    fi
  fi

  echo "------------------------------------------------------------"
  if [ "${MONITOR_ONLY:-0}" = "1" ]; then
    echo "Logs are shown in the bottom pane (tmux)."
  else
    echo "tmux split enabled (SESSION_NAME=$SESSION_NAME). Existing session will be killed automatically."
    echo "Tuning: LOG_PANE_LINES=auto|<lines>, SESSION_NAME=<name>"
  fi
  echo "Ctrl+C to exit | Refresh every ${INTERVAL_SECONDS}s"
  sleep "$INTERVAL_SECONDS"

done
