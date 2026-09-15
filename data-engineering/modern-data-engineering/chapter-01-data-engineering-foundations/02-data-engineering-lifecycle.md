# 1.2 — The Data Engineering Lifecycle

```text
GENERATION
    ↓
INGESTION
    ↓
STORAGE
    ↓
TRANSFORMATION
    ↓
SERVING
```

## 1) Generation
Where data is born:
- application database
- API
- event stream
- IoT sensor
- uploaded file

Usually not owned by the Data Engineer.

## 2) Ingestion
Move data from source to data platform.

Key decisions:
- Batch vs Streaming
- Push vs Pull

Often failure-prone because external systems are involved.

## 3) Storage
Keep data:
- durably
- affordably
- in a useful layout

Tradeoff: cost ↔ query performance.

Examples:
- object storage
- warehouse
- database
- lake

## 4) Transformation
Turn raw data into trustworthy/useful data:
- clean bad values
- standardize formats
- join datasets
- aggregate
- model data

## 5) Serving
Deliver data to consumers:
- dashboards
- analysts
- ML models
- applications
- reports

> Serving is the purpose of the entire lifecycle.

If final data is wrong, everything upstream was pointless.

## Four undercurrents (across all stages)
- Security
- Data management
- Orchestration
- Cost
