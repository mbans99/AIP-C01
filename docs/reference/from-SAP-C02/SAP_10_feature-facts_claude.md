# Feature Facts Log — "Does it natively do that?"

> **Owner:** Claude · **Created:** 2026-10-26 · Mohit and other agents may append rows in §2 (append only).
> **Why this file exists:** From the SAA debrief: Mohit usually narrows to the right two options, then gets stuck when they differ by a service setting he isn't sure exists. On SAP, that's what separates "least operational overhead" from "custom work". This log records those facts.

## 1. How to use it
- After every practice exam, add one row for **each option you couldn't confirm or rule out**, not just the questions you got wrong.
- Wording rule: write what the service **does natively** and what **needs custom work** (Lambda, scripts, a third party).
- Elimination heuristics:
  1. A **native, managed feature** beats Lambda, cron or scripts for "least operational overhead".
  2. An option that describes a setting you've never seen *may be invented*. AWS distractors often describe features that sound real but don't exist. Check for it here or in the docs.
  3. "Minimal changes to the application" rules out refactors (e.g. moving to DynamoDB) even if they're better architecture.
  4. Watch the scope words: per-AZ, per-Region, per-account, org-wide.

## 2. Facts
| Service | Fact (natively supports / doesn't) | Commonly confused with / distractor | Source |
|---|---|---|---|
| S3 Replication | Not transitive (A→B→C doesn't give A→C). Only replicates new objects; existing objects need **S3 Batch Replication** | "Enable replication and existing objects copy over" | seed |
| EBS | Volumes are AZ-scoped. **Snapshots** can be copied cross-Region/cross-account; **Data Lifecycle Manager** automates the copy | "Replicate EBS volume to another Region" | seed |
| DynamoDB Global Tables | Multi-active, multi-Region writes; conflicts resolved last-writer-wins by default | Read replicas (that's RDS/Aurora) | seed |
| Aurora Global Database | Storage-level cross-Region replication, typically under 1 s lag; managed switchover/failover to a secondary Region | Cross-Region read replica on RDS (logical, slower) | seed |
| SCPs | Never grant permissions; don't affect the **management account** or service-linked roles | "SCP to allow X" | seed |
| Control Tower | Controls (formerly guardrails): preventive = SCP, detective = Config rules, proactive = CloudFormation hooks. Account Factory (also an AFT/Terraform option) | Building a landing zone by hand with Orgs + scripts | seed |
| IAM Identity Center | Org-level SSO; external IdP via SAML 2.0 + automatic provisioning via SCIM; permission sets → roles in each account | Per-account IAM SAML federation (works, more overhead) | seed |
| AWS RAM | Shares TGW, subnets (VPC sharing), Route 53 Resolver rules, etc. VPC sharing participants can't modify the owner's VPC/subnets | VPC peering per account | seed |
| Transit Gateway | Transitive routing; route tables for segmentation; inter-Region **peering** (static routes); VPN attachments support **ECMP** for aggregate bandwidth | VGW (no ECMP); VPC peering (non-transitive) | seed |
| Direct Connect Gateway | One DX connection → VPCs in many Regions/accounts; no VPC-to-VPC transit through it | Thinking DXGW routes between VPCs | seed |
| Route 53 Resolver | Inbound endpoint (on-prem → AWS names) / outbound endpoint + forwarding rules (AWS → on-prem names); rules shareable via RAM | Running custom DNS servers on EC2 | seed |
| Global Accelerator | Static anycast IPs, TCP/UDP, fast cross-Region failover, no caching | CloudFront (HTTP caching; origin failover via origin groups) | seed |
| NLB vs ALB | NLB can have a static/Elastic IP per AZ; ALB cannot (put GA or NLB in front) | "Assign EIP to ALB" | seed |
| KMS multi-Region keys | Same key material/ID in multiple Regions, but each replica is a separate resource managed independently | "Global KMS key" | seed |
| Secrets Manager | Native rotation for RDS/Aurora/Redshift; replica secrets in other Regions | Parameter Store (no native rotation) | seed |
| AWS Backup | Central policies across org; cross-Region + cross-account copies; **Vault Lock** for WORM | Custom snapshot Lambdas | seed |
| StackSets | **Service-managed** (needs Orgs): targets **OUs**, roles auto-created, **auto-deploys to new accounts**; can run from a **delegated admin**; never deploys to the management account. **Self-managed**: you create admin/execution roles, target account IDs, works without Orgs | Running CloudFormation per account; thinking StackSets needs manual roles in every case | seed + TD 2026-11-04 |
| Application Migration Service (MGN) | Block-level continuous replication for rehost; replaces SMS (discontinued) | SMS still appearing in older material | seed |
| DMS / SCT | DMS full load + **CDC** for ongoing replication; heterogeneous engines need schema conversion (SCT / DMS Schema Conversion) | "DMS converts stored procedures automatically" | seed |
| DataSync | Agent-based online transfer to S3/EFS/FSx, scheduled, incremental, with verification | Storage Gateway (ongoing hybrid access, not a migration tool) | seed |
| Lambda | Max 15-minute timeout; long jobs → Step Functions / ECS / Batch | "Increase Lambda timeout to 1 hour" | seed |
| AWS Backup (supported list) | One plan covers S3, EBS, EFS, FSx, RDS, Aurora, DynamoDB, DocumentDB, Neptune, Redshift, Timestream, EC2 (AMIs), **Storage Gateway Volume Gateway**, VMware (Backup gateway), CloudFormation stacks, SAP HANA on EC2. Cross-Region copy = copy rule to a vault in the other Region | Carving one service out to a separate tool (RDS read replica, DataSync for EFS, manual EBS snapshot copies) | Official practice exam 2026-11-14 |
| Route 53 Application Recovery Controller (ARC) | **Routing controls** = simple on/off switches per Region/cell (flipped by a person or automation such as Lambda on CloudWatch alarms) for failover that catches **partial** failures. **Readiness checks** = is the standby set up and scaled (not failure detection). **Zonal shift / autoshift** = move traffic off an impaired AZ | Route 53 health check on the endpoint only (misses partial/back-end failures); readiness checks as failover triggers | Official practice exam 2026-11-14 |
| Elastic Disaster Recovery (DRS) | Continuous block-level replication of servers to a low-cost staging area; RPO seconds, RTO minutes; recovery to EC2; failback supported | MGN (same engine, but for one-time **migration**, not ongoing DR) | Claude glue list 2026-11-14 |
| Service Catalog | Portfolios of approved CloudFormation products; **launch constraints** let users launch without broad IAM permissions; portfolios shareable across accounts/Orgs | Giving users raw CloudFormation + broad IAM | Claude glue list 2026-11-14 |
| Compute Optimizer | ML right-sizing recommendations from CloudWatch metrics for EC2, Auto Scaling groups, EBS, Lambda, ECS on Fargate, RDS; can run org-wide | Trusted Advisor (broad checks, less precise sizing); Cost Explorer (spend, not sizing) | Claude glue list 2026-11-14 |
| Trusted Advisor | Checks across cost, performance, security, fault tolerance, service limits (and operational excellence); **full check set needs Business/Enterprise Support** | Compute Optimizer (deeper right-sizing) | Claude glue list 2026-11-14 |
| License Manager | Tracks/enforces license rules (vCPU, socket, core counts) for BYOL such as Oracle and Windows; works with Dedicated Hosts (host resource groups) and Systems Manager | Tracking licenses in spreadsheets / custom scripts | Claude glue list 2026-11-14 |
| Network Firewall | Managed stateful + stateless VPC firewall, Suricata-compatible rules, domain filtering; deployed in firewall subnets, often centralized in an inspection VPC behind Transit Gateway; policies can be pushed by Firewall Manager | Security groups / NACLs (no domain filtering, no deep inspection); third-party appliances on EC2 | Claude glue list 2026-11-14 |
| Transfer Family | Managed SFTP / FTPS / FTP / AS2 endpoints into S3 or EFS; custom identity provider via Lambda or API Gateway | Running an SFTP server on EC2; DataSync (bulk transfer, not a partner-facing endpoint) | Claude glue list 2026-11-14 |
| Route 53 Evaluate Target Health | **Alias-only** yes/no setting: the record inherits the health of its AWS target (e.g. an ALB is healthy if it has healthy targets), so no separate health check is needed. Works with any routing policy: latency records + Evaluate Target Health = active-active with automatic failover. The **failover** routing policy is separate (active-passive, primary/secondary) | Creating Route 53 health checks for an ALB (works, more setup); CNAME records (no Evaluate Target Health; can't be used at the apex) | Official practice exam 2026-11-14 |
