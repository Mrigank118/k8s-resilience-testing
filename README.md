
# Canary-Resilience

Canary-Resilience is a Kubernetes-based microservices application designed to study and evaluate system resilience under controlled failure conditions. The project demonstrates how a distributed system behaves under stress and how resilience mechanisms such as self-healing, autoscaling, and fault isolation improve system reliability.


# Key Objectives

* Analyze system behavior under failure
* Validate resilience properties
* Demonstrate fault injection using chaos engineering
* Monitor system performance using real-time metrics


# Technologies Used

* Kubernetes
* Docker
* Prometheus
* Grafana
* LitmusChaos
* Helm

# Setup Instructions

## 1. Clone Repository

```bash id="ns9s16"
git clone <repository-url>
cd k8s-resilience-testing/scripts
```

## 2. Run Setup Script

```bash id="k3wgb2"
chmod +x master.sh
./setup.sh
```

# Accessing Services

## Frontend

```bash id="d60c9x"
minikube service canary-frontend -n notes
```

## Grafana

```bash id="0c39z7"
kubectl port-forward -n monitoring svc/kube-prometheus-grafana 3000:80
```

Open:

```id="q4j6me"
http://localhost:3000
```

## ChaosCenter (Litmus)

```bash id="n4q3mk"
minikube service litmusportal-frontend-service -n litmus
```

# Persistence

* SQLite database is used
* Data is stored via PersistentVolumeClaim
* Data persists across pod restarts


# Chaos Engineering (LitmusChaos)

Faults are injected using LitmusChaos to simulate real-world failures:

* Pod Deletion
* CPU Stress
* Network Latency

These experiments help evaluate how the system behaves under failure conditions.

# Monitoring and Observability

Prometheus collects system and application metrics. Grafana visualizes these metrics through dashboards.

# Key Metrics and Graphs

The following graphs are used to analyze system behavior:

## 1. CPU Usage

* Metric: `container_cpu_usage_seconds_total`
* Shows CPU consumption per pod
* Used to observe CPU stress and HPA scaling


## 2. Memory Usage

* Metric: `container_memory_usage_bytes`
* Shows RAM usage
* Ensures system stability under load


## 3. Pod Count

* Metric: `kube_deployment_status_replicas`
* Shows number of running pods
* Used to observe self-healing and scaling


## 4. Network Traffic

* Metrics:

  * `container_network_receive_bytes_total`
  * `container_network_transmit_bytes_total`
* Shows communication between services
* Used during latency experiments


## 5. Request Rate

* Metric: `http_requests_total`
* Shows number of requests handled
* Used to analyze throughput


## 6. Error Rate

* Metric: `http_requests_total{status=~"5.."}`
* Shows failed requests
* Used to validate circuit breaker behavior


## 7. Latency

* Metric: `http_request_duration_seconds`
* Shows response time
* Used to observe performance degradation and fail-fast behavior


# Resilience Experiments


## 1. Pod Deletion

* Fault: Pod termination
* Observation: Pods recreated automatically
* Property: Self-healing

## 2. CPU Stress

* Fault: High CPU load
* Observation: HPA scales pods
* Property: Scalability

## 3. Network Latency

* Fault: Artificial delay in communication
* Observation: System slows but continues functioning
* Property: Fault tolerance

## 4. Circuit Breaking

* Fault: Slow/unresponsive backend
* Observation: Requests fail fast
* Property: Failure isolation

# Conclusion

This project demonstrates how a Kubernetes-based microservices system behaves under real-world failure scenarios. By integrating chaos engineering and monitoring tools, it validates system resilience through recovery, adaptation, and fault containment.


