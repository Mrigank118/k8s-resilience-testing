#!/bin/bash

set -e

# =========================
# CONFIGURATION
# =========================
PROJECT_DIR="$HOME/Documents/Github/k8s-resilience-testing"

# Colors (minimal)
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

log() {
  echo -e "${YELLOW}[INFO]${RESET} $1"
}

success() {
  echo -e "${GREEN}[OK]${RESET} $1"
}

error() {
  echo -e "${RED}[ERROR]${RESET} $1"
}

# =========================
# VALIDATE PROJECT
# =========================
log "Checking project directory"

if [ ! -d "$PROJECT_DIR" ]; then
  error "Project directory not found: $PROJECT_DIR"
  exit 1
fi

cd "$PROJECT_DIR"
success "Using project directory: $PROJECT_DIR"

# =========================
# START MINIKUBE
# =========================
log "Starting Minikube"

minikube start --driver=docker

success "Minikube started"
kubectl get nodes

# =========================
# CREATE NAMESPACES
# =========================
log "Creating namespaces"

kubectl create namespace notes 2>/dev/null || true
kubectl create namespace litmus 2>/dev/null || true
kubectl create namespace monitoring 2>/dev/null || true

kubectl get ns
success "Namespaces ready"

# =========================
# DEPLOY APPLICATION
# =========================
log "Deploying application"

kubectl apply -f k8s/sqlite-pvc.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

log "Waiting for application pods"

kubectl wait --for=condition=ready pod --all -n notes --timeout=120s

kubectl get pods -n notes
success "Application deployed"

# =========================
# ACCESS FRONTEND
# =========================
log "Opening frontend service"

minikube service canary-frontend -n notes

# =========================
# METRICS SERVER
# =========================
log "Enabling metrics server"

minikube addons enable metrics-server
sleep 10

kubectl top pods -n notes || log "Metrics not ready yet"

# =========================
# INSTALL HELM (IF MISSING)
# =========================
if ! command -v helm &> /dev/null; then
  error "Helm is not installed. Install Helm before running this script."
  exit 1
fi

# =========================
# PROMETHEUS + GRAFANA
# =========================
log "Installing Prometheus and Grafana"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

log "Waiting for monitoring stack"

kubectl wait --for=condition=ready pod --all -n monitoring --timeout=180s

kubectl get pods -n monitoring
success "Monitoring stack ready"

# =========================
# GRAFANA ACCESS
# =========================
log "Retrieving Grafana credentials"

PASSWORD=$(kubectl get secret -n monitoring kube-prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana Username: admin"
echo "Grafana Password: $PASSWORD"

log "Opening Grafana service"

minikube service kube-prometheus-grafana -n monitoring

# =========================
# INSTALL LITMUS
# =========================
log "Installing LitmusChaos"

kubectl apply -f https://litmuschaos.github.io/litmus/litmus-operator-v3.0.0.yaml
kubectl apply -f https://litmuschaos.github.io/litmus/litmus-crds-v3.0.0.yaml

sleep 20

kubectl get pods -n litmus
success "Litmus installed"

# =========================
# ACCESS CHAOSCENTER
# =========================
log "Opening ChaosCenter"

minikube service litmusportal-frontend-service -n litmus

# =========================
# FINAL STATUS
# =========================
echo ""
echo "===== SYSTEM STATUS ====="

echo "Namespaces:"
kubectl get ns

echo ""
echo "Application Pods:"
kubectl get pods -n notes

echo ""
echo "Monitoring Pods:"
kubectl get pods -n monitoring

echo ""
echo "Litmus Pods:"
kubectl get pods -n litmus

success "Setup complete"