# D3-01 · Deployment & Management (CloudFormation/StackSets, Service Catalog, SSM, CI/CD)

> **Owner:** Claude · **Created:** 2026-11-04 · **Domains:** 1 (task 1.4 multi-account) and 3
> **Status:** 🟡 §1–2 written 2026-11-04; §3–6 (Service Catalog, SSM, CI/CD, deployment strategies) pre-filled 2026-11-04 night, discussion pending
> Related: [[D1-01 Organizations & Control Tower]] · playbook 3.5, 1.1

## 1. CloudFormation StackSets
**What:** one template + parameters, deployed as **stack instances** to many **accounts × Regions** from a single **administrator** account. Update the StackSet once, and every instance updates.

### 1.1 Two permission models (most-tested point)
| | **Self-managed** | **Service-managed** |
|---|---|---|
| Needs Organizations? | No | **Yes** (trusted access enabled) |
| IAM roles | **You** create `AWSCloudFormationStackSetAdministrationRole` (admin acct) + `AWSCloudFormationStackSetExecutionRole` (every target acct) | Created/managed **for you** |
| Targets | List of **account IDs** | **OUs** (or the org root) |
| New accounts | Manual: add them | ✅ **Automatic deployment**: accounts joining a target OU get the stack automatically. Leaving accounts: stacks deleted or retained (your choice) |
| Run from | Any account | Management account or a **delegated administrator** member account (up to 5) |

- Service-managed StackSets **do not deploy to the management account itself**, even if you target the root.

### 1.2 Deployment controls
- **Max concurrent accounts** (count or %) and **failure tolerance** (count or %) per Region.
- **Region order** + Region concurrency: sequential or parallel.
- **Parameter overrides** per account/Region.
- **Drift detection** across all stack instances.

### 1.3 Typical uses
Baseline in every account: IAM roles (e.g. security audit role), AWS Config rules, CloudTrail, GuardDuty enablement, VPC/networking templates. Control Tower uses StackSets underneath.

### 1.4 Exam cheatsheet
| Scenario | Answer |
|---|---|
| Deploy resources to **all existing and future accounts** in an OU, **least overhead** | **Service-managed StackSet** targeting the OU with **automatic deployment** |
| Same, but **without** using the management account | Register a **delegated administrator** for StackSets |
| Accounts **not** in Organizations / external accounts | **Self-managed** StackSet (create the admin + execution roles) |
| Roll out carefully, stop if it breaks | Max concurrency + failure tolerance, sequential Regions |
| Org-wide **Config rules** specifically | Also: Config **organization rules / conformance packs** |
| Org-wide **security groups / WAF / Shield / Network Firewall** policy | **Firewall Manager** (more specific than StackSets) |
| Control Tower environment, customize every new account | **CfCT** / Account Factory Customization (built on StackSets) |

## 2. CloudFormation core (SAP-level)
| Concept | What it's for · exam cue |
|---|---|
| **Nested stacks** | Reuse a template *inside* a parent stack (e.g. a standard ALB module); updated with the parent |
| **Cross-stack references** (`Outputs` + `Export` → `Fn::ImportValue`) | Share values between *independent* stacks (network stack exports VPC/subnet IDs; app stacks import them). An exported value **can't be changed or deleted while imported** |
| **Change sets** | Preview exactly what an update will create/modify/**replace** before executing. Cue: "review the impact before applying" |
| **Stack policy** | JSON that blocks updates to critical resources (e.g. deny `Update:Replace` on the production DB) |
| **DeletionPolicy** `Retain` / `Snapshot` (+ `UpdateReplacePolicy`) | Keep data (S3 bucket, RDS snapshot) when the stack or resource is deleted/replaced. Cue: "must not lose data if the stack is deleted" |
| **Termination protection** | Prevents the whole stack being deleted |
| **Drift detection** · **resource import** | Find manual changes outside CloudFormation · bring existing resources under a stack |
| **Custom resources** (Lambda-backed) | Do something CloudFormation can't natively (call an API, look up an AMI, seed data) |
| **cfn-init / cfn-signal + CreationPolicy / WaitCondition** | Bootstrap instances and only mark them CREATE_COMPLETE after the app is really up |
| **UpdatePolicy** on Auto Scaling groups | `AutoScalingRollingUpdate` vs `AutoScalingReplacingUpdate` for safe AMI/launch template rollouts |
| **Service role** | CloudFormation acts with a role; users only need `cloudformation:*` + `iam:PassRole`. Basis of Service Catalog **launch constraints** |
| **Dynamic references** | `{{resolve:ssm:...}}`, `{{resolve:secretsmanager:...}}`: no secrets in templates |
| **Hooks / CloudFormation Guard** | Validate resources *before* provisioning (Control Tower proactive controls use Hooks) |
| **Macros / transforms, CDK, SAM** | SAM = serverless transform; CDK synthesizes CloudFormation |

## 3. AWS Service Catalog
**What:** an admin-curated catalog of **approved CloudFormation (or Terraform) templates**. End users launch "products" without needing permissions on the underlying services.

| Concept | Meaning |
|---|---|
| **Product** | A versioned template (CloudFormation, or Terraform via the Terraform engine) |
| **Portfolio** | A group of products + who may use them (IAM users/groups/roles, or Identity Center groups) |
| **Launch constraint** ⭐ | An **IAM role Service Catalog assumes** to provision the product. The user needs only Service Catalog permissions, **not** EC2/RDS/IAM rights. Most-tested point |
| **Template constraint** | Limits parameter values (e.g. only `t3.small`/`t3.medium`, only certain VPCs) |
| **Notification constraint** | Stack events go to SNS |
| **StackSet constraint** | Launch the product into multiple accounts/Regions via StackSets |
| **TagOptions** | Enforced/offered tags on provisioned products (cost allocation) |
| **Sharing** | Share a portfolio with other accounts, or **with an OU / the whole org** (from management or delegated admin). Recipients import it, can add their own launch constraints/users |
| **Updates** | New product version → users update their provisioned product |

**Exam cues**
| Scenario | Answer |
|---|---|
| Developers must self-serve approved, compliant resources, **without broad IAM permissions** | Service Catalog + **launch constraint** |
| Restrict which instance types/sizes users can pick | **Template constraint** |
| Same approved catalog in every account of the org | Share portfolio with the **org/OU** |
| Control Tower Account Factory | Is itself a Service Catalog product |
| Deploy the *same baseline* automatically everywhere (no user choice) | StackSets (§1), not Service Catalog |

## 4. AWS Systems Manager (SSM)
**Root concept:** an **agent on the machine** (EC2, on-prem server, edge device) + an **IAM role** + a path to the SSM endpoints = a **managed node**. Every SSM capability below is then just "send something to managed nodes".

### 4.1 Making a node managed (prerequisites, often tested)
1. **SSM Agent** (preinstalled on Amazon Linux, Windows Server, Ubuntu AMIs).
2. **IAM**: instance profile with `AmazonSSMManagedInstanceCore`, **or** **Default Host Management Configuration** (account setting, no instance profile needed).
3. **Network to the SSM endpoints**: internet/NAT, **or** in a private subnet with no internet, **interface VPC endpoints** `ssm`, `ssmmessages` (+ `ec2messages`). Cue: "private subnet, no NAT, Session Manager fails" → add the endpoints.
4. **On-prem / other clouds**: **hybrid activation** (activation code + ID) → node shows as `mi-…`, uses an IAM service role.

### 4.2 Capabilities (grouped by job)
| Job | Capability | Key facts · exam cue |
|---|---|---|
| **Access** | **Session Manager** | Shell/RDP **without SSH keys, open port 22, or bastion host**; IAM-controlled; session logs to **S3 / CloudWatch Logs**; port forwarding. Cue: "remove bastion hosts", "audit all shell commands" |
| **Run something now** | **Run Command** | Run a document (script) on many nodes by tag/resource group; rate control + error threshold; output to S3 |
| **Run on a schedule** | **Maintenance Windows** | Time slots for Run Command / Automation / patching |
| **Keep desired state** | **State Manager** | **Associations** re-apply a configuration on a schedule (e.g. agent installed, setting enforced). Drift correction for OS config |
| **Patching** | **Patch Manager** | **Patch baselines** (auto-approve rules, e.g. critical after 7 days) + **patch groups** (tag `Patch Group`) + maintenance window; or **patch policies via Quick Setup** across **accounts/Regions in the org**. Compliance reporting |
| **Runbooks** | **Automation** | Multi-step workflows calling AWS APIs (e.g. `AWS-UpdateLinuxAmi` → **golden AMI pipeline**, restart/resize instances). **Remediation action for AWS Config rules**. Runs **multi-account / multi-Region**. Approval steps possible |
| **Know what's installed** | **Inventory** | Software, patches, files, roles on nodes. **Resource Data Sync** → central S3 bucket (multi-account) → Athena/QuickSight |
| **Compliance view** | **Compliance** | Patch + State Manager association compliance; feeds Security Hub / Config |
| **Config & secrets** | **Parameter Store** | Hierarchical (`/prod/app/db-url`), versioned, `SecureString` via KMS; **Standard** (free, 4 KB) vs **Advanced** (8 KB, **parameter policies** such as expiration/TTL). **No native rotation** → use Secrets Manager for rotation |
| **Ops issues** | **OpsCenter** (OpsItems), **Explorer**, **Incident Manager**, **Change Manager** | Central ops dashboards, incident response plans/on-call, change approval workflows |
| **Install packages** | **Distributor** | Publish/install software packages (e.g. a security agent) to nodes |
| **Feature flags / runtime config** | **AppConfig** | Validated config/feature-flag rollouts with deployment strategy + **automatic rollback on CloudWatch alarm** |
| **Setup** | **Quick Setup**, Fleet Manager | One-click org-wide setup (e.g. Host Management, patch policies); GUI to manage nodes |

### 4.3 Exam cues
| Scenario | Answer |
|---|---|
| Patch 1,000 EC2 + on-prem servers on a schedule, report compliance | Patch Manager (baselines + patch groups/patch policy) + maintenance window; hybrid activation for on-prem |
| Remove SSH/bastion, keep an audit trail | Session Manager + logging to S3/CloudWatch |
| Auto-fix non-compliant resources found by Config | Config rule + **SSM Automation remediation** |
| Build hardened AMIs regularly | SSM Automation (`AWS-UpdateLinuxAmi`) or **EC2 Image Builder** (newer, managed pipelines) |
| Central view of installed software across accounts | Inventory + Resource Data Sync to one S3 bucket |
| Store config values / non-rotating secrets, cheap | Parameter Store; rotating DB creds → Secrets Manager |

## 5. CI/CD: CodePipeline, CodeBuild, CodeDeploy (and friends)
**Root concept:** **CodePipeline orchestrates**, it does no work itself. Each stage calls an action provider: **source** (CodeCommit, GitHub/GitLab/Bitbucket via CodeConnections, S3, ECR) → **build/test** (**CodeBuild**) → **deploy** (**CodeDeploy**, CloudFormation, ECS, Elastic Beanstalk, S3, Service Catalog…). Artifacts pass between stages through an **S3 artifact bucket**.

### 5.1 CodePipeline
- Stages → actions (sequential or parallel). **Manual approval** action (notify via SNS).
- Triggered by source change (EventBridge / webhooks); V2 pipelines add triggers on git tags/branches/file paths and pipeline variables.
- **Cross-Region:** an artifact bucket per Region the pipeline acts in.
- **Cross-account deploy** ⭐: artifact bucket encrypted with a **customer managed KMS key** (the default AWS managed key can't be shared) + key policy and bucket policy allowing the target account + a **role in the target account** that the pipeline assumes for the deploy action.

### 5.2 CodeBuild
- Fully managed build containers, pay per build minute, no build servers to run (vs Jenkins on EC2).
- **`buildspec.yml`** phases: `install` → `pre_build` → `build` → `post_build`; `artifacts`, `reports` (test reports), `cache` (S3 or local).
- Env vars from **Parameter Store / Secrets Manager** (no secrets in buildspec).
- Run **inside a VPC** to reach private resources (RDS, internal repos) during tests.
- Logs to CloudWatch Logs / S3.

### 5.3 CodeDeploy ⭐ (the most-tested of the three)
Deploys an app revision to a **compute platform** following an **`appspec.yml`** and a **deployment configuration**.

| Platform | Types | Deployment configs | Notes |
|---|---|---|---|
| **EC2 / on-prem** | **In-place** (EC2 and on-prem) or **blue/green** (EC2 with Auto Scaling/ELB only, **not on-prem**) | `AllAtOnce`, `HalfAtATime`, `OneAtATime`, custom *minimum healthy hosts* | Needs the **CodeDeploy agent**. Lifecycle hooks: ApplicationStop → BeforeInstall → AfterInstall → ApplicationStart → **ValidateService** |
| **Lambda** | Traffic shifting between **alias** versions | **Canary** (e.g. `Canary10Percent5Minutes`), **Linear** (`Linear10PercentEvery1Minute`), AllAtOnce | Hooks `BeforeAllowTraffic` / `AfterAllowTraffic` (Lambda validation functions). SAM uses this (`DeploymentPreference`) |
| **ECS** | **Blue/green**: new task set behind a second ALB/NLB target group, optional **test listener** | Canary / Linear / AllAtOnce | Hooks incl. `AfterAllowTestTraffic` |

- **Automatic rollback** on deployment failure or when a **CloudWatch alarm** fires. Rollback = redeploy the last good revision.
- Deployment groups target EC2 by **tags** or **Auto Scaling groups**.
- [beyond exam guide] Since 2025, **ECS has native blue/green, linear and canary** deployments without CodeDeploy. The exam (written 2022) still expects CodeDeploy.

### 5.4 Other names you may see
| Service | One line |
|---|---|
| **CodeCommit** | Managed Git. Closed to new customers in 2024, AWS reversed that in late 2025; exam questions still use it as a source |
| **CodeArtifact** | Managed package repository (npm, Maven, PyPI) with upstream proxying |
| **CodeGuru** | Reviewer (code review) / Profiler (runtime performance) |
| **EC2 Image Builder** | Managed pipelines for golden AMIs / container images, share across accounts/Regions |
| **CDK / SAM** | Both produce CloudFormation. SAM = serverless shorthand + local testing + CodeDeploy traffic shifting for Lambda |
| **OpsWorks** | Chef/Puppet managed. **Retired (2024)**: if it appears, it's legacy |
| **CodeStar** | Discontinued 2024 |

## 6. Deployment strategies across services (comparison)
| Strategy | Downtime | Rollback speed | Cost | Where on AWS |
|---|---|---|---|---|
| All at once / in-place | Yes | Slow (redeploy) | Lowest | CodeDeploy in-place AllAtOnce, Beanstalk *All at once* |
| Rolling | No (reduced capacity) | Slow | Low | CodeDeploy OneAtATime/HalfAtATime, Beanstalk *Rolling*, ASG rolling update |
| Rolling with extra batch | No, full capacity | Slow | Low+ | Beanstalk *Rolling with additional batch* |
| Immutable | No | Fast (terminate new) | Double briefly | Beanstalk *Immutable*, ASG `AutoScalingReplacingUpdate` |
| Blue/green | No | **Fastest** (switch back) | Double while both run | CodeDeploy blue/green (EC2/ECS), Beanstalk **swap environment URLs (CNAME)**, Route 53 weighted records |
| Canary / linear | No | Fast | Low | CodeDeploy Lambda/ECS, Beanstalk *Traffic splitting*, API Gateway canary stage, Route 53 weighted |

## 7. Q&A log
**2026-11-04 · Didn't know StackSets could target the whole Organization.** → §1. Key: service-managed + OU targets + automatic deployment.

### Session 2026-11-04 night (voice): CodeDeploy, CloudFormation, Service Catalog, SSM

**CodeDeploy**
- **Why is ECS (even on EC2) blue/green only?** CodeDeploy's ECS platform deploys *tasks*, not instances. Containers are immutable, so a new task set is started. The dividing line is mutable vs immutable target, not serverless vs servers. ECS's own rolling update (without CodeDeploy) still replaces tasks.
- **EC2 blue/green, how?** CodeDeploy copies the **Auto Scaling group** (same launch template, so the agent must be in the AMI/user data), installs the code via the agent, registers the new instances in the target group, deregisters the old ones, and terminates the old group after a wait (default 1 h). The new group is production from then on. Alternative: instances you launch yourself, found by tag; CodeDeploy can still terminate the old blue ones automatically.
- **Do the original instances need to be created by CodeDeploy?** No. Needs: agent + instance role, deployment group finding them (ASG or tags), load balancer for blue/green.
- **In-place, how?** Same instances. One-at-a-time: take VM out of target group → appspec scripts (stop, copy files, start, validate) → put back → next. **No downtime behind an LB** (reduced capacity, slow rollback); downtime only with all-at-once or no LB. Blue/green's double cost is temporary.
- **The switch** = registering/deregistering targets in the target group (EC2), or changing which target group the listener forwards to (ECS). Deregistration delay (connection draining) 300 s default.
- **ECS task sets** are a real ECS object (visible via describe-services / deployment details), only with an external deployment controller (CodeDeploy or third party).
- **Canary/linear** = CodeDeploy *deployment configuration* (on the deployment group, overridable per deployment), done via weighted ALB target groups (ECS) or alias weights (Lambda). Canary = two steps; linear = equal steps on a timer. **NLB: all-at-once only. EC2: no canary/linear.**
- **What decides the EC2 server config?** Not the appspec (files + scripts only). It's the ASG's launch template. For ECS the appspec names the task definition.
- **Neal's lab with two target groups** was the Fargate/ECS pipeline, not EC2.
- **Can CodeDeploy run CloudFormation?** No. **CodePipeline orchestrates, CloudFormation builds infrastructure, CodeDeploy deploys code.** CloudFormation has native support for ECS blue/green via CodeDeploy.

**CloudFormation**
- ⚠️ **Gotcha: EC2 blue/green with a CloudFormation-owned ASG → stack drift**; new ASG orphaned on stack delete. Fixes: in-place deployment, `AutoScalingReplacingUpdate`, or **alternating stacks** (pipeline creates green stack, CodeDeploy *keeps* originals, pipeline deletes old stack).
- **CloudFormation is regional**; StackSets create a stack instance per account × Region.
- **Self-managed vs service-managed StackSets** = who creates the roles. Self-managed works from any account to any account (even outside the org). Service-managed: trusted access, management or delegated admin account, OU targets, auto-deploy to new accounts, one org only, never the management account. Use case: audit role / Config / alarms in every existing and future account (Control Tower uses it).
- Denying actions / enforcing tags → **SCPs / tag policies**, not StackSets.
- **Nested stacks vs cross-stack references**: lifecycle. Reusable block that lives/dies with the parent (or resource-limit split) → nested. Shared foundation with its own owner → Outputs `Export` + `Fn::ImportValue`. **Same account and Region only; OUs make no difference.** Export can't be changed/deleted while imported. Cross-account/Region → Parameter Store or StackSet parameters.
- **Latest AMI without editing the template** → parameter of type `AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>` pointing at the public AL2023 path.
- **CloudFormation service role**: you create it; without one the user's own permissions are used; with one, the role's. Guard with **`iam:PassRole`**. The stack keeps using that role for later updates/deletes.

**Service Catalog**
- **Product** = an approved template (not an AWS service). **Portfolio** = products + who may launch + where constraints attach; unit of access and sharing. Same product can have different constraints in two portfolios.
- **Launch constraint** = custom IAM role Service Catalog assumes (users need no EC2/RDS rights). Specify by ARN (one account) or **local role name** (shared portfolios; create the role everywhere via StackSet). No launch constraint → user's own permissions. Receiving accounts can add their own launch constraint.
- **Template constraint** = limits parameter choices. **StackSet constraint** = one user launch → several accounts/Regions (user-driven, no auto-deploy).
- **Versions don't auto-upgrade** provisioned products; owner chooses "update". Admin can deprecate old versions. Contrast: StackSets push.
- **Share (reference)** = live link, updates flow, central source of truth. **Copy** = independent. Sharing ≠ access: grant users/groups/roles in each account, or centrally **by name** (e.g. `AWSReservedSSO_Developer*` wildcard for Identity Center roles).
- CloudFormation can launch products (`AWS::ServiceCatalog::CloudFormationProvisionedProduct`), reading their outputs.
- **Role chain in CodePipeline → CloudFormation → product**: EventBridge rule role (trigger) → pipeline service role (artifacts, call CFN, PassRole) → CloudFormation service role (only launch products + portfolio access) → launch constraint role (creates the resources).
- Sample question (all accounts, devs without EC2/ELB/IAM rights, updates reach everyone) → **share portfolio with the org + launch constraint**. Copy fails "updates", StackSet fails "developers deploy".

**Identity side-trip**
- Users don't own roles, they assume them. In orgs, developers land in Identity Center roles generated from permission sets.
- Pure IAM: user's identity policy allows `sts:AssumeRole` on the role ARN (no Principal element), **and** role trust policy names the user/account. Both must agree.
- **Identity-account pattern**: IAM users only in one account, roles in dev/prod trust it, users switch role. Identity Center automates this; on the exam it's the older approach/distractor.
- Exam identity patterns list: Identity Center; Identity Center + AD/external SAML IdP; cross-account roles (+ external ID for third parties); Roles Anywhere / OIDC for workloads; Cognito for app customers. IAM can trust SAML directly without Identity Center.

**Systems Manager**
- **No inbound port**: agent dials out on **HTTPS 443** and keeps the channel open. SG needs only outbound 443; NACLs must allow return traffic (stateless).
- Public regional endpoints (like S3), IAM-signed. Private subnet **without NAT** → interface endpoints `ssm`, `ssmmessages`, `ec2messages` (private DNS on, endpoint SG allows 443 from instances).
- **On-prem**: hybrid activation (code + ID) → `mi-` node with the activation's IAM role; outbound 443 via internet, or VPN/DX to interface endpoints.
- ⚠️ **The agent writes session logs / Run Command output itself** → instance role needs S3 (+ KMS) or CloudWatch Logs permissions, plus a network path (S3 gateway endpoint, `logs` interface endpoint).
- ⚠️ **General rule**: anything on the instance calling an AWS service needs **IAM permission + network path** (NAT or VPC endpoint). Basic EC2 metrics are collected from outside; agent logs, memory/disk, custom metrics need `logs` / `monitoring` endpoints.
- **Config remediation = an SSM Automation runbook** (e.g. `AWS-DisablePublicAccessForSecurityGroup`). Rule detects; remediation is a separate setting pointing at a runbook, with parameters (resource ID) and usually a role. Runs show under SSM → Automation. Auto-remediation = usual "least overhead" answer.
- **Regional and per-account**: nodes register locally. Central management: Quick Setup (org-wide), multi-account/Region Automation, unified console via Organizations + delegated admin (still called Systems Manager), Explorer, Inventory + Resource Data Sync.
- **Patch org-wide** → Quick Setup **patch policy** (OUs, Regions, baseline, schedule). **Automation across accounts** → central start with admin role + execution roles in targets (deploy roles by StackSet).
- **No account hierarchy**: flat (management/delegated admin vs members). OUs are only a targeting tool. Delegated admin = Organizations-granted, kept up to date for new accounts; self-managed = IAM trust you create.
- **Same mechanism everywhere** (StackSets, launch roles, cross-account Automation, cross-account CodePipeline): role in target account + trust policy + permissions. Self- vs service-managed = who creates the roles.
- **Automation triggers**: manual/API, Config remediation, **EventBridge** (event or schedule; how an alarm can start one), maintenance windows, State Manager associations, Incident/Change Manager. The **CloudWatch alarm field on an execution is a safety stop**, not a trigger.
- Exam depth for SSM: Session Manager, Patch Manager, Automation, Run Command, Parameter Store (rotation → Secrets Manager), managed-node basics.

### 2026-11-10 · Why does the EC2 instance need a role for SSM Run Command? Isn't SSM the one acting?
- **SSM never reaches into the instance.** The **SSM Agent** on the instance does the work: it makes outbound HTTPS calls to SSM, registers itself, **polls for commands**, runs them locally, and uploads results (pull model, no inbound ports). Those are API calls made **by the instance**, so the instance needs credentials → instance profile with `AmazonSSMManagedInstanceCore` (`ssm:UpdateInstanceInformation`, `ssmmessages:*`, `ec2messages:*`, ...). Add S3/CloudWatch Logs permissions if command output goes there.
- **Authorizing "run this on that instance"** is a separate check on whoever calls `ssm:SendCommand`: you in the console, or **EventBridge's target role** (EventBridge assumes a role with `ssm:SendCommand` on the document + instances).
- So the lab has **two roles**: EventBridge role = *send* the command. Instance profile = *receive and report*. The instance role is needed even when you run the command by hand.
- Alternative: **Default Host Management Configuration** (account-level setting; SSM provides the credentials, no instance profile).
- Exam cue: *"instance doesn't appear in Fleet Manager / Run Command target list"* → missing instance profile, agent not running, or no route to the SSM endpoints (NAT or interface endpoints `ssm`, `ssmmessages`, `ec2messages`).

### 2026-11-10 · Default Host Management Configuration (DHMC): where it's stored, how to change it
- **Stored as an SSM *service setting***, per **account + Region**: `/ssm/managed-instance/default-ec2-instance-management-role`. Its value is just the **role name**, default `service-role/AWSSystemsManagerDefaultEC2InstanceManagementRole`. Nothing is stored on the instance itself.
- **The role:** trust = **`ssm.amazonaws.com`** (not ec2), policy `AmazonSSMManagedEC2InstanceDefaultPolicy`. The agent proves its identity with the EC2 instance identity from **IMDSv2**; SSM assumes the role and hands the agent the credentials. That's why no instance profile is needed.
- **View / enable / disable:** `aws ssm get-service-setting` / `update-service-setting --setting-value <role>` / `reset-service-setting` (reset = DHMC off). Console: Fleet Manager → Account management → Configure DHMC. **Org-wide:** Quick Setup DHMC configuration across accounts/Regions.
- **Who can change it:** `ssm:UpdateServiceSetting` / `ResetServiceSetting` on that setting ARN, plus `iam:PassRole` on the role (`iam:PassedToService = ssm.amazonaws.com`). Harden with an SCP denying those for non-admins.
- **Requirements:** IMDSv2 (IMDSv1 not supported), SSM Agent ≥ 3.2.582.0. Can take ~30 min to take effect. Enable **per Region**.
- **Precedence:** agent tries the **instance profile first**. If the profile allows `ssm:UpdateInstanceInformation`, DHMC is not used.
- Exam cue: *"make all EC2 instances in the account/org managed by SSM without attaching instance profiles, least overhead"* → DHMC (via Quick Setup for an org).

### 2026-11-10 · What does the DHMC role's permissions policy look like?
- Two policies on the role: **trust** = `ssm.amazonaws.com`; **permissions** = `AmazonSSMManagedEC2InstanceDefaultPolicy`.
- Permissions = only what the agent needs to be managed (approximate, from memory; exact JSON: `aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy --version-id $(aws iam get-policy --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedEC2InstanceDefaultPolicy --query Policy.DefaultVersionId --output text)`):
  - `ssm:` UpdateInstanceInformation (heartbeat), GetDocument/DescribeDocument, List/DescribeAssociation(s), UpdateInstanceAssociationStatus, PutInventory, PutComplianceItems, GetDeployablePatchSnapshotForInstance, ...
  - `ssmmessages:` Create/Open Control/Data Channel (Session Manager, newer Run Command channel)
  - `ec2messages:` GetMessages, AcknowledgeMessage, SendReply, FailMessage, DeleteMessage, GetEndpoint (classic Run Command delivery)
- Not included: writing command output to **S3 / CloudWatch Logs**, **KMS** for Session Manager encryption, app data. Add those to the DHMC role (custom policy) or use an instance profile.
- Design point: DHMC = **one role for every instance in the account+Region**. Per-instance/app permissions → instance profile (which wins over DHMC).

### 2026-11-10 · How SSM Agent gets credentials: instance profile vs DHMC
| Step | Instance profile | DHMC |
|---|---|---|
| Role trusts | `ec2.amazonaws.com` | `ssm.amazonaws.com` |
| Role passed by | Whoever launches/attaches (`iam:PassRole` → EC2) | Admin enabling the setting (`iam:PassRole` → SSM) |
| Who calls STS AssumeRole | **EC2 service** | **SSM service** |
| Where creds land | IMDS `/latest/meta-data/iam/security-credentials/<role>` (EC2 rotates) | Handed to the agent by SSM (agent refreshes via SSM) |
| Who can use them | **Any process on the box** that reads IMDS | The SSM Agent |
| Scope | Per instance | Every instance in account+Region |
- Agent precedence: instance profile first; DHMC only if the profile doesn't allow `ssm:UpdateInstanceInformation`.

### 2026-11-16 · StackSet = one template × many accounts/Regions (NOT a bundle of different stacks)
- **StackSet** = **one template**, deployed as identical **stack instances** into target accounts × Regions. Update the StackSet → every instance updates.
- "Frontend + Backend as one unit" = **nested stacks** (parent template with `AWS::CloudFormation::Stack` children), or separate stacks linked by Outputs/`Fn::ImportValue`. Different concept.
- Can combine: StackSet whose template is a parent with nested stacks → same full app/baseline everywhere.
- Exam cues: *"same config/guardrail (Config rules, IAM role, CloudTrail, GuardDuty) in every account and Region, incl. new accounts"* → **StackSets, service-managed + automatic deployment on OU**. *"Reusable components inside one app template"* → nested stacks.

- **App uses of StackSets:** same app/infra in **multiple Regions** (active-active, DR standby Region), **account-per-tenant SaaS** (one template → every tenant account), regional replicas of shared services. CodePipeline has StackSet actions (`CloudFormationStackSet`, `CloudFormationStackInstances`) for pipeline-driven rollouts.
- **Limits:** rollout control = concurrency / failure tolerance / Region order only; no health-based canary or traffic shifting. For app *release strategy* (blue/green, canary, rollback on alarms) the exam wants **CodeDeploy / CodePipeline**, not StackSets.

## 8. Practice-question mistakes on this topic
- 2026-11-04 · TD D1 section set · StackSets org-wide deployment (details to add)
