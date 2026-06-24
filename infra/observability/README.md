
# Observability

Recommended signal flow:

```mermaid
flowchart LR
  app[Apps and services] --> otel[OpenTelemetry SDK]
  otel --> collector[OpenTelemetry Collector]
  collector --> prometheus[Prometheus metrics]
  collector --> tempo[Tempo traces]
  app --> loki[Loki logs]
  prometheus --> grafana[Grafana]
  tempo --> grafana
  loki --> grafana
```

Minimum production requirements:

* RED metrics: request rate, errors, duration
* USE metrics: utilization, saturation, errors
* structured JSON logs
* trace IDs in logs
* SLO dashboard
* paging alert rules
