#!/usr/bin/env bash
set -euo pipefail

# Simple CLI monitor for Geth sync progress via JSON-RPC
# Requirements: curl, jq

RPC_URL="${RPC_URL:-http://localhost:8545}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-5}"

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
  # strip 0x
  hex=${hex#0x}
  # default to 0 if empty
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

format_num() {
  # thousands separators
  awk '{printf "%'")}{print}' 2>/dev/null || echo "$1"
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
  # gwei = wei / 1e9
  gas_price_gwei=$(awk -v w=$gas_price_wei 'BEGIN { printf("%.2f", w/1000000000) }')

  clear
  tput civis 2>/dev/null || true

  echo "Geth CLI Monitor (RPC: $RPC_URL)"
  echo "Chain ID: $chain_id | Peers: $peers | Gas Price: ${gas_price_gwei} gwei"
  echo "Time: $(date)"
  echo "------------------------------------------------------------"

  if [ "$syncing_result" = "false" ]; then
    # Fully synced
    head_hex=$(get_rpc eth_blockNumber '[]' | jq -r '.result')
    head_block=$(hex_to_dec "$head_hex")
    echo "Status: SYNCED"
    echo "Head Block: $head_block"
    echo "Lag Blocks: 0"
    echo "Speed: -"
    echo "ETA: -"
  else
    # Syncing object
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
        # blocks per second
        speed=$(awk -v b=$delta_blocks -v t=$delta_time 'BEGIN { if (t>0) printf("%.2f", b/t); else print 0 }')
        speed_bps="$speed blk/s"
        # eta seconds
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

    # progress percent
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
  echo "Ctrl+C to exit | Refresh every ${INTERVAL_SECONDS}s"
  sleep "$INTERVAL_SECONDS"

done
