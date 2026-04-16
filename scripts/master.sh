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
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# =========================
# VALIDATE PROJECT
# =========================
log "Checking project directory"

cd "$PROJECT_DIR" || { error "Project directory not found"; exit 1; }
success "Using project directory: $PROJECT_DIR"

# =========================
# START MINIKUBE
# =========================
log "Starting Minikube"

minikube start --driver=docker

kubectl get nodes
success "Minikube ready"

# =========================
# NAMESPACES
# =========================
log "Creating namespaces"

kubectl create ns notes 2>/dev/null || true
kubectl create ns monitoring 2>/dev/null || true
kubectl create ns litmus 2>/dev/null || true

kubectl get ns
success "Namespaces ready"

# =========================
# DEPLOY APP
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
success "Application deployed"

# =========================
# OPEN FRONTEND
# =========================
log "Opening frontend"
minikube service canary-frontend -n notes

# =========================
# METRICS SERVER
# =========================
log "Enabling metrics-server"

minikube addons enable metrics-server

kubectl wait --for=condition=available deployment metrics-server -n kube-system --timeout=120s || true

kubectl top pods -n notes || log "Metrics still warming up"

# =========================
# HELM CHECK
# =========================
command -v helm >/dev/null || { error "Helm not installed"; exit 1; }

# =========================
# PROMETHEUS + GRAFANA
# =========================
log "Installing monitoring stack"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

helm upgrade --install kube-prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace

log "Waiting for monitoring pods"

kubectl wait --for=condition=ready pod --all -n monitoring --timeout=300s

kubectl get pods -n monitoring
success "Monitoring ready"

# =========================
# GRAFANA ACCESS
# =========================
log "Grafana credentials"

PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana Username: admin"
echo "Grafana Password: $PASSWORD"

log "Opening Grafana"
minikube service kube-prometheus-grafana -n monitoring

# =========================
# INSTALL MONGODB (LITMUS)
# =========================
log "Installing MongoDB for Litmus"

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

log "Waiting for MongoDB"

kubectl wait --for=condition=ready pod --all -n litmus --timeout=300s

# =========================
# INSTALL LITMUS
# =========================
log "Installing LitmusChaos"

kubectl apply -f https://raw.githubusercontent.com/litmuschaos/litmus/master/mkdocs/docs/3.20.0/litmus-getting-started.yaml -n litmus

log "Waiting for Litmus pods"

kubectl wait --for=condition=ready pod --all -n litmus --timeout=300s || true

kubectl get pods -n litmus
success "Litmus ready"

# =========================
# OPEN CHAOSCENTER
# =========================
log "Opening ChaosCenter"

minikube service litmusportal-frontend-service -n litmus

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

success "SETUP COMPLETE"