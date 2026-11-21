# Labs

Timeboxed hands-on labs (≤ 2 h each; none in the last 7 days before the exam). Format carried from SAP-C02 (`../../SAP-02/labs/route53-hybrid-dns/` is the worked example).

## Each lab folder contains
- `README.md`: goal and exam tasks covered → **results map** (predict each outcome first, then mark ✅/❌) → phases with copy-paste CLI → optional exam-gotcha experiments → **teardown** (same day, order matters) → lessons from the run.
- CloudFormation template(s) for the base infrastructure.
- `teardown.sh` and, where useful, an `architecture.html` diagram.

## Shared
- `AWSLabTemplate.yaml`: foundation stack (VPC, public/private subnets). Set `KeyPairName` to your own key pair.
- `../tools/close-org-prep.sh`: cost-by-service report and resource sweep; run after labs to catch anything still billing.

## Before any Bedrock lab
- Request model access for the models used, in the lab Region.
- Set a budget alarm; vector stores (e.g. OpenSearch Serverless collections) and provisioned throughput bill by the hour even when idle, so tear them down the same day.

## Lab ideas (pick by D0-00 ❌ ratings)
_(To fill: e.g. Knowledge Base over an S3 bucket with metadata filtering; Guardrail on a chat flow; Lambda MCP tool server for an agent.)_
