# Scaling Recommendations (AWS-preferred patterns)

> **Owner:** Claude · **Created:** 2026-11-15 · Started from the SQS backlog-per-instance question (official practice exam). Append as new ones come up.
> Format: **situation → AWS-preferred answer** · *distractor it beats*

## EC2 Auto Scaling: policy types
| Situation | Preferred | Beats |
|---|---|---|
| Default dynamic scaling ("keep CPU at 50%") | **Target tracking** | Step/simple (more tuning) |
| Large, fast swings (2–10× in minutes); several changes in a row | **Step scaling** (adds capacity in proportion to the breach, no cooldown wait) | **Simple scaling** (one change, then waits out the cooldown, about 300 s by default; legacy) |
| Recurring daily/weekly pattern | **Predictive scaling** (learns from history, scales *ahead* of demand); combine with target tracking | Reacting only after the spike |
| Known one-off event (sale starts at 9 AM) | **Scheduled scaling** | Waiting for metrics |
| Instances take a long time to boot | **Warm pools** (pre-initialized, stopped instances) | Over-provisioning all the time |

## Choosing the scaling metric
| Workload | Metric |
|---|---|
| Compute-heavy or uneven requests | **CPUUtilization** |
| Uniform web requests behind an ALB | **ALBRequestCountPerTarget** |
| **SQS queue workers** | **Backlog per instance** = ApproximateNumberOfMessagesVisible ÷ running instances, as a **custom metric + target tracking**. Target = acceptable latency ÷ processing time per message. *Beats raw queue depth (ignores fleet size) and CPU (wrong signal)* |

## Making scaling behave well
- **ELB health check type** on the Auto Scaling group behind a load balancer, so instances failing *application* health checks get replaced (EC2 checks alone only catch host or OS failures).
- **Instance warmup** (default instance warmup), so brand-new instances don't distort the metrics.
- **Lifecycle hooks** to bootstrap before an instance goes in service, or to drain and save state before termination.
- **Scale-in protection** for instances busy with long jobs.
- **Mixed instances policy**: several instance types plus Spot with the **price-capacity-optimized** allocation strategy, and **Capacity Rebalancing** turned on.

## Other services
| Service | Preferred pattern |
|---|---|
| **Lambda** | **Reserved concurrency** = guaranteed amount + cap (stops one function from starving others; free). **Provisioned concurrency** = warm environments, no cold starts (paid); can be auto scaled (scheduled or target tracking) through Application Auto Scaling |
| **DynamoDB** | Unpredictable or new traffic → **on-demand**. Predictable → **provisioned + auto scaling** (min / max / target utilization; auto scaling **does not apply to on-demand**). Hot keys read repeatedly → **DAX** |
| **Aurora** | **Aurora Auto Scaling** of read replicas (target tracking on CPU or connections). Highly variable load → **Aurora Serverless v2** |
| **ECS** | **Service Auto Scaling** (target tracking on CPU, memory or ALB requests). EC2 launch type → **capacity providers with managed scaling** so the cluster grows with the tasks |
| **Kinesis Data Streams** | Unpredictable throughput → **on-demand capacity mode** |
| **Spiky writes to a database** | **Buffer with SQS** (load leveling); workers drain the queue at a steady rate |
| **Sudden surge on a web app** | ASG + **SQS** + DynamoDB; static content to **CloudFront / S3** to take load off EC2 |

## Exam reading rules
- Timing words pick the policy type: "**unexpected / unpredictable**" peaks → **dynamic** (target tracking); "**recurring**, daily/weekly pattern" → **predictive**; "**known date or time**" → **scheduled**.
- If the stem says **EC2 metrics don't follow the load** → scale on the **ALB `RequestCountPerTarget`** metric (a load balancer metric, not an EC2 one). *From official practice exam, ecommerce peak-sales question.*
- "**Periodic** / spiky" load → horizontal (Auto Scaling). Vertical scaling only if the stem states a **single-instance limit**.
- "**MOST scalable**" → the option that scales **in proportion** (target tracking on a per-instance metric), not the one that merely works.
