#!/bin/bash
set -e

# Генерируем JWT секрет
openssl rand -hex 32 > /jwtsecret

# Запускаем geth
exec geth \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=eth,net,web3,debug,txpool,personal,admin \
  --http.vhosts=* \
  --http.corsdomain=* \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.origins=* \
  --ws.api=eth,net,web3,debug,txpool,personal,admin \
  --datadir=/root/.ethereum \
  --syncmode=full \
  --cache=8192 \
  --database.cache=4096 \
  --trie.cache=256 \
  --snapshot.cache=256 \
  --state.cache=256 \
  --maxpeers=50 \
  --discovery.v5 \
  --metrics \
  --metrics.addr=0.0.0.0 \
  --metrics.port=6060 \
  --authrpc.disable \
  --override.terminaltotaldifficulty=0 \
  --override.mergeforkblock=0 \
  --override.shanghaiblock=0 \
  --override.cancunblock=0 \
  --override.pragueblock=0
