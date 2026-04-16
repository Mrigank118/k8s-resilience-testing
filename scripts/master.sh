#!/bin/bash

set -euo pipefail

# =========================
# CONFIG
# =========================
PROJECT_DIR="$HOME/Documents/GitHub/k8s-resilience-testing"

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

log() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
ok() { echo -e "${GREEN}[OK]${RESET} $1"; }
err() { echo -e "${RED}[ERROR]${RESET} $1"; }

# =========================
# VALIDATE PROJECT
# =========================
log "Checking project directory"
cd "$PROJECT_DIR" || { err "Project directory not found"; exit 1; }
ok "Using project directory: $PROJECT_DIR"

# =========================
# START MINIKUBE
# =========================
log "Starting Minikube"
minikube start --driver=docker
kubectl get nodes
ok "Minikube ready"

# =========================
# NAMESPACES
# =========================
log "Ensuring namespaces"
kubectl create ns notes 2>/dev/null || true
kubectl create ns monitoring 2>/dev/null || true
kubectl create ns litmus 2>/dev/null || true
kubectl get ns
ok "Namespaces ready"

# =========================
# LITMUS (MONGO + CHAOSCENTER) FIRST
# =========================
log "Installing MongoDB (Litmus backend)"

helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update

cat <<EOF > mongo-values.yml
auth:
  enabled: true
  rootPassword: "1234"

architecture: replicaset
replicaCount: 3

persistence:
  enabled: true

volumePermissions:
  enabled: true
EOF

helm upgrade --install my-release bitnami/mongodb \
  --values mongo-values.yml \
  -n litmus --create-namespace

log "Waiting for MongoDB pods"
kubectl get pods -n litmus
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mongodb -n litmus --timeout=300s || true

log "Installing LitmusChaos"
kubectl apply -f https://raw.githubusercontent.com/litmuschaos/litmus/master/mkdocs/docs/3.20.0/litmus-getting-started.yaml -n litmus

log "Waiting for ChaosCenter (frontend/server/auth)"
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/component=frontend \
  -n litmus --timeout=180s || true

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/component=server \
  -n litmus --timeout=180s || true

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/component=auth-server \
  -n litmus --timeout=180s || true

kubectl get pods -n litmus
ok "Litmus ready"

log "Opening ChaosCenter"
minikube service litmusportal-frontend-service -n litmus || true

# =========================
# DEPLOY APPLICATION
# =========================
log "Deploying application"

kubectl apply -f k8s/sqlite-pvc.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

log "Waiting for app pods"
kubectl wait --for=condition=ready pod --all -n notes --timeout=180s

kubectl get pods -n notes
ok "Application deployed"

log "Opening frontend"
minikube service canary-frontend -n notes || true

# =========================
# METRICS SERVER
# =========================
log "Enabling metrics-server"
minikube addons enable metrics-server

kubectl wait --for=condition=available deployment metrics-server -n kube-system --timeout=120s || true
kubectl top pods -n notes || log "Metrics warming up"

# =========================
# MONITORING (ONLY kube-prometheus-stack)
# =========================
log "Installing monitoring stack (kube-prometheus-stack)"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

log "Waiting for Grafana + Prometheus (core only)"

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=grafana \
  -n monitoring --timeout=180s || true

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=prometheus \
  -n monitoring --timeout=180s || true

kubectl get pods -n monitoring
ok "Monitoring ready"

# =========================
# GRAFANA ACCESS
# =========================
log "Fetching Grafana credentials"

PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana Username: admin"
echo "Grafana Password: $PASSWORD"

log "Opening Grafana"
minikube service kube-prometheus-grafana -n monitoring || true

# =========================
# FINAL STATUS
# =========================
echo ""
echo "===== SYSTEM STATUS ====="

echo "App:"
kubectl get pods -n notes

echo ""
echo "Monitoring:"
kubectl get pods -n monitoring

echo ""
echo "Litmus:"
kubectl get pods -n litmus

ok "SETUP COMPLETE 🚀"