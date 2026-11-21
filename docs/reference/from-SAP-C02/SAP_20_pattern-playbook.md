# SAP-C02 Pattern Playbook: attack by pattern, not by service

> **Owner:** Claude · **Created:** 2026-10-28 · Mohit/agents: append new patterns in §6 (append only)
> **Why:** After exam #1, Mohit noticed questions repeat a limited set of *problem shapes* per domain. This file is the primary study spine; videos become **on-demand lookups** for services inside a pattern he doesn't know.
> **How to use a pattern:** it **shortlists** 1–2 options fast; the **constraint words** decide between them. Distractors are built to match a pattern's keyword but break a constraint, so never pick on the keyword alone.

---

## 0. Tie-breakers that apply to every domain
| Constraint word | What usually wins | What usually loses |
|---|---|---|
| **Least operational overhead** | Managed / native feature / serverless | EC2 + scripts, cron, custom Lambda doing what a feature does |
| **Most cost-effective** | Spot (fault-tolerant), Savings Plans (steady), S3 lifecycle/IT, serverless (spiky) | Over-provisioned HA nobody asked for |
| **Minimal changes to the application** | Rehost/replatform, config-only changes, DNS/LB switch | Refactor to DynamoDB/Lambda, rewrites |
| **Minimal downtime** | Replication + cutover (DMS CDC, MGN, blue/green, weighted DNS) | Backup → restore, stop-copy-start |
| **Most secure / least privilege** | Roles over keys, resource policies with org/VPC conditions, KMS CMK, private endpoints | Long-lived access keys, public endpoints with IP allow-lists |
| **As quickly as possible** | Existing managed solution / AWS-provided blueprint | Building a custom platform |

**Speed rule:** read the last sentence → name the pattern → shortlist → decide on the constraint word. Max 3 min, then flag.

---

## 1. Domain 1: Organizational Complexity (26%)
| # | Pattern (how it shows up) | Usually wins | Typical distractor |
|---|---|---|---|
| 1.1 | Govern many accounts with best practices, **quickly** | **Control Tower** (landing zone, controls, Account Factory) | Hand-built Orgs + scripts |
| 1.2 | Stop accounts/admins from doing X (regions, disabling logs, leaving org) | **SCP** (deny-list) | IAM policy in each account (admins can remove it) |
| 1.3 | Keep outsiders off our resources even with bad resource policies | **RCP** / resource policy with `aws:PrincipalOrgID` | Listing account IDs |
| 1.4 | Security team manages a service across all accounts | **Delegated administrator** (GuardDuty, Security Hub, Config, Firewall Manager…) | Logging into each account / using the management account |
| 1.5 | Workforce SSO across accounts with corporate IdP | **IAM Identity Center** + SAML 2.0 + SCIM, permission sets | IAM users per account; per-account SAML |
| 1.6 | On-prem Active Directory users need AWS / app access | **AD Connector** (proxy, no sync) or **AWS Managed Microsoft AD + trust** (AWS-side workloads need a real AD) | Simple AD (small, not real MS AD); syncing users by script |
| 1.7 | Third party / another account needs access | **Cross-account IAM role** (+ **external ID** for third parties) | Sharing access keys |
| 1.8 | Many VPCs/accounts need to talk; transitive routing | **Transit Gateway** shared via **RAM**, TGW route tables for segmentation | Full-mesh VPC peering |
| 1.9 | Expose one service to many VPCs/accounts, **overlapping CIDRs** | **PrivateLink** (NLB + endpoint service) | Peering/TGW (CIDR overlap breaks routing) |
| 1.10 | Central egress / traffic inspection for all VPCs | **TGW + inspection VPC** with **Network Firewall** or **GWLB** appliances (TGW **appliance mode** on) | NAT GW in every VPC with no inspection |
| 1.11 | Hybrid link: consistent bandwidth / private | **Direct Connect**; **max resilience** = 2 DX connections at 2 locations; **cheap backup** = S2S VPN over internet | Single DX |
| 1.12 | One DX to VPCs in many Regions/accounts | **DX gateway** (+ TGW for transitive needs) | One DX per Region |
| 1.13 | Encrypt traffic over DX | **MACsec** (dedicated) or **VPN over DX** (public/transit VIF) | "DX is encrypted by default" (it's not) |
| 1.14 | Hybrid DNS (on-prem ↔ AWS names) | **Route 53 Resolver** inbound/outbound endpoints + rules shared via RAM | Custom DNS servers on EC2 |
| 1.15 | Central logs, tamper-proof | **Org CloudTrail** → Log Archive bucket (+ Object Lock / SCP deny delete); Config aggregator | Per-account trails |
| 1.16 | Share subnets so teams don't manage networking | **VPC sharing (RAM)** | Each team builds VPCs |
| 1.17 | Charge-back / cost per team | **Cost allocation tags**, **Cost Categories**, Budgets per account/OU | Splitting bills manually |

## 2. Domain 2: Design for New Solutions (29%)
| # | Pattern | Usually wins | Typical distractor |
|---|---|---|---|
| 2.1 | Spiky load, don't lose requests, decouple | **SQS** buffer + consumers scaling on queue depth | Bigger instances |
| 2.2 | Strict ordering / exactly-once processing | **SQS FIFO** (MessageGroupId per entity) | Standard queue |
| 2.3 | One event → many consumers | **SNS → SQS fan-out** or **EventBridge** rules (content filtering, SaaS/AWS events) | Consumers polling one queue |
| 2.4 | Multi-step / long-running / human approval workflow | **Step Functions** (Standard = long, Express = high-volume short) | Lambda chaining / Lambda >15 min |
| 2.5 | Streaming ingestion at scale, replay | **Kinesis Data Streams** (or **MSK** if Kafka compatibility) → **Firehose** to S3/Redshift/OpenSearch | SQS for analytics replay |
| 2.6 | Global users, low-latency **static/cacheable** | **CloudFront** (+ S3 with **OAC**) | Multi-Region EC2 |
| 2.7 | Global, **non-HTTP / static IPs / fast failover** | **Global Accelerator** | CloudFront |
| 2.8 | Global **multi-Region writes** | **DynamoDB Global Tables** | Aurora Global (one writer Region) |
| 2.9 | Global **relational**, local reads, DR in minutes | **Aurora Global Database** (write forwarding if needed) | Cross-Region RDS read replica (slower failover) |
| 2.10 | Read-heavy DB / repeated queries | **ElastiCache** / **DAX** (DynamoDB) / read replicas | Scale up primary |
| 2.11 | Session state for stateless web tier | **ElastiCache** or **DynamoDB** | Sticky sessions only |
| 2.12 | Secure public API | **API Gateway** + **WAF** + Cognito / Lambda authorizer; usage plans for throttling | Exposing ALB with app-level auth only |
| 2.13 | Containers, least overhead | **ECS on Fargate** (EKS only if Kubernetes is required) | Self-managed k8s on EC2 |
| 2.14 | Shared file storage choice | Linux NFS → **EFS** · Windows SMB/AD → **FSx for Windows** · HPC + S3 → **FSx for Lustre** · NetApp/multi-protocol → **FSx for ONTAP** | EBS multi-attach / S3 as a filesystem |
| 2.15 | Secrets / DB credential rotation | **Secrets Manager** (native rotation) | Parameter Store + Lambda / env vars |
| 2.16 | Encryption with control over keys, cross-account | **KMS customer managed key** + key policy grants | AWS-managed keys (can't share cross-account) |
| 2.17 | DR design from RTO/RPO | Hours → **Backup & restore** · tens of minutes → **Pilot light** · minutes → **Warm standby** · ~zero → **Multi-site active/active**. Pick the **cheapest that meets the RTO/RPO** | Over-engineering to active/active |
| 2.18 | Protect against DDoS / L7 attacks | **Shield Advanced** + **WAF** on CloudFront/ALB; Firewall Manager for org-wide rules | Security groups / NACLs |

## 3. Domain 3: Continuous Improvement for Existing Solutions (25%)
| # | Pattern | Usually wins | Typical distractor |
|---|---|---|---|
| 3.1 | Risky deployments / need fast rollback | **Blue/green** or **canary** (CodeDeploy, Lambda alias weights, ALB weighted TGs) | In-place rolling with no rollback |
| 3.2 | SSH/bastion management, patching toil | **SSM Session Manager**, **Patch Manager**, **Automation** runbooks | Bastion hosts, cron scripts |
| 3.3 | Config drift / non-compliance fixed automatically | **AWS Config rule + auto-remediation (SSM Automation)** | Periodic manual audit |
| 3.4 | Need visibility into distributed latency | **X-Ray** / CloudWatch ServiceLens, Container Insights, **Synthetics** canaries | More logs |
| 3.5 | Repeatable infra across accounts/Regions | **CloudFormation StackSets** (service-managed, auto-deploy) / Service Catalog for self-service | Console clicks per account |
| 3.6 | Compute cost too high | **Compute Optimizer** rightsizing → **Savings Plans** for baseline → **Spot** for fault-tolerant/batch; Graviton | Buy RIs before rightsizing |
| 3.7 | Storage cost too high | S3 **lifecycle** / **Intelligent-Tiering**, **gp2 → gp3**, delete unattached EBS/old snapshots | Moving everything to Glacier (retrieval needs!) |
| 3.8 | Data transfer / NAT cost too high | **VPC gateway endpoints** (S3, DynamoDB), interface endpoints, CloudFront, keep traffic in-AZ | Bigger NAT gateway |
| 3.9 | Improve availability of existing app | Multi-AZ (RDS/ASG across AZs), ELB health checks, Route 53 health-check failover | Bigger single instance |
| 3.10 | Improve security posture of existing estate | Replace keys with **roles**, **IAM Access Analyzer**, **GuardDuty**, **Inspector**, **Security Hub** | Manual reviews |
| 3.11 | DB hitting connection limits from Lambda | **RDS Proxy** | Increase max_connections |
| 3.12 | Monolith → loosely coupled, incrementally | **Strangler fig**: API Gateway/ALB routes pieces to new services (Migration Hub Refactor Spaces) | Big-bang rewrite |

## 4. Domain 4: Migration & Modernization (20%)
| # | Pattern | Usually wins | Typical distractor |
|---|---|---|---|
| 4.1 | Which of the 7 Rs | No code change, fast → **Rehost (MGN)** · small tweak to managed service → **Replatform** (e.g. RDS, Beanstalk) · cut licensing / scale → **Refactor** · SaaS exists → **Repurchase** · not needed → **Retire** · can't move yet → **Retain** · VMware as-is → **Relocate** | Refactor when "minimal changes" is stated |
| 4.2 | Discover what's on-prem, dependencies | **Application Discovery Service** (agentless via vCenter for VMs; **agent** for processes/network dependencies) → **Migration Hub** to track | Spreadsheets/interviews |
| 4.3 | Build the business case / TCO | **Migration Evaluator** | ADS (that's inventory, not TCO) |
| 4.4 | Lift-and-shift servers with minimal downtime | **AWS Application Migration Service (MGN)**: continuous block replication, test then cutover | SMS (retired), manual AMI import |
| 4.5 | Database migration, minimal downtime | **DMS full load + CDC** → cutover; heterogeneous engines add **SCT / DMS Schema Conversion** | Dump & restore over a weekend |
| 4.6 | Lots of data, limited bandwidth | **Do the math:** if transfer over the link takes more than about a week → **Snowball Edge**; else **DataSync** (online, scheduled, verified) | Upload over a slow link |
| 4.7 | Ongoing hybrid file access (on-prem apps keep using files) | **Storage Gateway** (S3 File / FSx File / Volume / Tape) | DataSync (one-way transfer tool) |
| 4.8 | Partners send files via SFTP/FTPS | **AWS Transfer Family** → S3/EFS | SFTP server on EC2 |
| 4.9 | Migrate Windows file servers | **FSx for Windows** + **DataSync** | EFS (no SMB) |
| 4.10 | Replace tape backup | **Tape Gateway** → S3 Glacier/Deep Archive | Snowball every month |
| 4.11 | Big-bang cutover risk | Phased waves; DNS weighted routing; test cutovers with MGN | All-at-once |
| 4.12 | Modernize a migrated monolith | Containers (ECS/Fargate) / strangler fig (see 3.12) | Rewrite before migrating |

---

## 5. Study workflow with this playbook (replaces "watch every video")
1. **Read one domain's table** (20–30 min). Mark each pattern ✅ know / ❓ unsure / ❌ don't know the service.
2. **For each ❓/❌**: watch **only that service's Neal video** (or read the AWS FAQ section). Use the slides PDF for quick lookups.
3. **Drill**: Tutorials Dojo **section-based** questions for that domain, timed at 2 min/Q.
4. **For every question you review**, write the pattern number in the review log (e.g. `1.9`). Misses with **no pattern** → add a new pattern in §6.
5. Patterns you miss twice → Weak-Topics Log in the baseline.

## 6. New patterns found from practice (append)
| # | Domain | Pattern | Wins | Distractor | Found in |
|---|---|---|---|---|---|
