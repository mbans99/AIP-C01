# D3-02 · Monitoring, Logging & Auditing (CloudWatch, CloudTrail, Config, X-Ray, Grafana/Prometheus)

> **Owner:** Claude · **Created:** 2026-11-10 · **Domains:** 3 (task 3.2 operational excellence, 3.3 security), also 1 (task 1.1/1.2 multi-account logging)
> **Status:** 🟡 Pre-filled for Neal §16 (Monitoring, Logging, and Auditing) + AWS Config (Neal §17). Discussion pending
> Related: [[D1-01 Organizations & Control Tower]] (org trail, Log Archive) · [[D3-01 Deployment & Management]] (SSM Automation remediation, CodeDeploy alarm rollback) · playbook 1.15, 3.3, 3.4

## 0. Root concept: five different questions, five different tools
Most wrong options in this area use a real service to answer the **wrong question**. Decide which question the stem is asking first.

| The question | Tool | What it stores |
|---|---|---|
| **How is it performing / is it healthy right now?** | **CloudWatch Metrics + Alarms** | Numbers over time (CPU, latency, queue depth) |
| **What did the application/OS write?** | **CloudWatch Logs** | Text lines your code, agent or service emits |
| **Who called which AWS API, when, from where?** | **CloudTrail** | One record per API call (`userIdentity`, `eventName`, `sourceIPAddress`) |
| **What did this resource look like, and is it compliant?** | **AWS Config** | Configuration snapshots of resources over time + rule results |
| **Where is the time spent across services in one request?** | **X-Ray** (or OpenTelemetry → CloudWatch Application Signals) | Traces: one request followed through API GW → Lambda → DynamoDB |

Plus **EventBridge**: not a store, the *reaction* layer. "When X happens, do Y" (state change, CloudTrail API event, alarm state change, schedule).

Quick contrast that the exam loves: *"Who opened port 22 on this security group?"* → **CloudTrail** (`AuthorizeSecurityGroupIngress`). *"Which security groups have port 22 open, and since when?"* → **Config**. *"Alert me the moment someone does it"* → **EventBridge rule on the CloudTrail event** (or a Config rule + remediation to undo it).

## 1. CloudWatch Metrics & Alarms
### 1.1 Metrics
- A metric = **namespace** (`AWS/EC2`) + name + **dimensions** (`InstanceId=i-…`). Kept **15 months** (rolled up to coarser periods as it ages).
- **EC2 default metrics are hypervisor-level only**: CPU, network, disk I/O, status checks. **No memory, no disk-space-used** → install the **CloudWatch agent** (unified agent; collects OS metrics + log files; config can live in **SSM Parameter Store**, pushed by SSM).
- EC2 basic monitoring = 5-min, **detailed monitoring** = 1-min (paid).
- **Custom metrics**: `PutMetricData`; standard (1-min) or **high-resolution** (down to 1 s). From Lambda/containers without API calls: **Embedded Metric Format (EMF)**, i.e. structured JSON log lines that CloudWatch turns into metrics.
- **Metric math** (combine metrics, e.g. errors ÷ requests), **anomaly detection** (ML band instead of a fixed threshold).

### 1.2 Alarms
- Watch one metric (or a metric-math expression). States: `OK` · `ALARM` · `INSUFFICIENT_DATA`. Settings: period, evaluation periods, *datapoints to alarm* (M of N), missing-data treatment.
- **Actions**: SNS · Auto Scaling policy · **EC2 actions** (stop / terminate / reboot / **recover**: moves the instance to new hardware, keeps IDs/IPs/EBS) · SSM OpsItem / Incident Manager · Lambda (newer). Every state change is also an **EventBridge event**, so anything else is reachable from there.
- **Composite alarms**: AND/OR of other alarms; cuts alert noise ("page only when latency AND error-rate alarms both fire").
- Used by other services: target-tracking scaling creates alarms for you · **CodeDeploy / AppConfig roll back on alarm** (see D3-01).

### 1.3 Dashboards & cross-account
- Dashboards are global and can show **multiple Regions**.
- **CloudWatch cross-account observability** ⭐: one **monitoring account** sees metrics, logs, traces of many **source accounts** (set up with Organizations; uses OAM *sinks* and *links*). Cue: "central operations team, single pane across all accounts, least overhead".

### 1.4 The "Insights" family (recognise the names)
| Name | One line |
|---|---|
| **Container Insights** | Metrics/logs for ECS, EKS, Kubernetes on EC2 (per cluster/service/task/pod) |
| **Lambda Insights** | Per-function system metrics (memory, cold starts) via a Lambda layer |
| **Contributor Insights** | Top-N from log data ("top 10 IPs hitting errors", "heaviest DynamoDB keys") |
| **Application Insights** | Auto-sets up monitoring for apps like .NET/SQL Server, detects problems |
| **Logs Insights** | Query language over CloudWatch Logs (see §2) |
| **Synthetics** (canaries) | Scripted probes that hit your endpoint/UI on a schedule, even with no real traffic |
| **RUM** | Real-user monitoring from browsers |
| **Application Signals** | APM: service map, SLOs, built on OpenTelemetry + X-Ray traces |
| **Internet Monitor / Network Monitor** | Internet-path health to your users / hybrid network path (DX/VPN) latency & loss |

## 2. CloudWatch Logs
- **Log group** (unit of settings: retention, KMS key, subscriptions) → **log streams** (one per instance/container/function instance).
- **Retention default = never expire** (cost trap). Set 1 day to 10 years per group.
- **Encryption**: always encrypted; customer KMS key per log group optional.
- **Metric filter** ⭐: pattern in log lines → a CloudWatch metric → alarm. Cue: "alarm when `ERROR` appears / when root logs in" (CloudTrail → CloudWatch Logs → metric filter → alarm is the CIS-benchmark classic).
- **Subscription filter** ⭐: **real-time** stream of matching log events to **Kinesis Data Streams, Data Firehose, Lambda, or OpenSearch**. Max 2 per log group (account-level subscription policy also exists).
- **Cross-account log centralisation**: source account subscription filter → **destination** (a Kinesis stream / Firehose in the central account, with a destination policy allowing the source accounts) → S3 / OpenSearch.
- **Export to S3 (`CreateExportTask`)**: **batch**, not real-time; can take **up to 12 h** to be available; one export task at a time per account. Cue: "near-real-time" → subscription + Firehose, not export.
- **Logs Insights**: interactive queries (`fields`, `filter`, `stats`, `parse`) across log groups. **Live Tail** = real-time console view.
- **Log classes**: Standard vs **Infrequent Access** (cheaper ingestion, fewer features). **Data protection policies** mask PII in log events.
- **Sources you get "for free"**: Lambda (stdout), API Gateway execution/access logs, ECS `awslogs` driver, VPC Flow Logs, Route 53 Resolver query logs, RDS/Aurora engine logs (export option), CloudTrail (if enabled on the trail), SSM Session Manager.

## 3. AWS CloudTrail
### 3.1 Event types (most-tested)
| Type | What | Default? |
|---|---|---|
| **Management events** | Control-plane calls: `RunInstances`, `CreateBucket`, `PutBucketPolicy`, `AssumeRole`, console sign-in. Read and write | **Logged by default** (Event history; first copy in a trail is free) |
| **Data events** | Resource-level, high-volume: **S3 object** `GetObject`/`PutObject`/`DeleteObject`, **Lambda `Invoke`**, DynamoDB item ops, and more | **Off by default**, extra cost. Enable per trail with (advanced) event selectors |
| **Network activity events** | API calls made through **VPC endpoints** (who used my endpoint, incl. denied calls) | Off by default (newer, 2024+) |
| **Insights events** | Detects **unusual** write-API call rates or error rates vs baseline | Off by default, extra cost |

Cue: "who downloaded objects from this bucket" → **S3 data events** (or S3 server access logs, §6). Management events alone won't show it.

### 3.2 Event history vs trails vs Lake
- **Event history**: last **90 days** of **management** events, per Region, no setup, free. Can't hold data events, can't keep longer.
- **Trail**: continuous delivery to an **S3 bucket** (optionally also **CloudWatch Logs**, which unlocks metric filters/alarms). **Multi-Region trail** is the default and recommended. Delivery is **not real-time**: typically within ~5 min. For instant reaction use **EventBridge** (CloudTrail events appear there without a trail).
- **Organization trail** ⭐: created in the **management account or a delegated administrator**; logs every member account into one bucket (prefix per account ID); member accounts **can see it but can't stop or modify it**.
- **CloudTrail Lake**: managed **event data store** with **SQL** queries, long retention (years), can also ingest Config items and non-AWS events. Cue: "query audit events with SQL, no pipeline to build". Classic alternative: trail → S3 → **Athena** (partitioned table).
- **Global services** (IAM, STS global endpoint, CloudFront) log their events in **us-east-1**.

### 3.3 Protecting the audit trail (tamper evidence)
| Need | Mechanism |
|---|---|
| **Prove logs weren't changed or deleted** | **Log file integrity validation**: hourly **digest files** hold SHA-256 hashes of each log file, digest signed by CloudTrail, chained to the previous digest. Verify with `aws cloudtrail validate-logs` |
| **Prevent deletion** | S3 **Object Lock** (compliance mode) / MFA Delete, restrictive bucket policy, bucket in a separate **Log Archive account** |
| **Prevent anyone turning it off** | **SCP** deny `cloudtrail:StopLogging`, `DeleteTrail`, `UpdateTrail`, `PutEventSelectors` (+ organization trail) |
| **Encrypt** | SSE-S3 default; **SSE-KMS** with a key policy allowing CloudTrail to encrypt and only auditors to decrypt |

Validation **detects** tampering; Object Lock/SCP **prevent** it. Exam options often offer only one of the two: match the verb in the stem.

## 4. AWS Config (in Neal §17, belongs here)
- **Configuration recorder** (per account **per Region**) records **configuration items** (CIs) for supported resources + **relationships** (instance ↔ ENI ↔ SG ↔ VPC). Delivery channel → S3 snapshots/history + optional SNS.
- Answers: "what did it look like at time T", resource **timeline**, and links each change to the **CloudTrail** event that caused it.
- **Rules**: **managed** (hundreds, e.g. `s3-bucket-public-read-prohibited`, `restricted-ssh`, `required-tags`) or **custom** (Lambda or **Guard** policy). Trigger on **configuration change** or **periodic**.
- **Config is detective, not preventive**: the change already happened. Prevent = SCP / IAM / CloudFormation Hooks.
- **Remediation** ⭐: attach an **SSM Automation document**; manual or **automatic** (with retries). Cue: "automatically fix non-compliant resources with least overhead".
- **Conformance packs**: a bundle of rules + remediations as one YAML; deployable **across the organization**. **Organization rules** also exist.
- **Aggregator** ⭐: **read-only**, multi-account + multi-Region view of compliance and resources (org-wide aggregator in management or delegated admin account). It **does not deploy** rules: that's conformance packs / org rules / StackSets.
- **Advanced queries**: SQL-like query over current resource config (e.g. all EC2 by instance type across the org with an aggregator).
- **Cost**: per CI recorded + per rule evaluation. **Periodic (daily) recording** instead of continuous lowers cost for chatty resources.

## 5. Tracing & open-source monitoring
### 5.1 AWS X-Ray
- **Trace** = one request end to end, identified by a **trace ID** passed in the `X-Amzn-Trace-Id` header. **Segments** (per service) → **subsegments** (downstream calls, SQL, HTTP).
- **Service map** (visual graph with latency/error per edge), **sampling rules** (don't trace every request), **annotations** (indexed, filterable: `customer_tier=gold`) vs **metadata** (not indexed).
- Enabling: **Lambda** and **API Gateway** = a toggle (active tracing); **EC2/ECS/EKS** = X-Ray **daemon** (ECS: sidecar container) or **ADOT collector** + SDK/agent in code. Elastic Beanstalk: an option.
- Cue: "find which microservice causes latency / errors in a distributed app" → **X-Ray** (not more logs, not CloudTrail).
- [beyond course] AWS now steers new instrumentation to **OpenTelemetry (ADOT)**; traces still land in X-Ray / Application Signals. Exam answer remains "X-Ray".

### 5.2 Amazon Managed Service for Prometheus (AMP) & Amazon Managed Grafana (AMG)
| | AMP | AMG |
|---|---|---|
| What | Managed **Prometheus-compatible metrics store** (PromQL), scales and HA for you | Managed **Grafana** dashboards |
| Feeds | Kubernetes/EKS, ECS, EC2 via **ADOT collector**, Prometheus remote-write, or AMP's managed scraper | Data sources: **CloudWatch, AMP, X-Ray, OpenSearch, Timestream, Athena, Redshift**, third parties |
| Auth | IAM | Users via **IAM Identity Center or SAML** |
Cue: "company already uses Prometheus/Grafana (e.g. on Kubernetes) and wants to stop operating them" → **AMP + AMG**. Cue absent → CloudWatch is usually the least-overhead answer.

## 6. Service-specific logs (where each one can go)
| Log | Contains | Destinations |
|---|---|---|
| **VPC Flow Logs** (VPC/subnet/ENI, also TGW) | IP/port/protocol/accept-reject **metadata**, no payload | CloudWatch Logs · S3 · Firehose |
| **ELB access logs** (ALB/NLB/CLB) | Every request: client IP, latency, target, status | **S3 only** |
| **S3 server access logs** | Best-effort request records for a bucket | S3 (another bucket). For guaranteed, near-complete audit use **CloudTrail S3 data events** |
| **CloudFront** standard logs / **real-time logs** | Viewer requests | S3 (and CloudWatch/Firehose for newer standard logs) / **Kinesis Data Streams** (seconds) |
| **Route 53 Resolver query logs** | DNS queries from VPCs | CloudWatch Logs · S3 · Firehose |
| **WAF logs** | Inspected requests + rule matched | CloudWatch Logs · S3 · Firehose (names must start `aws-waf-logs-`) |
| **API Gateway** | Execution logs / access logs | CloudWatch Logs (access logs also Firehose) |
| **RDS/Aurora** | Error, slow query, general, audit logs | CloudWatch Logs (export option) |
| **SSM Session Manager** | Session commands/output | S3 · CloudWatch Logs |
Packet contents → **VPC Traffic Mirroring**, not Flow Logs.

## 7. Architecture patterns (Neal's last lesson is mostly these)
| Scenario | Best answer | Loses because |
|---|---|---|
| Central, tamper-proof audit logs for all accounts, least overhead | **Organization trail** → S3 in **Log Archive account** + log file validation + Object Lock + SCP deny StopLogging | Per-account trails (members can stop them), Lambda copy jobs |
| Alert within seconds when someone changes a security group / root logs in | **EventBridge rule** on the CloudTrail API event → SNS/Lambda | Waiting on S3 delivery + Athena; Config periodic rule |
| Alarm when an error string appears in app logs | Logs → **metric filter** → alarm → SNS | Custom Lambda parsing logs |
| Stream logs from many accounts to one place in near real time | **Subscription filter** → central **Firehose/Kinesis destination** → S3/OpenSearch | `CreateExportTask` (batch, up to 12 h) |
| Ad-hoc SQL on audit events | **CloudTrail Lake**, or trail → S3 → **Athena** | Downloading logs, Logs Insights on CloudTrail when not sent to Logs |
| Memory / disk-space metrics on EC2 (and on-prem servers) | **CloudWatch agent** (config in Parameter Store, installed via SSM) | "Enable detailed monitoring" (still no memory) |
| Detect and auto-fix non-compliant resources across the org | **Config rule / conformance pack + SSM Automation auto-remediation**, aggregator for the view | Aggregator alone (read-only), scheduled scripts |
| Configure every new EC2 instance automatically on launch | **EventBridge** "EC2 state change: running" → **SSM Run Command/Automation** (Neal lab), or State Manager association by tag | Cron script polling |
| Find the slow microservice | **X-Ray** service map / Application Signals | More CloudWatch Logs, CloudTrail |
| One dashboard of all accounts' metrics/logs/traces | **CloudWatch cross-account observability** (monitoring account) | Logging into each account, copying metrics with Lambda |
| Know about app outages from outside before users do | **CloudWatch Synthetics** canary + alarm | Waiting on real-traffic metrics |
| Recover an EC2 instance on hardware failure, same IP | Alarm on `StatusCheckFailed_System` → **EC2 recover** action | Replacing via ASG (new IP/ID) when the stem needs to keep them |
| Existing Prometheus/Grafana, stop running them | **AMP + AMG** | Self-managed on EC2/EKS |
| Who accessed objects in a sensitive bucket | **CloudTrail S3 data events** (+ Macie/GuardDuty for threat angle) | Management events only |

## 8. Practice-question misses (append after TD D3 set)
_(topic → why wrong → rule)_

## 9. Q&A log
_(appended at end of the discussion)_
