# D2-06 · Analytics (Kinesis, Data Firehose, Managed Flink, MSK, Redshift, Data Lake: S3/Glue/Lake Formation/Athena, EMR, OpenSearch, QuickSight, Timestream)

> **Owner:** Claude · **Created:** 2026-11-10 · **Domains:** 2 (new solutions), also 3 (cost/performance improvement) and 4 (modernize analytics)
> **Status:** 🟡 Pre-filled for Neal §15 (Analytics Services). Discussion pending
> Related: [[D3-02 Observability]] (log subscription → Firehose) · [[D2-04 Serverless/Events]] (MSK vs Kinesis) · playbook 2.5

## 0. Root concept: one pipeline, four stages
Every analytics question is one pipeline. Work out **which stage** the stem is about, then pick the service for that stage.

```
 SOURCES            1. INGEST                 2. STORE              3. CATALOG / PROCESS        4. QUERY / SERVE
 apps, IoT,   →  Kinesis Data Streams   →   S3 (data lake)    →   Glue Data Catalog       →   Athena (SQL on S3)
 logs, DBs       MSK (Kafka)                 Redshift (DW)         Glue ETL / EMR / Flink      Redshift (BI SQL)
                 Data Firehose (delivery)    OpenSearch            Lake Formation (perms)      OpenSearch Dashboards
                 DMS / zero-ETL (DBs)        Timestream (time)                                 QuickSight (BI dashboards)
```

| The question in the stem | Service |
|---|---|
| "Capture a high-volume stream, **multiple consumers**, **replay**, custom real-time processing" | **Kinesis Data Streams** (or **MSK** when Kafka/open-source compatibility is required) |
| "Load streaming data into S3/Redshift/OpenSearch/Splunk, **no code, least overhead**" | **Amazon Data Firehose** |
| "Real-time SQL/aggregations/windows **on the stream itself**" | **Managed Service for Apache Flink** (formerly Kinesis Data Analytics) |
| "Ad-hoc SQL on files in S3, serverless, pay per query" | **Athena** |
| "Complex SQL / BI / joins on large **structured** data, consistent performance, many users" | **Redshift** |
| "Existing Hadoop/Spark/Hive/Presto jobs, big custom processing" | **EMR** |
| "Serverless ETL, discover schemas, catalog" | **Glue** (crawlers + Data Catalog + ETL jobs) |
| "Fine-grained (column/row) permissions on the data lake, share across accounts" | **Lake Formation** |
| "Full-text search, log analytics, dashboards over logs" | **OpenSearch Service** |
| "Business dashboards for people" | **QuickSight** |
| "Time-stamped measurements (IoT sensors, metrics), recent data hot, old data cheap" | **Timestream** |

**Mental model for Mohit (Kafka background):** Kinesis Data Streams ≈ a managed Kafka topic (shard ≈ partition, partition key → shard, retention + replay, consumers keep their own position). Firehose is **not** a stream you read from; it is a delivery pipe that buffers and writes to a destination.

## 1. Kinesis Data Streams (KDS)
- **Unit = shard.** Per shard: write **1 MB/s or 1,000 records/s**, read **2 MB/s** (shared across standard consumers).
- **Capacity modes:** **Provisioned** (you pick shard count; split/merge to resize) or **On-demand** (auto-scales; pay per GB; for unknown/spiky traffic).
- **Partition key** → hash → shard. Ordering is **per shard**. A "hot shard" = bad partition key (too few distinct values) → `ProvisionedThroughputExceededException`. Fix: higher-cardinality key, more shards.
- **Retention** 24 h default, up to **365 days**. Data is **replayable** (consumers re-read from a sequence number / timestamp). Records are immutable; can't delete individual records.
- **Consumers:** Lambda (event source mapping), KCL apps (on EC2/ECS; uses a DynamoDB table for checkpoints/leases), Firehose, Managed Flink.
  - **Enhanced fan-out (EFO):** each registered consumer gets its **own 2 MB/s per shard**, push (HTTP/2), ~70 ms latency. Cue: "many consumers, each needs full throughput / low latency".
- **Producers:** SDK `PutRecord(s)`, **KPL** (batching/aggregation), **Kinesis Agent** (log files on servers), CloudWatch Logs subscription, IoT Core rule, DMS target.
- **Security:** KMS server-side encryption, VPC interface endpoint, IAM.
- **Not for:** per-message ack/delete, delay queues, worker queues (that's SQS).

## 2. Amazon Data Firehose (formerly Kinesis Data Firehose)
- **Fully managed delivery**: no shards, no consumers to run, auto-scales. **Near-real-time** because it **buffers** (by size **1–128 MB** or time **0–900 s**, whichever first; zero-buffering option exists).
- **Sources:** Direct PUT (SDK/agent), **KDS stream as source**, MSK, CloudWatch Logs / EventBridge / IoT / WAF / VPC Flow Logs, etc.
- **Destinations:** **S3**, **Redshift** (writes to S3 then issues `COPY`), **OpenSearch**, **Splunk**, Snowflake, **Apache Iceberg tables**, generic **HTTP endpoints** (Datadog, New Relic…).
- **Built-in transforms** ⭐ (least-overhead answers):
  - **Lambda transformation** (enrich/filter/convert records)
  - **Format conversion** JSON → **Parquet/ORC** (uses a Glue Data Catalog table for schema) → cheaper Athena queries
  - **Dynamic partitioning** (S3 prefixes from fields in the record, e.g. `customer_id/year/month`)
  - Compression (GZIP, Snappy…), source-record backup to S3, failed records to an S3 error prefix
- **No replay, no data storage, no multiple consumers.** If the stem needs those, put **KDS in front** and Firehose as one consumer.

## 3. Managed Service for Apache Flink (formerly Kinesis Data Analytics)
- Run **Apache Flink** apps (Java/Scala/Python/SQL; Studio notebooks) on streams from **KDS or MSK**. Serverless scaling (KPUs), checkpoints/snapshots.
- Cue: "real-time anomaly detection / windowed aggregation / streaming joins before data lands", "continuous SQL on a stream".
- Output to KDS, Firehose, S3, OpenSearch, etc.

## 4. Amazon MSK (Kafka) — brief, since you know Kafka
- Managed Apache Kafka (provisioned brokers or **MSK Serverless**); **MSK Connect** for Kafka Connect connectors.
- **Pick MSK over KDS when:** existing Kafka apps/ecosystem ("migrate on-prem Kafka with minimal code changes"), message size > what KDS allows, need Kafka features (compaction, custom configs, very long retention via tiered storage).
- **Pick KDS when:** "least operational overhead", AWS-native integrations (Lambda, Firehose), no Kafka requirement.

## 5. The data lake: S3 + Glue + Lake Formation + Athena
### 5.1 S3 as the lake
- Zones: **raw → cleaned/curated → analytics**, often separate buckets/prefixes.
- **Performance/cost levers** (tested constantly): columnar formats (**Parquet/ORC**), **compression**, **partitioning** (`year=/month=/day=`), avoid many tiny files (compact them).
- Open table formats: **Apache Iceberg** (ACID updates/deletes, time travel, schema evolution) supported by Athena, Glue, EMR, Redshift; **S3 Tables** = managed Iceberg buckets.

### 5.2 AWS Glue
- **Glue Data Catalog:** central metastore (databases/tables/schemas/partitions). Used by Athena, Redshift Spectrum, EMR, Lake Formation. One per account per Region (shareable).
- **Crawlers:** scan S3/JDBC sources, infer schema, create/update catalog tables and partitions (scheduled).
- **Glue ETL jobs:** serverless **Spark** (or Python shell / Ray); **job bookmarks** process only new data; triggers and **workflows**; Glue Studio visual editor.
- **Glue DataBrew:** no-code data preparation (cleaning, normalising) for analysts. **Glue Data Quality:** rules on datasets. **Glue Schema Registry:** schemas for KDS/MSK producers/consumers.
- **Glue vs EMR:** Glue = serverless, less control, ETL-focused. EMR = full cluster control, any big-data framework, can be cheaper at large steady scale with Spot.

### 5.3 AWS Lake Formation ⭐
- Sets up and **governs** the data lake on top of S3 + Glue Catalog.
- **Fine-grained access:** database / table / **column** / **row** / **cell-level** permissions (data filters), enforced for Athena, Redshift Spectrum, EMR, Glue, QuickSight. Simpler than juggling S3 bucket policies + IAM per prefix.
- **LF-Tags (tag-based access control):** tag tables/columns (e.g. `classification=PII`), grant on tags → scales to many tables.
- **Cross-account sharing** of catalog tables (uses **AWS RAM** under the hood) without copying data. Cue: "central data lake account, consumer accounts query with column restrictions" → Lake Formation.
- Governed tables / blueprints for ingestion (blueprints = templated Glue workflows from DBs/logs).

### 5.4 Amazon Athena
- **Serverless SQL** (Trino/Presto engine) directly on S3, schema from Glue Catalog. **Pay per TB scanned** (so Parquet + partitions + compression = lower cost and faster).
- **Workgroups:** separate users/teams, **per-query and per-workgroup data-scanned limits**, result locations, cost tracking. Cue: "control Athena costs per team".
- **Federated query:** Lambda-based connectors query DynamoDB, RDS, Redshift, CloudWatch Logs, on-prem JDBC… and join with S3 data.
- **CTAS / INSERT INTO** to convert data to Parquet / create partitioned tables. Supports Iceberg (UPDATE/DELETE/MERGE).
- Typical uses: query **CloudTrail, ALB, VPC Flow Logs, CloudFront logs** in S3; ad-hoc analysis. Also **Athena for Apache Spark** (notebooks).
- Not ideal for: sub-second dashboards with many concurrent users over hot data (Redshift / QuickSight SPICE), OLTP.

## 6. Amazon Redshift (data warehouse, OLAP)
- **Columnar, MPP** SQL warehouse (PostgreSQL-flavoured). **Leader node** (plans queries) + **compute nodes**. Good for complex joins/aggregations over TB–PB with steady BI workloads.
- **Node types:** **RA3** (compute separate from **Redshift Managed Storage** on S3, scale each independently) — the default answer; DC2 (older, local SSD).
- **Redshift Serverless:** no cluster, pay for RPU-seconds; cue "unpredictable/intermittent analytics, no capacity management".
- **Redshift Spectrum:** query **S3** data from Redshift (external tables via Glue Catalog) and join with warehouse tables, without loading. Cue: "keep recent data in Redshift, years of history in S3, query both".
- **Loading:** `COPY` from S3 (parallel; best way), Firehose (uses COPY), DMS, Glue. **Zero-ETL integrations** ⭐ from **Aurora MySQL/PostgreSQL, RDS MySQL, DynamoDB** (near-real-time replication into Redshift, no pipeline to build). **Streaming ingestion** directly from **KDS / MSK** into materialized views.
- **Federated query:** query live data in RDS/Aurora PostgreSQL/MySQL from Redshift.
- **Data sharing** ⭐: share live data **read-only** across clusters/serverless workgroups, **accounts and Regions**, no copies (RA3/serverless). Cue: "ETL cluster and BI cluster isolation" or "share with another business unit's account".
- **Performance:** distribution styles (KEY/ALL/EVEN/AUTO), sort keys, materialized views, result caching, **Workload Management (WLM)** queues, **Concurrency Scaling** (adds transient capacity for read bursts, often free credits), **Short Query Acceleration**, Redshift Advisor.
- **Availability & DR:** a provisioned cluster lives in **one AZ** by default; **Multi-AZ** deployment option for RA3. **Snapshots** (automated to S3, manual); **cross-Region snapshot copy** (for KMS-encrypted clusters you need a **snapshot copy grant** in the destination Region). Restore = new cluster. Relocation (move cluster to another AZ).
- **Security:** KMS or HSM encryption, VPC, **Enhanced VPC Routing** (forces COPY/UNLOAD traffic through your VPC so you can use VPC endpoints/flow logs), audit logging to S3/CloudWatch.
- `UNLOAD` writes query results to S3 (Parquet supported).
- **Not for:** OLTP, small row-by-row writes, unstructured data.

## 7. Amazon EMR
- Managed **Hadoop ecosystem**: Spark, Hive, HBase, Presto/Trino, Flink, Hudi, Iceberg. Deployment: **EMR on EC2** (cluster), **EMR on EKS**, **EMR Serverless**.
- Node roles: **primary** (master), **core** (run tasks + hold HDFS data), **task** (compute only, **no HDFS** → perfect for **Spot**).
- **Storage:** HDFS (ephemeral, lost when cluster ends) vs **EMRFS = S3** (persistent; lets you use **transient clusters**: spin up, run job, terminate).
- Cost pattern ⭐: S3 for data + transient clusters + **On-Demand/RI for primary & core, Spot for task nodes** (instance fleets with multiple instance types).
- Cue: "migrate on-prem Hadoop/Spark with minimal changes" → EMR (lift and shift); "refactor to serverless" → Glue / EMR Serverless / Athena.

## 8. Amazon OpenSearch Service
- Managed OpenSearch (Elasticsearch fork): **full-text search, log analytics, observability**, OpenSearch Dashboards (Kibana-like). Also **OpenSearch Serverless** (collections).
- Ingestion: Firehose, **OpenSearch Ingestion** (managed Data Prepper pipelines), CloudWatch Logs subscription, Logstash, Lambda from DynamoDB Streams (search on DynamoDB data).
- Storage tiers: hot → **UltraWarm** (S3-backed, read-only, cheaper) → **cold storage**. Cue: "keep 1 year of logs searchable at lower cost".
- Domains: deploy across **3 AZs** with dedicated master nodes for production; fine-grained access control, Cognito/SAML for Dashboards.
- Classic pattern: **DynamoDB (source of truth) + OpenSearch (search index)**. OpenSearch is not a primary database.

## 9. Amazon QuickSight
- Serverless BI dashboards. **SPICE** = in-memory engine (imported data, fast, scales to many users); or direct query.
- Sources: Athena, Redshift, RDS/Aurora, S3, OpenSearch, Salesforce, on-prem via VPC connection…
- **Row-level security (RLS)** and column-level security; user types (authors/readers, pay-per-session readers); **embedded dashboards** in apps; **Amazon Q in QuickSight** natural-language questions.
- Cue: "business users need interactive dashboards, least overhead" → QuickSight (not a custom web app, not EC2 BI tools).

## 10. Amazon Timestream
- Serverless **time-series database**: rows of (timestamp, dimensions, measures). Built-in time-series functions (interpolation, smoothing, binning).
- **Two tiers, automatic movement:** **memory store** (recent data, fast writes/queries) → **magnetic store** (historical, cheap) by retention policies you set. **Scheduled queries** pre-compute rollups.
- Sources: IoT Core rules, KDS / Managed Flink, Telegraf, SDK. Visualise with **Grafana** (Amazon Managed Grafana) or QuickSight.
- Cue: "millions of IoT sensor readings / DevOps metrics per second, query recent and historical trends, least overhead" → Timestream (vs DynamoDB: no native time-series functions or tiering; vs RDS: doesn't scale).
- ⚠️ Note: AWS now offers **Timestream for LiveAnalytics** (the serverless engine above) and **Timestream for InfluxDB** (managed InfluxDB). LiveAnalytics stopped accepting new customers in 2025, but SAP-C02 questions written earlier still use it as the time-series answer.

## 11. Other names to recognise
| Name | One line |
|---|---|
| **AWS Data Exchange** | Subscribe to third-party datasets (delivered to S3 / Redshift / API) |
| **AWS Clean Rooms** | Analyse combined datasets with partners without sharing raw data |
| **Amazon DataZone / SageMaker Unified Studio** | Data catalog + governance portal for business users to find and request data |
| **AWS Entity Resolution** | Match/link records about the same entity across datasets |
| **Amazon Managed Workflows for Apache Airflow (MWAA)** | Managed Airflow to orchestrate pipelines (vs Glue workflows / Step Functions) |
| **AWS Glue Elastic Views** | ❌ Discontinued; if it appears, likely a distractor |
| **Kinesis Video Streams** | Ingest video from devices (cameras) for playback / ML (Rekognition). Not for media/OTT delivery |

## 12. Architecture patterns
| Scenario | Best answer | Loses because |
|---|---|---|
| Clickstream/IoT to S3 for later analysis, least overhead | **Firehose** → S3 (Parquet conversion + dynamic partitioning) → Glue Catalog → **Athena** | KDS + custom consumer on EC2 (more ops) |
| Stream needs several independent consumers + replay of last 7 days | **KDS** (retention 7 d, **EFO** for each consumer) | Firehose (no replay/multiple consumers), SQS (message deleted once consumed) |
| Real-time dashboard/alert on streaming metrics within seconds | KDS → **Managed Flink** (windowed aggregation) → Lambda/SNS or OpenSearch | Firehose → S3 → Athena (minutes, batch) |
| Existing on-prem Kafka, move to AWS, no code changes | **MSK** (MSK Connect, MirrorMaker 2 to migrate) | KDS (rewrite producers/consumers) |
| Query years of logs in S3 occasionally, cheapest | **Athena** on partitioned Parquet; workgroup limits | Loading into Redshift; running an always-on EMR cluster |
| Athena queries too slow / expensive | Convert to **Parquet/ORC**, compress, **partition**, compact small files (Glue job or CTAS) | Bigger Athena "instances" (there are none) |
| Analysts in many accounts query the central lake; hide PII columns | **Lake Formation** column/row filters or **LF-Tags** + cross-account grants | Per-bucket S3 policies, copying data per account |
| Steady BI workload, complex joins, many concurrent users | **Redshift** (RA3; concurrency scaling for peaks) | Athena (per-scan cost, concurrency limits) |
| Recent data hot in warehouse, history cheap in S3, join both | **Redshift Spectrum** (or `UNLOAD` old data to S3 + Spectrum) | Resizing the cluster to hold all history |
| Analytics on Aurora OLTP data without ETL pipeline or load on the primary | **Aurora zero-ETL integration → Redshift** | DMS + Glue pipelines (more overhead), querying the writer |
| Separate ETL and BI workloads on the same warehouse data | **Redshift data sharing** (producer → consumer cluster/serverless) | Copying data between clusters, one cluster with WLM only |
| Redshift DR in another Region | **Cross-Region snapshot copy** (+ snapshot copy grant for KMS) | Read replicas (Redshift has none) |
| Lift-and-shift Hadoop/Spark, cut cost | **EMR**, data on S3 (EMRFS), transient clusters, **Spot task nodes** | Spot for core/primary nodes (HDFS/cluster loss) |
| Serverless ETL with schema discovery | **Glue crawlers + Glue ETL** (job bookmarks for incremental) | EMR cluster you manage; Lambda (15-min limit) |
| Search and log analytics with dashboards, keep a year cheaply | **OpenSearch** with **UltraWarm/cold** tiers | CloudWatch Logs Insights for full-text search UX; keeping everything in hot nodes |
| Business dashboards for thousands of readers | **QuickSight** with SPICE (+ RLS) | Custom app; Redshift alone (no UI) |
| IoT sensor time-series, recent + historical queries | **IoT Core → Timestream** (memory → magnetic tiers), Grafana | DynamoDB + custom rollups; RDS |
| Near-real-time log centralisation from many accounts | CloudWatch Logs **subscription filter** → central **Firehose** → S3/OpenSearch (see D3-02) | `CreateExportTask` (batch, up to 12 h) |

## 13. Practice-question misses (append after TD D2 set)
_(topic → why wrong → rule)_

## 14. Q&A log
_(appended at end of the discussion)_
