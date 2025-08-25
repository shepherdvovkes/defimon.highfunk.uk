#!/bin/zsh

# Apply Kubernetes secrets from plaintext secrets.env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_FILE="$PROJECT_ROOT/secrets.env"
NAMESPACE="defimon"

if [ ! -f "$SECRETS_FILE" ]; then
  echo "secrets.env not found at $SECRETS_FILE"
  exit 1
fi

# Load secrets
set -a
source "$SECRETS_FILE"
set +a

# Create or update secret in K8s
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

kubectl -n $NAMESPACE delete secret defimon-secrets --ignore-not-found

kubectl -n $NAMESPACE create secret generic defimon-secrets \
  --from-literal=JWT_SECRET_KEY="$JWT_SECRET_KEY" \
  --from-literal=ADMIN_DASHBOARD_SECRET_KEY="$ADMIN_DASHBOARD_SECRET_KEY" \
  --from-literal=ANALYTICS_API_SECRET_KEY="$ANALYTICS_API_SECRET_KEY" \
  --from-literal=AI_ML_SERVICE_SECRET_KEY="$AI_ML_SERVICE_SECRET_KEY" \
  --from-literal=GOOGLE_CLOUD_SQL_PASSWORD="$GOOGLE_CLOUD_SQL_PASSWORD" \
  --from-literal=ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY:-}" \
  --from-literal=POLYGONSCAN_API_KEY="${POLYGONSCAN_API_KEY:-}" \
  --from-literal=ARBISCAN_API_KEY="${ARBISCAN_API_KEY:-}" \
  --from-literal=OPTIMISTIC_ETHERSCAN_API_KEY="${OPTIMISTIC_ETHERSCAN_API_KEY:-}" \
  --from-literal=SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}" \
  --from-literal=TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}" \
  --from-literal=TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secrets applied to namespace $NAMESPACE"
