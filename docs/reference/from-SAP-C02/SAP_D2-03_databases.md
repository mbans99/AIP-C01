# D2-03 · Databases (RDS, Aurora, DynamoDB, ElastiCache/MemoryDB, DocumentDB, Neptune, Keyspaces, Timestream, QLDB)

> **Owner:** Claude · **Created:** 2026-11-16 (exam morning) · **Domains:** 2 (new solutions), 3 (improve performance/reliability/cost), 4 (migrate/modernize)
> **Status:** 🟡 Last-minute review sheet. Discussion pending
> Related: [[D2-06 Analytics]] (Redshift, zero-ETL) · [[D4-01 Migration]] (DMS/SCT) · ../30_scaling-recommendations.md · DR review sheet

## 0. Root concept: pick by data model + access pattern, then by scale / HA / DR

Two questions, in this order:
1. **What shape is the data and how is it accessed?** → picks the *engine family*.
2. **What does the stem stress: read scale, write scale, failover time, cross-Region RPO/RTO, cost, ops effort?** → picks the *feature* inside that engine.

| Data / access pattern in the stem | Service |
|---|---|
| Relational, joins, transactions, existing MySQL/PostgreSQL/Oracle/SQL Server/MariaDB/Db2 app, "lift and shift the DB" | **RDS** |
| Relational, but needs more performance, faster failover, more replicas, global, serverless scaling | **Aurora** |
| Key-value / simple lookups by key, massive scale, single-digit ms, serverless, unpredictable traffic | **DynamoDB** |
| Microsecond reads in front of a DB, session store, leaderboard | **ElastiCache** (Redis/Valkey or Memcached) / **DAX** for DynamoDB |
| Redis API but it IS the primary database (durable) | **MemoryDB** |
| JSON documents, MongoDB compatibility | **DocumentDB** |
| Relationships: social graph, fraud rings, recommendations, knowledge graph | **Neptune** |
| Apache Cassandra (CQL) compatibility | **Keyspaces** |
| Time-stamped IoT / metrics | **Timestream** |
| Immutable, cryptographically verifiable history (ledger) | **QLDB** (exam-era answer; AWS ended support July 2025) |
| Analytics / data warehouse / BI SQL | **Redshift** (see D2-06) |

---

## 1. RDS

**HA vs scale: the two features people mix up**

| | **Multi-AZ (instance)** | **Multi-AZ DB cluster** | **Read replica** |
|---|---|---|---|
| Purpose | HA / failover | HA + read scale | Read scale (and DR if cross-Region) |
| Replication | Synchronous | Semi-synchronous | **Asynchronous** |
| Standby readable? | **No** | Yes (2 readable standbys) | Yes |
| Failover | Automatic, ~60–120 s, same endpoint (DNS flip) | Automatic, typically < 35 s | **Manual promote** (becomes standalone DB) |
| Engines | All | MySQL, PostgreSQL | MySQL, MariaDB, PostgreSQL (up to 15), Oracle, SQL Server |
| Cross-Region? | No | No | **Yes** |

- **Backups:** automated, retention up to **35 days**, point-in-time restore (restore = **new instance**, new endpoint). Manual snapshots kept until deleted. **Cross-Region automated backup replication** for DR.
- **Encryption:** set at creation. To encrypt an existing unencrypted DB: **snapshot → copy snapshot with encryption → restore**. Read replica encryption follows the source.
- **Sharing an encrypted snapshot cross-account:** must use a **customer managed KMS key** and share the key (AWS managed key can't be shared).
- **RDS Proxy:** connection pooling. Cue: **Lambda exhausting DB connections**, "too many connections", or "reduce failover time" for apps. Supports IAM auth + Secrets Manager.
- **RDS Custom** (Oracle, SQL Server): you need **OS / DB host access** but still want managed backups. Otherwise needing full control → EC2.
- **Oracle RAC is not supported on RDS** → EC2 (or keep on-prem).
- **IAM database authentication:** MySQL, MariaDB, PostgreSQL (token, 15 min).
- **Blue/Green Deployments:** low-downtime major version upgrades / schema changes, switchover in about a minute.
- **Storage autoscaling** for growing storage; **Performance Insights** to find the slow SQL.
- **Secrets Manager** native rotation for RDS credentials.

## 2. Aurora (MySQL- and PostgreSQL-compatible)

**Root idea:** compute is separate from a **shared storage volume** that keeps **6 copies across 3 AZs** and grows automatically (up to 128 TiB). Replicas read the same storage, so replica lag is tiny (usually < 100 ms) and failover is fast.

- **Up to 15 Aurora Replicas**; failover to a replica typically **< 30 s** (set **promotion tiers** to choose which).
- **Endpoints:** **writer (cluster)**, **reader** (load-balances across replicas), **custom** (subset, e.g. bigger replicas for reporting).
- **Aurora Global Database:** 1 primary Region + up to 5 secondary read-only Regions (exam-era number), storage-level replication, lag typically **< 1 s** → **RPO ≈ 1 s, RTO < 1 min**.
  - **Write forwarding:** secondary Region apps can send writes; they are forwarded to the primary.
  - **Switchover (managed planned failover):** no data loss, for drills / Region rotation. **Failover (unplanned):** promote secondary during an outage; possible small data loss.
- **Aurora Serverless v2:** scales in fine steps of ACUs, in seconds. Cue: **unpredictable, spiky, or intermittent** relational workload; dev/test. Can mix serverless and provisioned instances in one cluster.
- **Cloning:** copy-on-write, very fast. Cue: "create a **test/staging copy of prod quickly**, minimal cost".
- **Backtrack** (Aurora MySQL only): rewind the cluster in place to a time, **no restore needed**. Cue: "undo a bad DELETE/UPDATE quickly".
- **Babelfish** (Aurora PostgreSQL): understands SQL Server T-SQL / TDS. Cue: "migrate **SQL Server** to Aurora with **minimal code changes**".
- **Database Activity Streams:** near-real-time audit stream to Kinesis (compliance, separation of duties from DBAs).
- **I/O-Optimized** storage config: cheaper when I/O is a large share (> ~25%) of the Aurora bill.
- **Zero-ETL integration to Redshift:** analytics on Aurora data without building a pipeline.

## 3. DynamoDB

**Root idea:** you design the table around **how you will query it**. Every item is found by its **partition key** (optionally + sort key). Data is spread across partitions by hashing the partition key. (Mohit's Kafka analogy: partition key → partition, so a low-cardinality key = hot partition.)

- **Capacity modes:** **On-demand** (pay per request, unknown/spiky traffic) vs **Provisioned** (+ auto scaling, predictable traffic, cheaper; reserved capacity possible).
  - 1 **RCU** = 1 strongly consistent read/s of up to 4 KB (or 2 eventually consistent). 1 **WCU** = 1 write/s of up to 1 KB. Transactions cost 2×.
- **Item max 400 KB** → big objects go to **S3**, store the pointer in DynamoDB.
- **Indexes:**
  - **GSI:** different partition/sort key, add **any time**, eventually consistent only, own capacity. A throttled GSI can throttle base-table writes.
  - **LSI:** same partition key, different sort key, **only at table creation**, supports strong consistency.
- **DAX:** in-memory cache, **microsecond** reads, API-compatible. Not for strongly consistent reads or write-heavy work.
- **Streams:** ordered change log (24 h) → Lambda triggers, replication, audit, aggregation.
- **Global Tables:** **multi-Region, multi-active** (read and write in every Region), typically < 1 s replication, last-writer-wins. Cue: "**active-active** across Regions, low-latency writes globally". (Newer: multi-Region strong consistency option.)
- **Backups:** **PITR** (up to 35 days) and on-demand backups. Restore = new table.
- **Export to S3** (needs PITR, does **not** consume RCUs) → query with Athena. **Import from S3** into a new table.
- **TTL:** free automatic expiry of items (sessions, temp data); deletions appear in Streams.
- **Table classes:** Standard vs **Standard-IA** (storage-heavy, rarely read).
- **Security:** fine-grained access with IAM condition **`dynamodb:LeadingKeys`** (users only see items with their own key); **VPC gateway endpoint** for private access.
- **Hot partition fix:** higher-cardinality key, add a random/calculated suffix (write sharding).

## 4. Caches and the "other" engines

- **ElastiCache Redis/Valkey:** replication, **Multi-AZ auto-failover**, persistence, backups, sorted sets (**leaderboards**), pub/sub, **Global Datastore** (cross-Region). **Memcached:** multi-threaded, simple, no replication/persistence. Cue to pick Memcached: "simplest cache, multi-threaded, data loss OK".
  - Caching patterns: **lazy loading** (cache-aside, can be stale) vs **write-through** (always fresh, writes cost more); TTL to limit staleness.
  - **Session state** off the web tier: ElastiCache or DynamoDB.
- **MemoryDB:** Redis-compatible, **durable** (multi-AZ transaction log) → can be the **primary** database.
- **DocumentDB:** MongoDB-compatible, storage model like Aurora (6 copies / 3 AZs). Global clusters for cross-Region.
- **Neptune:** graph (Gremlin, openCypher, SPARQL).
- **Keyspaces:** serverless Cassandra.
- **Timestream:** time series, memory tier (recent) → magnetic tier (old, cheap) automatically.

## 5. Common exam stem → answer

| Stem says | Answer |
|---|---|
| RDS read-heavy, reporting slows prod | Read replicas (+ point reports at them) or ElastiCache |
| Lambda + RDS "too many connections" | **RDS Proxy** |
| Faster failover than RDS Multi-AZ, more replicas | **Aurora** (or RDS Multi-AZ DB cluster) |
| Cross-Region DR, RPO ~1 s, RTO ~1 min, relational | **Aurora Global Database** |
| Cheaper relational cross-Region DR, RPO minutes–hours | Cross-Region read replica / automated backup replication / snapshot copy |
| Active-active writes in multiple Regions | **DynamoDB Global Tables** |
| Unpredictable relational load, pay for what you use | **Aurora Serverless v2** |
| Quick copy of prod DB for testing | **Aurora clone** |
| Undo accidental data change fast (Aurora MySQL) | **Backtrack** |
| Encrypt existing unencrypted RDS | Snapshot → encrypted copy → restore |
| Share encrypted snapshot with another account | Customer managed KMS key + share key + share snapshot |
| Need OS access on managed Oracle/SQL Server | **RDS Custom** |
| Oracle RAC | **EC2** |
| SQL Server → Aurora PostgreSQL, few code changes | **Babelfish** |
| Heterogeneous migration (Oracle → Aurora PG) | **SCT** (schema) + **DMS** (data, CDC) |
| DynamoDB read latency must be microseconds | **DAX** |
| DynamoDB data for analytics, no impact on table | **Export to S3** + Athena |
| Big blobs with metadata lookups | S3 for object, DynamoDB/RDS for metadata |
| Users only access their own rows in DynamoDB | `dynamodb:LeadingKeys` IAM condition |
| Audit DB activity separately from DBAs (Aurora) | **Database Activity Streams** |

---

## Q&A log
_(empty until the discussion is completed)_
