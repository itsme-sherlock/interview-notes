# 1.1 — What Is Data Engineering?

## Core idea
> Data engineering = building reliable systems that move data from where it is produced to where it can be trusted and used.

Typical flow:

```text
Source Systems
     ↓
Ingestion
     ↓
Storage
     ↓
Transformation
     ↓
Trusted Data
     ↓
Analytics / ML / Applications
```

- A **data pipeline** is an automated, repeatable process that moves and reshapes data.
- A **data platform** is the collection of infrastructure/services the pipelines run on.
- A **data product** is the trustworthy output others consume, such as:
  - cleaned table
  - metric
  - dashboard dataset
  - ML feature/training data

## Data Engineer vs Other Roles

| Role | Main responsibility |
|---|---|
| Platform Engineer | Infrastructure/compute/storage/networking |
| Data Engineer | Ingestion, storage, transformation, pipelines, reliability, cost |
| Analytics Engineer | SQL-based modeling of loaded data |
| Data Analyst | Business analysis/reporting |
| Data Scientist/ML Engineer | ML/statistical models |

> Data Engineer makes trustworthy data exist and stay fresh.

## Core tools
Two essential languages:
- SQL → querying/manipulating data
- Python → pipeline/programming logic

Supporting tools:
- Git → version control
- Linux/Bash → operating/debugging environment
- Docker → reproducible runtime
- Jupyter → exploration/prototyping

## Important mindset
A production pipeline is not just a Python script. It must handle:
- failures
- retries
- duplicate execution
- monitoring
- testing
- reproducibility

## Cost is part of architecture
Three major cost dimensions:
- Storage → keeping data
- Compute → processing data
- Egress → moving data out

A technically correct pipeline can still be a bad design if it scans/copies unnecessarily large amounts of data.

## Production pipeline mental model

```text
Pipeline
   ↓
DAG
   ↓
Idempotent
Observable
Testable
```

- **Idempotent**: safe to run again.
- **Observable**: you can see whether it ran, duration, failures, and whether data looks correct.
- **Testable**: logic can be automatically verified.

> A production pipeline is a DAG of idempotent, observable and testable steps — not a pile of scripts.
