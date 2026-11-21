# Feature Facts Log — "Does it natively do that?"

> **Owner:** Claude · **Created:** 2026-11-20 (format carried from SAP-C02) · Mohit and other agents may append rows in §2 (append only).
> **Why this file exists:** From the SAA debrief, confirmed on SAP: Mohit usually narrows to the right two options, then gets stuck when they differ by a service setting he isn't sure exists. GenAI services add features every month, so this matters even more here.

## 1. How to use it
- After every practice set, add one row for **each option you couldn't confirm or rule out**, not just the questions you got wrong.
- Wording rule: write what the service **does natively** and what **needs custom work** (Lambda, scripts, a third party).
- Add the **date checked**; Bedrock features change fast. If an answer key disagrees with current docs, log it as an **exam-era fact** (note both).
- Elimination heuristics:
  1. A **native, managed feature** beats Lambda, cron or scripts for "least operational overhead" (e.g. a managed Knowledge Base vs a hand-built RAG pipeline, a guardrail vs custom regex filtering).
  2. An option that describes a setting you've never seen *may be invented*. Check here or in the docs.
  3. "Minimal changes to the application" rules out re-architecting even if it's better design.
  4. Watch the scope words: per-model, per-Region, per-account, per-knowledge-base, org-wide.

## 2. Facts
| Service | Fact (natively supports / doesn't) | Commonly confused with / distractor | Source |
|---|---|---|---|
| Lambda | Max 15-minute timeout; long jobs → Step Functions / ECS / Batch | "Increase Lambda timeout to 1 hour" | SAP seed |
| Secrets Manager | Native rotation for RDS/Aurora/Redshift; replica secrets in other Regions | Parameter Store (no native rotation) | SAP seed |
| KMS multi-Region keys | Same key material/ID in multiple Regions, but each replica is a separate resource managed independently | "Global KMS key" | SAP seed |
| IAM Identity Center | Org-level SSO; external IdP via SAML 2.0 + automatic provisioning via SCIM; permission sets → roles in each account | Per-account IAM SAML federation (works, more overhead) | SAP seed |
| DynamoDB Global Tables | Multi-active, multi-Region writes; last-writer-wins by default | Read replicas (that's RDS/Aurora) | SAP seed |
| Service Catalog | Portfolios of approved CloudFormation products; **launch constraints** let users launch without broad IAM permissions; shareable across accounts | Raw CloudFormation + broad IAM | SAP glue list |
| DataSync | Agent-based online transfer to S3/EFS/FSx, scheduled, incremental, verified | Storage Gateway (ongoing hybrid access) | SAP seed |
| Transfer Family | Managed SFTP/FTPS/FTP/AS2 into S3 or EFS | SFTP server on EC2; DataSync | SAP glue list |
| CloudWatch Logs subscription filter | Real-time stream of matching log events to Kinesis, Firehose, Lambda or OpenSearch; max 2 per log group | `CreateExportTask` (batch) | SAP D3-02 |
| CloudWatch cross-account observability | One monitoring account sees metrics/logs/traces of many source accounts | Copying logs per account | SAP D3-02 |
