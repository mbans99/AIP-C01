# D1-04 · Multi-account networking: VPC design, TGW, RAM/VPC sharing, PrivateLink, centralized egress & inspection

> **Owner:** Claude · **Created:** 2026-10-31 · **Exam domains:** 1 (also 2 and 3 for cost)
> **Status:** 🟡 Pre-filled, discussion pending
> Related: [[D1-05 Hybrid connectivity]] · [[D2-01 Edge & DNS]] (hybrid DNS, PHZ sharing) · playbook patterns 1.8, 1.9, 1.10, 1.16, 3.8
> Mohit is strong on basic VPC, SG/NACL and TGW. This file focuses on the **SAP angle**: scale, multiple accounts, cost and the traps. **[beyond course]** = probably not covered in Neal's videos.

---

## 1. VPC/subnet facts at SAP depth (quick refresher)
- VPC IPv4 CIDR **/16 to /28**. You can add **secondary CIDRs** later (fix for running out of IPs; also 100.64.0.0/10 for EKS pod IPs). The primary CIDR can't be changed.
- **5 IPs reserved per subnet:** network, +1 router, **+2 DNS**, +3 future, broadcast. A /28 gives 11 usable.
- A subnet lives in **one AZ**. "Public" just means its route table has 0.0.0.0/0 → IGW.
- IPv6: VPC gets a /56, subnets get /64. All IPv6 is globally routable; for outbound-only use an **egress-only internet gateway** (NAT doesn't apply to IPv6, except NAT64 with DNS64 for IPv6-only → IPv4).
- **NAT gateway** is per AZ. For HA, one per AZ with per-AZ route tables. Cross-AZ use works but costs cross-AZ data transfer and fails if that AZ goes down.
- **Amazon VPC IPAM [beyond course]:** plan, allocate and audit CIDRs across the Organization; pools per Region/OU; detects overlaps. The answer to *"prevent overlapping CIDRs across hundreds of accounts"*.
- **Overlapping CIDRs break peering and TGW routing.** Only PrivateLink (or NAT tricks such as private NAT gateway) gets around them.

## 2. Connecting VPCs: the four options
| | **VPC peering** | **Transit Gateway (TGW)** | **PrivateLink** | **Cloud WAN [beyond course]** |
|---|---|---|---|---|
| Shape | 1:1, **not transitive** | Hub and spoke, **transitive** | Consumer → one service (one direction) | Global network managed by policy |
| Overlapping CIDRs | ❌ | ❌ (routing) | ✅ | ❌ |
| Cross-Region | ✅ | ✅ via **TGW peering** (static routes) | ✅ (cross-Region endpoints, newer) | ✅ native |
| Cross-account | ✅ | ✅ share TGW via **RAM** | ✅ allow principals on endpoint service | ✅ |
| Cost | No hourly fee, only data transfer (same AZ free) | **Per attachment-hour + per GB processed** | Per endpoint-hour per AZ + per GB | Core network + attachments |
| Scale | Mesh: n(n-1)/2 links; each VPC has a peering limit | Thousands of attachments | Many consumers per service | Multi-Region at large scale |
| Typical exam use | 2–3 VPCs, **cheapest for heavy traffic** between few VPCs | **Many VPCs + on-prem**, segmentation | SaaS / shared service, **overlap**, expose only one port | Global WAN, segments by policy across Regions |

**Peering gotchas:** no edge-to-edge routing (VPC A can't use VPC B's IGW, NAT, VPN, DX or gateway endpoint). You can reference a peer's **security group** (same Region). Longest-prefix match handles partial routes.

## 3. Transit Gateway in depth
- **Regional** resource. Attachments: **VPC, S2S VPN, DX gateway (via transit VIF), Connect (GRE + BGP for SD-WAN appliances), TGW peering** (inter-Region, **static routes only**), Network Firewall (native attachment).
- **Route tables:** each attachment is **associated** with exactly one TGW route table (where its traffic is looked up) and can **propagate** its routes into one or more tables. This is how you segment: e.g. *Prod* table, *Dev* table, *Shared* table. Prod and Dev don't see each other, both see Shared.
- **Blackhole routes** drop traffic for a CIDR on purpose.
- **ECMP over VPN:** TGW can spread traffic over multiple VPN tunnels (BGP needed) to go beyond 1.25 Gbps per tunnel. **VGW can't.** → see D1-05.
- **Appliance mode** on the inspection-VPC attachment keeps both directions of a flow on the **same AZ/appliance** (symmetric routing). Missing this is the classic "stateful firewall drops return traffic" bug.
- **Multicast** is supported (relevant for broadcast/media workloads, like video distribution).
- **Sharing:** TGW owner shares it via **RAM**; spoke accounts create attachments (auto-accept can be enabled).
- **Cost trap:** TGW charges per GB. For two VPCs with heavy traffic, **peering is cheaper**. A hybrid of both (TGW for most traffic, peering for a high-volume pair) is valid.

## 4. VPC sharing (RAM)
- One **owner** account (usually a central network account) owns the VPC and subnets and **shares subnets** with participant accounts **in the same Organization**, same Region.
- Participants launch their own resources (EC2, RDS, Lambda, ALB) into shared subnets. They **can't see or change** other accounts' resources or the VPC itself (routes, NACLs, IGW stay with the owner).
- Participants own their own security groups; they can reference other SGs in the shared VPC.
- **Why the exam likes it:** teams keep account-level isolation for billing and IAM, but don't run networking. Fewer VPCs means **fewer TGW attachments, less IP space used, less NAT cost**.
- Enable *sharing with AWS Organizations* in RAM first; then no invite acceptance is needed.
- Contrast: **TGW sharing** = each team has its own VPC connected through a hub. **VPC sharing** = teams share one VPC. *"Least operational overhead, app teams shouldn't manage networking"* → VPC sharing.

## 5. Centralized patterns (hub-and-spoke)
### 5.1 Centralized egress
- **Egress VPC** with NAT gateways (per AZ) + IGW. Spoke VPCs have **no IGW/NAT**. Spoke route 0.0.0.0/0 → TGW; TGW route table 0.0.0.0/0 → egress VPC attachment.
- Saves NAT hourly costs at scale, gives one place to control egress. Trade-off: TGW per-GB processing adds cost; NAT itself does **no** filtering.
- Add a blackhole route in TGW so spokes can't talk to each other through the egress VPC, if needed.

### 5.2 Centralized inspection
- **AWS Network Firewall:** managed, stateful + stateless, Suricata-compatible rules, **domain allow/deny lists (FQDN filtering)**, TLS inspection. Deployed as firewall endpoints in a firewall subnet (or as a native TGW attachment).
- **Gateway Load Balancer (GWLB):** for **third-party appliances** (Palo Alto, Fortinet, etc.). Uses **GENEVE on port 6081**, transparent bump in the wire, scales and health-checks the appliance fleet. Traffic enters through **GWLB endpoints** in the route table path. *"Existing third-party firewall vendor"* → GWLB.
- Inspection VPC on TGW: spokes → TGW → inspection VPC (**appliance mode on**) → back to TGW → destination / egress.
- **Distributed** model (firewall endpoint in every VPC) = more isolation, more cost and more to manage. **Centralized** = less overhead. Pick based on the constraint word.

### 5.3 Centralized interface endpoints [beyond course, common in SAP]
- Put **interface endpoints** (e.g. for SSM, ECR, STS, KMS) in a shared-services VPC once, instead of in every VPC.
- Turn off *private DNS* on the endpoint, create a **private hosted zone** for the service name (e.g. `ssm.us-east-1.amazonaws.com`) with an alias to the endpoint, and **associate the PHZ with all spoke VPCs** (or use Route 53 Profiles). Traffic flows over TGW.
- ⚠️ **Gateway endpoints (S3, DynamoDB) can't be used from another VPC, peering, TGW, VPN or DX.** They only work for the VPC whose route table has them. For on-prem or cross-VPC S3 access → **S3 interface endpoint**.
- Endpoint policies + bucket policy `aws:SourceVpce` / `aws:SourceVpc` lock access down (see D1-02).

### 5.4 Centralized ingress
- Public ALB/NLB in an ingress VPC (often with Network Firewall / WAF) forwarding to targets in spokes (IP targets over TGW), or keep ingress distributed per app. CloudFront + WAF in front is the common "best" answer for web.

## 6. Governance and troubleshooting tools
- **AWS Firewall Manager:** applies **SG policies, Network Firewall, WAF, Shield Advanced, Route 53 DNS Firewall** across all accounts in the Org, including new accounts. *"Enforce across the Organization automatically"* → Firewall Manager.
- **VPC Reachability Analyzer:** "why can't A reach B?" (static config analysis, no packets sent).
- **Network Access Analyzer [beyond course]:** find unintended access paths (e.g. "nothing in prod should be reachable from the internet").
- **VPC Flow Logs:** to CloudWatch Logs / S3 / Firehose; also at TGW level (**TGW Flow Logs**). Metadata only, not packet contents → **Traffic Mirroring** for packet capture (Nitro instances).
- **Prefix lists:** managed sets of CIDRs used in SGs and route tables; share via RAM.

## 7. Exam decision cheatsheet
| Scenario phrase | Answer |
|---|---|
| 100s of VPCs across accounts, transitive, on-prem too | **TGW** shared via RAM + DX gateway/VPN attachments |
| Isolate prod from dev, both reach shared services | **TGW route tables** (separate association/propagation) |
| Two VPCs, very heavy traffic, lowest cost | **VPC peering** |
| Expose one service to many consumers, **overlapping CIDRs** | **PrivateLink** (NLB → endpoint service) |
| App teams shouldn't manage networking, keep separate accounts | **VPC sharing via RAM** |
| Cut NAT gateway cost across many VPCs | **Centralized egress VPC** over TGW |
| Inspect all east-west and egress traffic, managed | **Network Firewall** in inspection VPC, **appliance mode** |
| Must use existing third-party firewall appliances | **GWLB** + GWLB endpoints |
| Firewall drops return traffic after adding inspection VPC | Enable **TGW appliance mode** |
| Filter outbound traffic by **domain name** | Network Firewall (stateful domain list) / DNS Firewall for DNS |
| Many VPCs need SSM/ECR endpoints, least cost | **Centralized interface endpoints** + PHZ shared to spokes |
| On-prem or other VPC must reach S3 privately | **S3 interface endpoint** (gateway endpoint won't work) |
| Prevent overlapping CIDRs across the Org | **VPC IPAM** |
| Enforce SG / firewall rules on every account incl. new ones | **Firewall Manager** |
| VPN throughput above 1.25 Gbps | **TGW + multiple tunnels with ECMP** (BGP) |

## 8. Practice misses
_(Q source · what I picked · what was right · rule)_

## 9. Q&A log
