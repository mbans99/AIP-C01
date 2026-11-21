# Carry-over from SAP-C02

> **Owner:** Claude · **Created:** 2026-11-20 · Source workspace: `../../SAP-02` (Mohit's local folder; passed SAP-C02 with 806).
> **Purpose:** One place that says what came over from SAP-C02, where it now lives, and which SAP knowledge answers which AIP-C01 task. SAP notes are linked, not rewritten.

## 1. What came over
| Item | Where it is now | How it was carried |
|---|---|---|
| Baseline format (profile, exam facts, resources, plan, pacing, exam rules, skip list, tracker, weak-topics log, open decisions, collaboration rules, topic index, change log) | `00_BASELINE.md` | Rewritten for AIP-C01 |
| Lessons from SAA/SAP (practice from day 1, pattern-first, feature facts, timeboxed labs, one-sitting exams, outdated answer keys) | `00_BASELINE.md` §4a | Distilled |
| Pacing checkpoints + reading method (same 75 Q / 180 min format) | `00_BASELINE.md` §4b–4c | Unchanged + a multiple-response rule |
| Constraint-word tie-breakers | `20_pattern-playbook.md` §0 | Carried, with GenAI meaning added |
| SAP patterns that still apply (SQS buffering, Step Functions, fan-out, API security, Fargate, secrets/KMS, PrivateLink, X-Ray, blue/green…) | `20_pattern-playbook.md` §7 | Selected rows |
| Feature-facts log format + relevant rows | `10_feature-facts_claude.md` | Selected rows |
| Scaling recommendations (Lambda, DynamoDB, ECS, Aurora, Kinesis, SQS load leveling) | `30_throughput-and-scaling.md` | Selected rows + Bedrock section |
| Topic-file skeleton, per-topic workflow, one-topic-per-chat | `00_BASELINE.md` §8, §10 | Unchanged |
| Exam review file format | `practice-exams/_TEMPLATE_exam-review.md` | Generalised |
| Follow-ups parking lot format | `practice-exams/followups-parking-lot.md` | Fresh list |
| Lab format (README with predict-then-check results map, CFN template, teardown, lessons) + foundation stack | `../labs/README.md`, `../labs/AWSLabTemplate.yaml` | Copied |
| Org-closure / cost-check script | `../tools/close-org-prep.sh` | Copied as is |
| Full SAP playbook, feature facts, scaling notes (archive) | `reference/from-SAP-C02/SAP_*.md` | Copied read-only |
| SAP topic notes relevant to AIP (below) + exam-technique and security-services review sheets (PDF) | `reference/from-SAP-C02/` | Copied read-only |

## 2. Not carried (and why)
- Neal Davis course code (`src/`) and slides PDF: SAP-specific and owned by Digital Cloud Training.
- SAP-only topics: Organizations/Control Tower, hybrid connectivity (DX/VPN), migration (7Rs, MGN, DMS), edge/DNS, EC2/ELB/ASG, the Route 53 hybrid DNS lab. Still available in `../SAP-02` if a question touches them.
- SAP study plan, exam dates, scores and practice-exam reviews (history; summarised in baseline §1 and §4a).

## 3. SAP notes → AIP tasks (read these instead of re-learning)
| AIP task | What it needs | SAP reference (read-only) |
|---|---|---|
| 1.2.2 / 2.4.4 Model switching & routing via Lambda, API Gateway, **AppConfig** | Feature flags/config without redeploy | `SAP_D3-01_deployment-management.md` (deployment strategies §6; AppConfig only briefly, D1-01 will cover it) |
| 1.2.3 / 2.1.3 Circuit breakers, stopping conditions, Step Functions | Workflow orchestration, retries | `SAP_20_pattern-playbook.md` 2.4 |
| 1.3.1 / 3.3.2 Glue Data Quality, Glue Data Catalog, lineage; 3.2.1 Lake Formation | Data lake governance | `SAP_D2-06_analytics.md` (Glue, Lake Formation, Athena) |
| 1.4 / 1.5 OpenSearch as vector store, sharding; Aurora pgvector; DynamoDB metadata | Search/DB internals | `SAP_D2-06_analytics.md` §8 OpenSearch · `SAP_D2-03_databases.md` |
| 1.6.2 Conversation history in DynamoDB; 4.1.4 caching (ElastiCache) | Session/state stores | `SAP_D2-03_databases.md` |
| 2.3.1 / 2.3.2 Event-driven integration (EventBridge, SQS, SNS), API Gateway microservices | Integration patterns | `SAP_20_pattern-playbook.md` 2.1–2.3, 2.12 |
| 2.3.3 Identity federation, RBAC for model/data access; Cognito | Federation, Identity Center | `SAP_D1-03_federation-identity-center.md` · `SAP_D1-02_iam-advanced.md` |
| 2.1.3 IAM resource boundaries; 3.2.1 IAM policies; service roles (Bedrock KB/Agents roles, PassRole) | IAM evaluation, trust policies | `SAP_D1-02_iam-advanced.md` §3 (trust, service roles, PassRole) |
| 2.3.5 CI/CD with CodePipeline/CodeBuild, rollback; 1.2.4 automated model deployment pipelines | CI/CD, blue/green, canary | `SAP_D3-01_deployment-management.md` §5–6 |
| 3.2.1 VPC endpoints / PrivateLink for Bedrock | Private access | `SAP_D1-04_multi-account-networking.md` (PrivateLink, endpoints) |
| 3.3.1 / 4.3 CloudWatch Logs, Logs Insights, metrics/alarms, anomaly detection, dashboards, CloudTrail audit, X-Ray tracing | Observability stack | `SAP_D3-02_observability.md` (whole file; §0 "which tool answers which question") |
| 2.4.3 / 4.1.3 Throttling, backoff, auto scaling | Scaling patterns | `SAP_30_scaling-recommendations.md` |
| 3.2.2 Macie, KMS, Secrets Manager, WAF | Security services | `SAP-C02_07_security-services-map.pdf` |
| All | Exam technique | `SAP-C02_01_exam-technique.pdf` |
