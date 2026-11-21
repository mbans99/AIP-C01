# D0-00 · Exam-guide concept map (all task statements, self-rating)

> **Owner:** Claude (structure) · **Mohit:** set the ratings · **Created:** 2026-11-20 from the official AIP-C01 exam guide (same approach as SAP D1-00).
> **Rating:** ✅ know it (real work or SAP) · ❓ unsure · ❌ new. **Topic** = the topic file that will cover it (baseline §10).
> Skills are condensed; the guide's own examples (services/techniques) are kept because questions are built from them.
> Source: https://docs.aws.amazon.com/aws-certification/latest/ai-professional-01/ai-professional-01.html

## Domain 1 · FM Integration, Data Management, and Compliance (31%)
| Skill | What it covers (guide examples) | Topic | Rating |
|---|---|---|---|
| 1.1.1 | Architecture that fits business/technical constraints (FM choice, integration, deployment) | D1-01 | |
| 1.1.2 | Proof of concept to validate feasibility and value (Bedrock) | D1-01 | |
| 1.1.3 | Standardised components (Well-Architected, **WA Tool Generative AI Lens**) | D1-01 | |
| 1.2.1 | Choose FMs (benchmarks, capabilities, limitations) | D1-01 | |
| 1.2.2 | Dynamic model/provider switching without code changes (Lambda, API Gateway, **AppConfig**) | D1-01 | |
| 1.2.3 | Resilience (Step Functions circuit breaker, **Bedrock Cross-Region Inference**, cross-Region deployment, graceful degradation) | D1-01 | |
| 1.2.4 | Customised model deployment and lifecycle (SageMaker AI, **LoRA/adapters**, **Model Registry**, automated pipelines, rollback, retirement) | D1-01 | |
| 1.3.1 | Data validation (**Glue Data Quality**, SageMaker **Data Wrangler**, Lambda, CloudWatch) | D1-02 | |
| 1.3.2 | Multimodal processing (Bedrock multimodal models, SageMaker Processing, **Transcribe**) | D1-02 | |
| 1.3.3 | Input formatting (Bedrock JSON requests, SageMaker endpoint payloads, conversation format) | D1-02 | |
| 1.3.4 | Improve input quality (Bedrock reformatting, **Comprehend** entities, Lambda normalisation) | D1-02 | |
| 1.4.1 | Vector DB architectures (**Bedrock Knowledge Bases**, **OpenSearch Neural plugin**, RDS + S3, DynamoDB for metadata) | D1-03 | |
| 1.4.2 | Metadata frameworks (S3 object metadata, custom attributes, tags) | D1-03 | |
| 1.4.3 | Vector search performance (OpenSearch sharding, multi-index, hierarchical indexing) | D1-03 | |
| 1.4.4 | Connectors to document systems, wikis, KBs | D1-03 | |
| 1.4.5 | Keep vector stores current (incremental updates, change detection, sync, scheduled refresh) | D1-03 | |
| 1.5.1 | Chunking (Bedrock chunking, fixed-size via Lambda, hierarchical) | D1-03 | |
| 1.5.2 | Embeddings (**Titan** by dimensionality/domain, Bedrock embedding models, batch via Lambda) | D1-03 | |
| 1.5.3 | Vector search deployment (OpenSearch, **Aurora pgvector**, KB managed vector store) | D1-03 | |
| 1.5.4 | Better relevance (semantic search, **hybrid search**, **Bedrock rerankers**) | D1-03 | |
| 1.5.5 | Query handling (query expansion, decomposition, transformation) | D1-03 | |
| 1.5.6 | Consistent access (function calling, **MCP** clients, standard retrieval APIs) | D1-03 | |
| 1.6.1 | Instruction frameworks (**Prompt Management** roles, **Guardrails**, templates) | D1-04 | |
| 1.6.2 | Interactive context (Step Functions clarification, Comprehend intent, DynamoDB history) | D1-04 | |
| 1.6.3 | Prompt governance (parameterised templates, approval, S3 repos, CloudTrail, CloudWatch Logs) | D1-04 | |
| 1.6.4 | Prompt QA (Lambda output checks, Step Functions edge cases, CloudWatch regression) | D1-04 | |
| 1.6.5 | Iterative refinement (structured input, output format, chain-of-thought, feedback loops) | D1-04 | |
| 1.6.6 | Complex prompt systems (**Prompt Flows**: chains, branching, reusable components, pre/post-processing) | D1-04 | |

## Domain 2 · Implementation and Integration (26%)
| Skill | What it covers (guide examples) | Topic | Rating |
|---|---|---|---|
| 2.1.1 | Autonomous systems with memory/state (**Strands Agents**, **Agent Squad**, **MCP**) | D2-01 | |
| 2.1.2 | Structured reasoning (Step Functions **ReAct**, chain-of-thought) | D2-01 | |
| 2.1.3 | Safeguarded workflows (stopping conditions, timeouts, IAM boundaries, circuit breakers) | D2-01 | |
| 2.1.4 | Model coordination (specialised FMs, ensembles, selection frameworks) | D2-01 | |
| 2.1.5 | Human-in-the-loop (Step Functions approvals, API Gateway feedback) | D2-01 | |
| 2.1.6 | Tool integrations (Strands API, function definitions, Lambda validation/error handling) | D2-01 | |
| 2.1.7 | Model extensions (Lambda stateless MCP servers, ECS MCP servers, MCP clients) | D2-01 | |
| 2.2.1 | Deployment by need (Lambda on-demand, **provisioned throughput**, SageMaker endpoints) | D2-02 | |
| 2.2.2 | LLM-specific deployment (containers for memory/GPU/token capacity, model loading) | D2-02 | |
| 2.2.3 | Optimised deployment (smaller models, **model cascading**) | D2-02 | |
| 2.3.1 | Enterprise connectivity (legacy APIs, event-driven, data sync) | D2-03 | |
| 2.3.2 | Add GenAI to existing apps (API Gateway, Lambda webhooks, EventBridge) | D2-03 | |
| 2.3.3 | Secure access (identity federation, RBAC, least-privilege model access) | D2-03 | |
| 2.3.4 | Cross-environment / data residency (**Outposts**, **Wavelength**) | D2-03 | |
| 2.3.5 | CI/CD and **GenAI gateway** (CodePipeline, CodeBuild, security scans, rollback, central abstraction) | D2-03 | |
| 2.4.1 | Flexible interaction (Bedrock sync APIs, SDKs + SQS async, API Gateway validation) | D2-04 | |
| 2.4.2 | Real-time (Bedrock **streaming APIs**, WebSockets/SSE, chunked transfer) | D2-04 | |
| 2.4.3 | Resilience (backoff, rate limiting, fallbacks, X-Ray) | D2-04 | |
| 2.4.4 | Model routing (static config, Step Functions content-based, metric-based, API Gateway transforms) | D2-04 | |
| 2.5.1 | GenAI API interfaces (streaming, token limits, timeout retries) | D2-04 | |
| 2.5.2 | Accessible interfaces (**Amplify**, OpenAPI, Prompt Flows no-code) | D2-04 | |
| 2.5.3 | Business system enhancements (CRM via Lambda, document processing, **Bedrock Data Automation**) | D2-04 | |
| 2.5.4 | Developer productivity (**Q Developer**) | D2-04 | |
| 2.5.5 | Advanced apps (Strands, Agent Squad, Step Functions agent patterns, prompt chaining) | D2-01/D2-04 | |
| 2.5.6 | Troubleshooting efficiency (Logs Insights, X-Ray, Q Developer) | D5-02 | |

## Domain 3 · AI Safety, Security, and Governance (20%)
| Skill | What it covers (guide examples) | Topic | Rating |
|---|---|---|---|
| 3.1.1 | Input safety (**Guardrails**, custom moderation in Step Functions/Lambda) | D3-01 | |
| 3.1.2 | Output safety (Guardrails, toxicity evaluations, text-to-SQL for determinism) | D3-01 | |
| 3.1.3 | Hallucination reduction (KB grounding, confidence scoring, similarity, **JSON Schema**) | D3-01 | |
| 3.1.4 | Defense in depth (Comprehend pre-filter, Guardrails, Lambda post-validation, API Gateway filtering) | D3-01 | |
| 3.1.5 | Adversarial threats (**prompt injection/jailbreak** detection, sanitisation, classifiers, adversarial testing) | D3-01 | |
| 3.2.1 | Protected environments (VPC endpoints, IAM, **Lake Formation**, CloudWatch) | D3-02 | |
| 3.2.2 | Privacy (**Comprehend** and **Macie** PII, Bedrock data privacy, Guardrails, S3 Lifecycle retention) | D3-02 | |
| 3.2.3 | Privacy-focused systems (masking, anonymisation, Comprehend PII, Guardrails) | D3-02 | |
| 3.3.1 | Compliance (SageMaker **model cards**, Glue lineage, tagging, decision logs) | D3-03 | |
| 3.3.2 | Source tracking (Glue Data Catalog, attribution metadata, CloudTrail) | D3-03 | |
| 3.3.3 | Organisational governance frameworks | D3-03 | |
| 3.3.4 | Continuous monitoring (misuse/drift/bias detection, alerting, token-level redaction, output filters) | D3-03 | |
| 3.4.1 | Transparency (reasoning displays, confidence metrics, evidence, **agent tracing**) | D3-03 | |
| 3.4.2 | Fairness (CloudWatch metrics, Prompt Management/Flows A/B, **LLM-as-a-judge**) | D3-03 | |
| 3.4.3 | Policy compliance (Guardrails, model cards, Lambda checks) | D3-03 | |

## Domain 4 · Operational Efficiency and Optimization (12%)
| Skill | What it covers (guide examples) | Topic | Rating |
|---|---|---|---|
| 4.1.1 | Token efficiency (estimation, context optimisation, compression, pruning, response limits) | D4-01 | |
| 4.1.2 | Cost-effective model selection (tiering by complexity, price/performance) | D4-01 | |
| 4.1.3 | Throughput (batching, capacity planning, auto scaling, provisioned throughput) | D4-01 | |
| 4.1.4 | Caching (semantic, fingerprinting, edge, request hashing, **prompt caching**) | D4-01 | |
| 4.2.1 | Latency vs cost (pre-computation, **latency-optimized** models, parallel requests, streaming) | D4-01 | |
| 4.2.2 | Retrieval performance (index optimisation, query preprocessing, hybrid scoring) | D4-01 | |
| 4.2.3 | Throughput optimisation (token processing, **batch inference**, concurrency) | D4-01 | |
| 4.2.4 | Model parameters (**temperature, top-k, top-p**, A/B testing) | D4-01 | |
| 4.2.5 | Resource allocation (token capacity planning, GenAI-shaped auto scaling) | D4-01 | |
| 4.2.6 | System performance (call profiling, vector query optimisation, LLM latency techniques) | D4-01 | |
| 4.3.1 | Holistic observability (operational, tracing, business metrics, dashboards) | D4-02 | |
| 4.3.2 | GenAI monitoring (token usage, hallucination rate, quality, drift, **model invocation logs**, cost anomalies) | D4-02 | |
| 4.3.3 | Integrated observability (dashboards, compliance, forensic audit, user interaction tracking) | D4-02 | |
| 4.3.4 | Tool performance (tool-call tracking, multi-agent coordination, baselines) | D4-02 | |
| 4.3.5 | Vector store operations (performance monitoring, index optimisation, data quality) | D4-02 | |
| 4.3.6 | GenAI failure modes (golden datasets, output diffing, reasoning-path tracing) | D4-02 | |

## Domain 5 · Testing, Validation, and Troubleshooting (11%)
| Skill | What it covers (guide examples) | Topic | Rating |
|---|---|---|---|
| 5.1.1 | Quality metrics (relevance, factual accuracy, consistency, fluency) | D5-01 | |
| 5.1.2 | Systematic evaluation (**Bedrock Model Evaluations**, A/B, canary, cost/latency vs quality) | D5-01 | |
| 5.1.3 | User-centred evaluation (feedback, ratings, annotation) | D5-01 | |
| 5.1.4 | QA processes (continuous evaluation, regression, quality gates) | D5-01 | |
| 5.1.5 | Multi-perspective assessment (RAG evaluation, LLM-as-a-judge, human feedback) | D5-01 | |
| 5.1.6 | Retrieval testing (relevance scoring, context matching, latency) | D5-01 | |
| 5.1.7 | Agent evaluation (task completion, tool use, **Bedrock Agent evaluations**, reasoning quality) | D5-01 | |
| 5.1.8 | Reporting to stakeholders (visualisation, automated reports, model comparisons) | D5-01 | |
| 5.1.9 | Deployment validation (synthetic workflows, hallucination/drift checks) | D5-01 | |
| 5.2.1 | Content handling (context overflow, dynamic chunking, truncation) | D5-02 | |
| 5.2.2 | FM integration issues (error logging, request validation, response analysis) | D5-02 | |
| 5.2.3 | Prompt problems (testing frameworks, version comparison) | D5-02 | |
| 5.2.4 | Retrieval problems (embedding diagnostics, drift, chunking, vector search tuning) | D5-02 | |
| 5.2.5 | Prompt maintenance (template testing, Logs Insights, X-Ray, schema validation) | D5-02 | |

## In-scope services that are new compared with SAP (from the guide's in-scope list)
Bedrock, **Bedrock AgentCore**, Bedrock Knowledge Bases, Prompt Management, Prompt Flows, Titan, Augmented AI, Comprehend, Kendra, Lex, Q Business (+ Apps), Q Developer, Amazon Quick, Rekognition, Textract, Transcribe, SageMaker AI (Clarify, Data Wrangler, Ground Truth, JumpStart, Model Monitor, Model Registry, Neo, Processing, Unified Studio), AppFlow, AppConfig, AppSync, Amplify, Kiro, Encryption SDK, Wavelength, Connect, Chatbot, Managed Grafana, Cost Anomaly Detection, Well-Architected Tool.
