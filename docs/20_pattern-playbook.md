# AIP-C01 Pattern Playbook: attack by pattern, not by service

> **Owner:** Claude · **Created:** 2026-11-20 (method carried from SAP-C02) · Mohit/agents: append new patterns in §6 (append only)
> **Why:** On SAP, questions repeated a limited set of *problem shapes* per domain; studying by pattern took exam scores from ~50% to 81%. This file is the primary study spine; videos are **on-demand lookups** for services inside a pattern he doesn't know.
> **How to use a pattern:** it **shortlists** 1–2 options fast; the **constraint words** decide. Distractors match a pattern's keyword but break a constraint, so never pick on the keyword alone.
> ⚠️ **§1–5 are seeds taken from the services the official exam guide names for each skill.** They are not yet validated against practice questions. Confirm, correct or replace them as questions come in, and fill the distractor column from real misses.

---

## 0. Tie-breakers that apply to every domain (carried from SAP, GenAI meaning added)
| Constraint word | What usually wins | GenAI reading | What usually loses |
|---|---|---|---|
| **Least operational overhead** | Managed / native feature / serverless | Bedrock managed feature (Knowledge Bases, Guardrails, Prompt Management, Evaluations, Agents) | Self-hosted model on EC2, hand-built RAG/moderation in Lambda |
| **Most cost-effective** | Pay for what's used; right-size | Smaller/cheaper model for routine queries, caching, batch inference, token trimming | Largest model for everything; provisioned capacity nobody fills |
| **Minimal changes to the application** | Config-only changes | Swap model via config/AppConfig, add a guardrail, change KB settings | Rewriting the app, retraining a model |
| **Lowest latency** | Closer, smaller, streaming | Streaming responses, latency-optimized inference, smaller model, caching | Bigger model, synchronous long chains |
| **Most secure / least privilege** | Roles, private endpoints, CMKs | VPC endpoints for Bedrock, IAM scoped to specific model ARNs, PII filtering before the model | Public endpoints, broad `bedrock:*` |
| **As quickly as possible** | Existing managed solution | Pre-built FM via API, managed KB, before fine-tuning | Training / fine-tuning first |

**Speed rule:** read the last sentence → name the pattern → shortlist → decide on the constraint word. Max 3 min, then flag.

## 1. Domain 1: FM Integration, Data Management & Compliance (31%)
| # | Pattern | Usually wins (seed) | Typical distractor |
|---|---|---|---|
| 1.1 | Validate a design against best practice | **Well-Architected Tool + Generative AI Lens** | |
| 1.2 | Switch models/providers **without code changes** | Model ID in **AppConfig**, behind Lambda / API Gateway abstraction | Hard-coded model ID |
| 1.3 | Model not available in my Region / capacity limits / resilience | **Bedrock Cross-Region Inference**; circuit breaker + fallback model (Step Functions) | |
| 1.4 | Deploy and version a fine-tuned / domain model | **SageMaker AI** endpoint + **Model Registry**; **LoRA / adapters** for parameter-efficient adaptation; rollback strategy | |
| 1.5 | Validate data quality before FM use | **Glue Data Quality**, SageMaker Data Wrangler, CloudWatch metrics | |
| 1.6 | Audio/image/text inputs | Transcribe (audio), Bedrock multimodal models, SageMaker Processing | |
| 1.7 | Managed RAG over documents | **Bedrock Knowledge Bases** (managed chunking, embeddings, vector store) | |
| 1.8 | Vector search on an existing relational DB | **Aurora PostgreSQL + pgvector** | |
| 1.9 | Vector search at scale / hybrid keyword + semantic | **OpenSearch Service** (vector search, Neural plugin, sharding, multi-index) | |
| 1.10 | Improve retrieval relevance | **Hybrid search** + **Bedrock reranker** models; metadata filtering | |
| 1.11 | Better retrieval for complex questions | **Query expansion/decomposition** (Bedrock, Lambda, Step Functions) | |
| 1.12 | Keep the vector store current | **Incremental sync / change detection**, scheduled refresh | Full re-index every time |
| 1.13 | Chunking choice | Fixed-size vs **hierarchical** vs semantic by document structure (Bedrock chunking options) | |
| 1.14 | Embedding model choice | **Titan embeddings** by dimensionality / domain fit; batch generate via Lambda | |
| 1.15 | Versioned, approved, parameterised prompts | **Bedrock Prompt Management** (+ CloudTrail usage, CloudWatch Logs) | Prompts in code |
| 1.16 | Multi-step prompt chain with branching, little code | **Bedrock Prompt Flows** | Lambda chains |
| 1.17 | Expose retrieval to FMs consistently | Function calling / **MCP** clients for vector queries | |

## 2. Domain 2: Implementation & Integration (26%)
| # | Pattern | Usually wins (seed) | Typical distractor |
|---|---|---|---|
| 2.1 | Multi-agent system with memory and tools | **Strands Agents**, **AWS Agent Squad**, **Bedrock AgentCore**; **MCP** for agent-tool access | |
| 2.2 | ReAct / structured reasoning orchestration | **Step Functions** | |
| 2.3 | Keep an agent from running away | Step Functions **stopping conditions**, Lambda **timeouts**, **IAM boundaries**, circuit breakers | |
| 2.4 | Human review/approval in the loop | **Step Functions** (wait for callback) + API Gateway feedback | |
| 2.5 | Lightweight tool server vs complex tool server | **Lambda** (stateless MCP server) vs **ECS** (complex MCP server) | |
| 2.6 | Steady, high, predictable inference volume | **Provisioned throughput** | On-demand at the throttle limit |
| 2.7 | Custom/open model needing GPUs, special containers | **SageMaker AI endpoints** | |
| 2.8 | Routine queries cheaply, hard ones to a big model | **Model cascading / routing** (smaller model first) | One large model for all |
| 2.9 | Real-time token-by-token output | Bedrock **streaming APIs** + WebSockets / SSE | Wait for full response |
| 2.10 | High-volume async processing | **SQS** + SDK workers | Synchronous calls from the web tier |
| 2.11 | Throttling / transient model errors | SDK **exponential backoff**, API Gateway rate limiting, fallback model | Immediate retries |
| 2.12 | Content-based routing to specialised models | **Step Functions** (dynamic) / API Gateway request transformation | |
| 2.13 | Data must stay on-prem / at the edge | **Outposts** / **Wavelength** | |
| 2.14 | Central, governed access to models for many teams | **GenAI gateway** (central abstraction + observability) with CI/CD (CodePipeline/CodeBuild) | Each team calls models directly |
| 2.15 | Automated document processing | **Bedrock Data Automation**, Step Functions orchestration | |
| 2.16 | Developer productivity / code generation | **Amazon Q Developer** | |

## 3. Domain 3: AI Safety, Security & Governance (20%)
| # | Pattern | Usually wins (seed) | Typical distractor |
|---|---|---|---|
| 3.1 | Block harmful input/output, denied topics | **Bedrock Guardrails** | Custom regex in Lambda |
| 3.2 | Reduce hallucinations | Ground with a **Knowledge Base**, confidence/similarity checks, **JSON Schema** structured output | Lower temperature alone |
| 3.3 | Defense in depth | Comprehend pre-filter → Guardrails → Lambda post-validation → API Gateway response filtering | Single control |
| 3.4 | Prompt injection / jailbreak | Detection + input sanitisation + safety classifiers + adversarial testing | |
| 3.5 | Detect PII in stored data (S3) | **Macie** | |
| 3.6 | Detect/redact PII in text in flight | **Comprehend** PII detection, **Guardrails** sensitive-info filters, masking | |
| 3.7 | Keep model traffic private | **VPC endpoints (PrivateLink)** + IAM policies | NAT to the public endpoint |
| 3.8 | Fine-grained data access for RAG sources | **Lake Formation** | Bucket policies only |
| 3.9 | Data retention for prompts/logs | **S3 Lifecycle** | |
| 3.10 | Document model limits / compliance | **SageMaker model cards** | |
| 3.11 | Lineage and source attribution | **Glue Data Catalog** + metadata tagging + **CloudTrail** | |
| 3.12 | Show reasoning / evidence | **Bedrock agent tracing**, citations from KB | |
| 3.13 | Fairness / A/B on prompts | Prompt Management + Prompt Flows A/B, **LLM-as-a-judge** | |

## 4. Domain 4: Operational Efficiency & Optimization (12%)
| # | Pattern | Usually wins (seed) | Typical distractor |
|---|---|---|---|
| 4.1 | Token cost too high | Prompt compression, context pruning, response length limits, token tracking | |
| 4.2 | Same/similar requests repeat | **Prompt caching**, **semantic caching**, request hashing, edge caching | Bigger model |
| 4.3 | Large offline workload | **Batch inference** | Synchronous loops |
| 4.4 | Time-sensitive responses | **Latency-optimized** models, streaming, parallel requests, pre-computation | |
| 4.5 | Output too random / too repetitive | Tune **temperature, top-k, top-p** by requirement | |
| 4.6 | Monitor token usage, quality, drift | **CloudWatch** metrics + **Bedrock model invocation logging**, anomaly detection | |
| 4.7 | Unexpected spend | **Cost Anomaly Detection**, Cost Explorer | |
| 4.8 | Detect hallucinations in production | **Golden datasets**, output diffing, reasoning-path tracing | |

## 5. Domain 5: Testing, Validation & Troubleshooting (11%)
| # | Pattern | Usually wins (seed) | Typical distractor |
|---|---|---|---|
| 5.1 | Compare models / configs systematically | **Bedrock Model Evaluations**, A/B and canary tests | Manual spot checks |
| 5.2 | Evaluate at scale without humans | **LLM-as-a-judge** | |
| 5.3 | Human quality review | Feedback/rating interfaces, annotation workflows (**Augmented AI**, **Ground Truth**) | |
| 5.4 | Evaluate RAG / retrieval | **RAG evaluation**, relevance scoring, context matching, retrieval latency | |
| 5.5 | Evaluate agents | Task completion rate, tool-use effectiveness, **Bedrock Agent evaluations** | |
| 5.6 | Block bad model updates | Automated **quality gates**, regression tests, synthetic user workflows | |
| 5.7 | Truncated / incomplete answers | Context-window overflow diagnostics, dynamic chunking | |
| 5.8 | Trace prompt problems | **CloudWatch Logs Insights** on prompts/responses, **X-Ray**, schema validation | |

---

## 6. New patterns found from practice (append)
| # | Domain | Pattern | Wins | Distractor | Found in |
|---|---|---|---|---|---|

## 7. Carried from SAP-C02 (still valid here)
Full table: `reference/from-SAP-C02/SAP_20_pattern-playbook.md`.
| SAP # | Pattern | Wins | AIP angle |
|---|---|---|---|
| 2.1 | Spiky load, don't lose requests | **SQS** buffer + consumers scaling on backlog | Async inference, protect model quotas |
| 2.3 | One event → many consumers | **SNS → SQS** fan-out / **EventBridge** | Event-driven GenAI integration (2.3.1) |
| 2.4 | Multi-step / long / human approval | **Step Functions** (Standard long, Express high-volume short) | Agent orchestration, review workflows |
| 2.5 | Streaming ingestion, replay | **Kinesis / MSK** → Firehose | Real-time data into vector stores |
| 2.6 | Global low-latency cacheable content | **CloudFront** | Edge caching of responses (4.1.4) |
| 2.10–2.11 | Repeated reads / session state | **ElastiCache / DynamoDB** | Semantic cache, conversation memory |
| 2.12 | Secure public API | **API Gateway + WAF + Cognito / Lambda authorizer**, usage plans | Model API front door, rate limiting |
| 2.13 | Containers, least overhead | **ECS on Fargate** | MCP servers, gateways |
| 2.15–2.16 | Secrets; key control | **Secrets Manager**; **KMS CMK** | Third-party model API keys; encrypting KB data |
| 1.9 | Expose a service privately across VPCs | **PrivateLink** | Bedrock interface endpoints |
| 3.1 | Risky deployments | **Blue/green / canary** (CodeDeploy, Lambda alias weights) | Canary model rollout (5.1.2) |
| 3.4 | Distributed latency visibility | **X-Ray**, Synthetics canaries | Trace FM calls (2.4.3, 2.5.6) |
| 3.5 | Repeatable infra across accounts | **StackSets / Service Catalog** | Standardised GenAI components (1.1.3) |
