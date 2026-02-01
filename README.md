
# Canary-Resilience

Canary-Resilience is a minimal notes application deployed on Kubernetes.
It is used as a **system under test** for studying Kubernetes behavior, persistence, and resilience under failures.

The application consists of a frontend UI and a backend API with SQLite persistence.

---

## Prerequisites

* Docker
* kubectl
* Minikube (or any Kubernetes cluster)

---

## Docker Images

The application uses prebuilt images:

* Backend: `mrigankwastaken/canary-resilience-backend:latest`
* Frontend: `mrigankwastaken/canary-resilience-frontend:latest`

Images are pulled directly by Kubernetes.
Local builds are not required to run the app.

---

## Running the Application (Minikube)

### 1. Start Minikube

```
minikube start --driver=docker
```

Verify cluster access:

```
kubectl get nodes
```

---

### 2. Deploy Kubernetes Resources

Apply manifests in the following order:

```
kubectl apply -f k8s/sqlite-pvc.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

---

### 3. Verify Deployment

```
kubectl get pods
kubectl get svc
kubectl get pvc
```

All pods should be in `Running` state and the PVC should be `Bound`.

---

### 4. Access the Application

Expose the frontend using Minikube:

```
minikube service canary-frontend
```

This command will open the application in the browser or print the access URL.

---

## Backend Authentication

All backend API requests require a password header:

```
X-APP-PASSWORD: canary123
```

The password is injected via environment variables in Kubernetes.

---

## Persistence

* Notes are stored in SQLite
* SQLite data is mounted on a PersistentVolumeClaim
* Data survives pod restarts and crashes

---

## Notes

* The application logic is intentionally minimal
* The app should not be modified during resilience testing
* Kubernetes behavior is the primary focus, not application features

---
