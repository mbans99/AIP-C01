# AIP-C01 Preparation — Common Baseline (all agents read this first)

> **Purpose:** Single source of truth shared by every agent helping Mohit prepare for **AWS Certified Generative AI Developer – Professional (AIP-C01)**.
> **Rule:** Read this before contributing. Edit only the section you own or the Change Log; propose larger changes to Mohit.
> **Format:** Carried over from the SAP-C02 workspace (`../SAP-02`), which got Mohit from ~50% on the diagnostic to a pass (806). What came over and why: `05_carryover-from-SAP-C02.md`.
> **Last updated:** 2026-11-20 by Claude (initial version)

---

## 1. Candidate Profile
- **Name:** Mohit — Software Architect at Vrio (broadcast MSO). Previously at DirecTV (DSS/DVB), set-top box middleware, J2EE.
- **Hands-on AWS:** Designed and led teams building highly distributed systems on **MSK, Lambda (heavily), ECS**, API Gateway, DynamoDB, S3/CloudFront (incl. a DRM/DASH streaming POC). On-prem MySQL → RDS migration work.
- **Certifications:** SAA-C03 **805** (2026-10-23) · **SAP-C02 806** (Nov 2026).
- **Strong (from real work + SAP prep):** distributed/event-driven design (SQS/SNS/EventBridge, Step Functions), Lambda, API Gateway, ECS/Fargate, DynamoDB, VPC/PrivateLink/endpoints, IAM (roles, trust policies, PassRole, ABAC), Identity Center, CloudWatch/CloudTrail/X-Ray, CodePipeline/CodeDeploy/CloudFormation, Kinesis/MSK, OpenSearch basics.
- **New for this exam (to confirm in D0-00):** Bedrock (models, inference options, Knowledge Bases, Agents/AgentCore, Guardrails, Prompt Management/Flows, Evaluations, Data Automation), RAG design (chunking, embeddings, vector stores, reranking, hybrid search), agent frameworks (Strands Agents, Agent Squad, MCP), SageMaker AI deployment/registry/Clarify/Model Monitor, Comprehend/Macie for PII, GenAI evaluation and troubleshooting.
- **Hands-on GenAI experience:** _Mohit to fill (exam guide expects ~1 year)._

## 2. Exam Facts (AIP-C01) — from the official exam guide and exam page (checked 2026-11-20)
- **75 questions (65 scored + 10 unscored), 180 minutes**, pass = **750/1000**, compensatory scoring (no per-domain minimum).
- **Question types:** multiple choice (1 of 4) and **multiple response (2+ of 5+, all must be right; no partial credit)**. No penalty for guessing; blanks score as wrong.
- **USD 300**, Pearson VUE test center or online proctored. No prerequisites.
- 💰 Check the **50% discount voucher** from the SAP-C02 certification (AWS Certification Account → Benefits).
- ⚠️ Retake rule (AWS policy, as for SAP): **14-day wait** + full fee after a fail.
- Out of scope: model development/training, advanced ML techniques, data/feature engineering.
- Domains:
  | # | Domain | Weight | ≈ scored Qs |
  |---|--------|--------|------|
  | 1 | Foundation Model Integration, Data Management, and Compliance | **31%** | ~20 |
  | 2 | Implementation and Integration | **26%** | ~17 |
  | 3 | AI Safety, Security, and Governance | **20%** | ~13 |
  | 4 | Operational Efficiency and Optimization for GenAI Applications | 12% | ~8 |
  | 5 | Testing, Validation, and Troubleshooting | 11% | ~7 |
- Full task/skill list with Mohit's self-rating: `topics/D0-00_exam-guide-concept-map.md`.
- Official guide: https://docs.aws.amazon.com/aws-certification/latest/ai-professional-01/ai-professional-01.html

## 3. Resources & How Each Is Used
_To decide (§7). Carried rules from SAP:_
| Resource | Role | Note |
|----------|------|------|
| Official exam guide (task statements + in-scope services list) | **Syllabus** | Drives D0-00 and the topic pre-fills |
| Primary video course | _TBD_ | 1.5–2x; skip/skim per §5 |
| Practice-question bank (Tutorials Dojo or similar) | **Primary practice exams** | Check AIP-C01 availability. Section-based mode for topic sets, timed mode for full exams |
| AWS Skill Builder official practice exam / question set | Closest match to the real exam | Check availability for AIP-C01 |
| AWS docs, Bedrock user guide, Well-Architected **Generative AI Lens** | Reference / gap-filling | Named explicitly in task 1.1 |
| Hands-on in Bedrock console + small labs | Feature-level knowledge | Timeboxed (see §4 lessons) |
| ❌ Braindump sites / "actual exam questions" channels | **Not used** | Violates the AWS Candidate Code of Conduct (risks all certs); answers often wrong |
| Generic Udemy "practice test" sets by unknown authors | Avoid / verify | Quality varies; third-party pages already disagree on basic exam facts |

## 4. Study Plan
_Pending exam date and resources (§7). The plan will be written day-by-day like SAP, using these carried rules._

### 4a. Lessons carried from SAA-C03 and SAP-C02 (apply from day 1)
1. **Practice starts on day 1** with a timed diagnostic. SAA had too little practice; SAP's diagnostic (~50%) exposed pacing before it was too late.
2. **Pattern-first study.** After SAP exam #1, questions turned out to repeat a limited set of problem shapes. `20_pattern-playbook.md` is the study spine; videos are on-demand lookups for ❓/❌ services. SAP went ~50% → 81% on the next full exam.
3. **The gap is feature-level knowledge** ("is that natively supported?"), not concepts or reading. Fixes: `10_feature-facts_claude.md` after every practice set, 15–20 min console walk-throughs (open the wizard, read every option, cancel), review every option of every question.
4. **Labs are expensive.** The SAP DNS lab took ~2 days and put the plan behind. Labs here are **timeboxed** (≤ 2 h, written as a README + template + teardown) and stop 7 days before the exam.
5. **Concepts first, then questions**, per domain (D0-00 concept map, then section sets).
6. **Sit full exams in one uninterrupted sitting** at the booked time of day. A split sitting leaves stamina untested.
7. **Answer keys can be outdated** (SAP official practice exam had pre-2023 answers). GenAI services change monthly, so log "exam-era" facts separately and check against current docs.
8. Build a **distilled review sheet** (45–60 min read) for the last 2 days.

### 4b. Pacing rules (same format as SAP: 75 Q / 180 min ≈ 2.4 min/Q)
- Checkpoints: **Q25 by 0:55 · Q50 by 1:50 · Q75 by 2:40** (~20 min left for flagged questions).
- **3-minute cap** per question on the first pass: best guess, flag, move on. **Never leave a blank.**
- Topic sets timed at **2 min/question**.
- Multiple-response: count the required answers first, then judge each option on its own (true/false), not as a set.

### 4c. Rules for every full exam
- Same time of day as the booked slot, no phone, no notes, no pausing; full 75 Q in 180 min.
- One pass, flag doubts, return. Note when the first pass ends.
- Review **every** question and every option: why the right one wins, why each wrong one loses (~2–3 h per review).
- New feature facts → `10_feature-facts_claude.md`; reasoning mistakes → Weak-Topics Log; unmatched question shapes → playbook §6.
- **Reading method:** (1) last sentence first: the ask and the constraint word; (2) jot hard requirements (latency, data residency, PII, "no code changes", budget, which model/Region); (3) compare options by what's *different*; (4) remove options breaking a hard requirement, then pick on the constraint word.
- Readiness signal: **≥ 75–80% on two consecutive fresh exams.**

### 4d. Burnout guards (carried)
- 50-min blocks / 10-min breaks; a real break between morning and afternoon blocks; hard stop ~5 h.
- If a day slips, drop that day's topic set, never a full exam or a review.
- One light day per week; the day before the exam is light only.

## 5. Skip / Skim List (strength-based, to confirm in D0-00)
- **Skim only:** Lambda, SQS/SNS/EventBridge, API Gateway basics, ECS/Fargate, DynamoDB basics, S3/CloudFront, IAM basics, CloudWatch/CloudTrail basics, CodePipeline/CodeBuild/CodeDeploy, Kinesis/MSK.
- **Don't skip even though familiar** (asked at a GenAI angle): API Gateway with **streaming / long-running model calls** and timeouts, Step Functions as an **agent/ReAct orchestrator** with stopping conditions, SQS for **async inference**, DynamoDB for **conversation memory**, OpenSearch as a **vector store**, X-Ray/Logs Insights for **prompt/response tracing**, IAM least privilege for **model access**, VPC endpoints for **Bedrock**.

## 6. Progress Tracker
| Date | Activity | Score / Result | Weak areas found |
|------|----------|----------------|------------------|
| 2026-11-20 | Workspace set up (carried from SAP-C02) | — | — |

### Weak-Topics Log
_(One line per weak area from practice: topic → why I got it wrong → the rule to remember)_

## 7. Open Decisions
- [ ] Target exam date and slot (test center vs online). Same center as SAA/SAP?
- [ ] Primary course
- [ ] Practice-question bank(s) — check which exist for AIP-C01 and their quality
- [ ] AWS Skill Builder subscription (official practice exam)
- [ ] Daily hours available (studying full time again, or alongside work?)
- [ ] Hands-on GenAI experience to record in §1 (drives the skip list)
- [ ] Sandbox AWS account/org for Bedrock labs (model access, budget alarm)
- [ ] Rate every task in D0-00 (✅/❓/❌)

## 8. Agent Collaboration Rules (carried from SAP)
1. **This file is the baseline.** Every agent reads it at the start of a session.
2. **One writer per file at a time.** Mohit coordinates; agents don't edit a file another agent is working on.
3. **Topic files** live in `docs/topics/` as `D<domain>-<NN>_<topic>.md` (see §10). Each one is self-contained and starts with owner, created date, domain/task, status and related links. Cross-cutting files stay in `docs/`. Practice-exam reviews go in `docs/practice-exams/exam-NN-review.md` (copy `_TEMPLATE_exam-review.md`).
4. Agents may append to **§6 Progress Tracker**, **Weak-Topics Log**, and **§9 Change Log**. Any other edit to this file: propose it to Mohit first.
5. Don't duplicate content. Link to another file instead of copying it. SAP-era notes in `reference/from-SAP-C02/` are **read-only**; link to them.
6. Write in plain English; tables for "situation → answer · distractor"; mark sections ▶ (covered in course) and **[beyond course]**.

## 10. Folder Structure & Topic Index
```
README.md
docs/
  00_BASELINE.md                    ← this file (start here)
  05_carryover-from-SAP-C02.md      ← what came over from SAP and which old notes map to which AIP task
  10_feature-facts_claude.md        ← "does it natively do X?" log
  20_pattern-playbook.md            ← MAIN STUDY SPINE: recurring question patterns per domain
  30_throughput-and-scaling.md      ← scaling/throughput patterns (Bedrock + carried compute/data rows)
  topics/                           ← one file per topic, review in isolation (D0-00 = exam-guide map)
  practice-exams/                   ← exam-NN-review.md, followups-parking-lot.md, template
  reference/from-SAP-C02/           ← read-only SAP notes still relevant (IAM, federation, networking, DBs, analytics, CI/CD, observability)
labs/                               ← timeboxed hands-on labs (README + template + teardown); AWSLabTemplate.yaml
tools/                              ← utility scripts (close-org-prep.sh)
```

**Per-topic workflow (carried):**
1. **Before the video:** the agent pre-fills the topic file from the exam-guide skills and AWS docs; items the course is unlikely to cover are marked **[beyond course]**; SAP notes that already cover something are linked, not copied.
2. **Watch** the course section at 1.5–2x.
3. **Read the topic file**, skim [beyond course].
4. **Discuss** in a topic chat. Real-world "how would this work at Vrio" questions are the best input; answers go to the file's Q&A log.
5. **Test** with section-based questions on the topic.
6. **Log** misses → topic file §8, feature facts → `10_feature-facts_claude.md`, new shapes → playbook §6.

**One discussion = one topic.** Start a new chat in this Project per topic and name the file in the first message, e.g. *"Topic D1-03 Vector stores & RAG. Read docs/00_BASELINE.md and docs/topics/D1-03_...md"*. At the end of the chat, the agent appends Q&A to that topic's §7.

**Topic file skeleton:** header (owner · created · domain/task · status · related) → §0 mental model → §1–5 content by task/skill → §6 exam decision cheatsheet (situation → answer · distractor) → common traps → hands-on (console walk-through) → **§7 Q&A log** → **§8 practice-question mistakes**.

| File | Topic | Exam tasks | Status |
|------|-------|-----------|--------|
| `D0-00_exam-guide-concept-map.md` | **All task statements + self-rating. Do first** | all | 🟡 Created |
| `D1-01_solution-design-fm-selection.md` | Solution design, WA GenAI Lens, FM selection, dynamic model switching, resilience (Cross-Region Inference), fine-tuned model deployment/lifecycle (SageMaker, LoRA, Model Registry) | 1.1, 1.2 | ⬜ |
| `D1-02_data-pipelines-for-fms.md` | Data validation (Glue Data Quality, Data Wrangler), multimodal processing, input formatting, Comprehend enrichment | 1.3 | ⬜ |
| `D1-03_vector-stores-rag-retrieval.md` | Knowledge Bases, OpenSearch vector/Neural plugin, Aurora pgvector, metadata, chunking, embeddings (Titan), hybrid search, rerankers, query expansion, sync | 1.4, 1.5 | ⬜ |
| `D1-04_prompt-engineering-management.md` | Prompt Management, Prompt Flows, templates/approval, CoT, structured output, prompt QA/regression | 1.6 | ⬜ |
| `D2-01_agentic-ai-tools-mcp.md` | Bedrock Agents, AgentCore, Strands Agents, Agent Squad, MCP servers (Lambda/ECS), ReAct with Step Functions, stopping conditions, human-in-the-loop | 2.1 | ⬜ |
| `D2-02_model-deployment.md` | On-demand vs provisioned throughput vs SageMaker endpoints, LLM container/GPU concerns, model cascading | 2.2 | ⬜ |
| `D2-03_enterprise-integration-gateway.md` | Legacy/event-driven integration, identity federation & RBAC for models, Outposts/Wavelength, GenAI gateway, CI/CD for GenAI | 2.3 | ⬜ |
| `D2-04_fm-api-app-patterns.md` | Bedrock APIs (Converse, streaming), async via SQS, retries/backoff, routing, API Gateway streaming, Amplify, Bedrock Data Automation, Q Developer | 2.4, 2.5 | ⬜ |
| `D3-01_guardrails-input-output-safety.md` | Bedrock Guardrails, moderation workflows, hallucination controls, prompt injection/jailbreak defense, defense in depth | 3.1 | ⬜ |
| `D3-02_data-security-privacy.md` | VPC endpoints, IAM, Lake Formation, PII with Comprehend/Macie, masking, retention | 3.2 | ⬜ |
| `D3-03_governance-responsible-ai.md` | Model cards, lineage (Glue Data Catalog), audit logging, drift/bias monitoring, transparency, fairness, LLM-as-judge | 3.3, 3.4 | ⬜ |
| `D4-01_cost-performance-optimization.md` | Token efficiency, model tiering, caching (prompt/semantic), batching, provisioned throughput, latency-optimized inference, inference parameters | 4.1, 4.2 | ⬜ |
| `D4-02_genai-monitoring-observability.md` | Invocation logging, CloudWatch token/quality metrics, anomaly detection, tool/agent tracing, vector store ops | 4.3 | ⬜ |
| `D5-01_evaluation-systems.md` | Bedrock Model Evaluations, RAG evaluation, LLM-as-judge, human feedback, agent evaluation, quality gates | 5.1 | ⬜ |
| `D5-02_troubleshooting-genai.md` | Context overflow, API integration errors, prompt and retrieval troubleshooting | 5.2 | ⬜ |

Status: ⬜ not started · 🟡 in progress · ✅ reviewed · 🔁 needs revisit

## 11. Parking Lot (after the exam)
_Curiosity questions that don't affect AIP-C01._ See also `practice-exams/followups-parking-lot.md` (exam-relevant follow-ups).

## 9. Change Log
- 2026-11-20 — Claude — Created workspace from the SAP-C02 format: baseline, carry-over map, feature facts, pattern playbook, throughput/scaling, D0-00 exam-guide map, exam-review template, parking lot, labs README; copied relevant SAP notes to `reference/from-SAP-C02/`.
