# Throughput & Scaling Recommendations (AWS-preferred patterns)

> **Owner:** Claude · **Created:** 2026-11-20 (format carried from SAP-C02 `30_scaling-recommendations.md`). Append as new ones come up.
> Format: **situation → AWS-preferred answer** · *distractor it beats*

## 1. FM inference throughput (seeds from exam guide tasks 2.2, 4.1, 4.2; confirm against docs/practice)
| Situation | Preferred | Beats |
|---|---|---|
| Unpredictable or low volume | Bedrock **on-demand** inference | Provisioned capacity sitting idle |
| Steady high volume, guaranteed capacity | Bedrock **provisioned throughput** | On-demand hitting throttles |
| Model has limited Regional availability / burst capacity | **Cross-Region Inference** | Building your own multi-Region routing |
| Large offline job (summarise a backlog) | **Batch inference** | Looping synchronous calls |
| Custom model, GPU/memory-bound | **SageMaker AI endpoint** with auto scaling | Bedrock on-demand (not available for that model) |
| Throttling errors | SDK **exponential backoff**, SQS buffer, fallback model | Immediate retry loops |
| Repeated prompts / prefixes | **Prompt caching**, semantic cache | Paying for the same tokens again |

## 2. Carried from SAP-C02 (still valid)
Full file: `reference/from-SAP-C02/SAP_30_scaling-recommendations.md`.
| Service | Preferred pattern |
|---|---|
| **Lambda** | **Reserved concurrency** = guaranteed amount + cap (stops one function starving others). **Provisioned concurrency** = no cold starts (paid), auto scalable via Application Auto Scaling |
| **DynamoDB** | Unpredictable → **on-demand**. Predictable → **provisioned + auto scaling**. Hot keys read repeatedly → **DAX** |
| **Aurora** | Read-replica auto scaling; highly variable load → **Aurora Serverless v2** |
| **ECS** | Service Auto Scaling (target tracking on CPU, memory or ALB requests) |
| **Kinesis Data Streams** | Unpredictable throughput → **on-demand capacity mode** |
| **Spiky writes / calls to a limited backend** | **Buffer with SQS** (load leveling); workers drain at a steady rate |
| **SQS workers** | Scale on **backlog per instance** (custom metric + target tracking), not raw queue depth |

## Exam reading rules (carried)
- "**Unpredictable**" → dynamic / on-demand; "**recurring**" → predictive; "**known date/time**" → scheduled.
- "**MOST scalable**" → the option that scales **in proportion**, not the one that merely works.
