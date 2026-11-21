# D1-03 · Federation & IAM Identity Center

> **Owner:** Claude · **Created:** 2026-10-30 · **Exam domain:** 1 (Organizational Complexity, 26%)
> **Status:** 🟡 In progress (session 2: Orgs / AuthN / AuthZ / IAM)
> Related: [[D1-01 Organizations & Control Tower]] · [[D1-02 IAM advanced]] (roles, trust policies, Roles Anywhere)

---

## 1. What Identity Center is (and isn't)
**Not a replacement for IAM.** It replaces **IAM users for humans** (workforce access) across **many accounts**. Machine/workload access stays plain IAM roles.

| Concern | Tool |
|---|---|
| People signing in to accounts (console / CLI) | **IAM Identity Center** |
| EC2 instance profile, Lambda execution role, ECS task role, automation cross-account roles, SLRs | **IAM roles** in each account (often deployed by CloudFormation StackSets / Control Tower customizations) |
| On-prem workloads | IAM Roles Anywhere (D1-02 §1) |

Org setup: enabled in the **management account** (organization instance), lives in **one home Region**, and admin can be **delegated** to a member account (best practice). An *account instance* also exists, but only for apps in a standalone account, not for multi-account permission sets.

## 2. Identity source (where users and groups live); exactly one at a time
| Identity source | When | Notes |
|---|---|---|
| **Identity Center directory** (built-in store) | Small orgs, labs, no corporate IdP | What you used in the lab |
| **Active Directory** | Corporate AD | Via **AWS Managed Microsoft AD**, or **AD Connector** → self-managed on-prem AD (proxy, no sync of passwords). Users/groups synced into Identity Center |
| **External IdP** (Okta, Entra ID, Ping, Google) | Company already has a SAML IdP | **SAML 2.0** for sign-in + **SCIM** for automatic user/group provisioning |

## 3. Permission sets are IAM roles under the hood
```
Identity Center (management / delegated admin account)
  Permission set "DevOps" = managed policies + customer-managed policy *names*
                          + inline policy + optional permissions boundary + session duration
        │  Assignment = (user or group) × permission set × account
        ▼  Identity Center provisions, in EACH target account:
  IAM role  AWSReservedSSO_DevOps_1a2b3c4d5e6f7a8b
     path   /aws-reserved/sso.amazonaws.com/
     trust  SAML provider  AWSSSO_xxxx_DO_NOT_DELETE  (in that account)
```
- A permission set is a **template**; the actual roles live **in each member account's IAM** and are **managed only by Identity Center** (you can't edit them in IAM; change the permission set and it re-provisions).
- **Customer managed policy references** are by **name**: a policy with that name must already exist in every target account.
- Sign-in: AWS access portal → pick account + role → console, or CLI via `aws configure sso` / `aws sso login` (short-lived creds).
- These are normal roles, so **SCPs apply** to them (except in the management account).
- CloudTrail in the member account shows `AWSReservedSSO_DevOps_.../<username>`.
- **ABAC**: *attributes for access control* (e.g. department, cost center from the IdP) become **session tags** → policies use `aws:PrincipalTag/...`, so fewer permission sets.
- Permission sets assigned to the **management account** can only be managed from the management account, not the delegated admin. Keep human access to the management account minimal.

## 4. Exam cues
| Phrase | Answer |
|---|---|
| "centrally manage workforce access to many accounts, least overhead" | **IAM Identity Center** + permission sets |
| "users already in on-prem AD, don't want to duplicate identities" | Identity Center + **AD Connector** (or AWS Managed Microsoft AD with trust) |
| "company uses Okta/Entra ID, automatic user provisioning" | External IdP: **SAML 2.0 + SCIM** |
| "grant access based on department attribute from IdP" | Identity Center **ABAC** (attributes for access control) |
| "EC2/Lambda needs access to S3" | Still an **IAM role** (instance profile / execution role), not Identity Center |
| "IAM users with access keys in every account" | ❌ legacy distractor |

---

## 5. "Permissions managed in AD": how AD groups map to AWS
AD can't hold IAM policies. The split is:
- **AWS side** defines *what* each role / permission set can do (IAM policies).
- **AD side** decides *who* gets it, via **group membership** (and optionally user attributes for ABAC).
So admins grant or revoke AWS access by changing AD groups; it *looks* like permissions live in AD.

### 5.1 Pattern A: classic SAML federation with AD FS (no Identity Center), common in older enterprises
```
User ──Windows login──► AD FS ──SAML assertion──► AWS sign-in (signin.aws.amazon.com/saml)
                         │ claim rule: AD group "AWS-111122223333-Admins"
                         │   → Role attribute = "arn:aws:iam::111122223333:role/Admins,
                         │                       arn:aws:iam::111122223333:saml-provider/ADFS"
                         ▼
   Each AWS account: IAM SAML provider "ADFS" + roles whose trust policy trusts it
   STS AssumeRoleWithSAML → temporary creds; user picks a role if in several groups
```
- **Group naming convention encodes account ID + role name**; one claim rule turns every matching group into a role.
- Setup is **per account** (SAML provider + roles in each), usually pushed with StackSets.
- CLI: helper tools (e.g. saml2aws / aws-adfs) do the SAML dance and write temp creds.

### 5.2 Pattern B: Identity Center with AD as the identity source (modern)
- **AD Connector** (to on-prem AD) or **AWS Managed Microsoft AD** (with a trust to on-prem AD).
- AD users/groups are **synced** into Identity Center (configurable sync scope); assign **permission sets to AD groups**.
- Variant: AD → Entra Connect → **Entra ID** → Identity Center via SAML + SCIM.

### 5.3 Attributes → ABAC
AD attributes (department, cost center, project) can be passed as **session tags**:
- Pattern A: SAML attribute `https://aws.amazon.com/SAML/Attributes/PrincipalTag:Department`
- Pattern B: Identity Center *attributes for access control*
Policies then use `aws:PrincipalTag/Department`, e.g. only start/stop EC2 instances tagged with the same department.

### 5.4 Which one does an org use?
| Clue | Pattern |
|---|---|
| Sign-in via `signin.aws.amazon.com/saml` with a role picker page | A: AD FS SAML federation |
| Sign-in via `https://<something>.awsapps.com/start` portal | B: Identity Center |
| Role names `AWSReservedSSO_*` in the accounts | B |

Exam cue: *"existing AD FS federation per account, want central multi-account management with least overhead"* → migrate to **Identity Center** with AD as identity source.

---

## 6. Third-party IdPs such as Google: first ask "workforce or customers?"
| Who signs in | Google product | AWS service | Protocol |
|---|---|---|---|
| **Employees** into AWS accounts (console/CLI) | **Google Workspace** (corporate accounts, not consumer Gmail) | **IAM Identity Center**, external IdP | **SAML 2.0** sign-in + **SCIM** provisioning |
| **End users** of your web/mobile app ("Sign in with Google") | Google accounts (incl. Gmail) | **Amazon Cognito** | OIDC / OAuth 2.0 |

### 6.1 Workforce: Google Workspace → Identity Center
1. Identity Center: change identity source to **External identity provider**; download the Identity Center SAML metadata (ACS URL, issuer).
2. Google Admin console: add the AWS IAM Identity Center SAML app with that metadata; download Google's IdP metadata and upload it to Identity Center.
3. Enable **automatic provisioning (SCIM)**: Identity Center gives a SCIM endpoint + access token; Google creates/updates/disables users there. (Google's SCIM has historically synced users but not groups; AWS's open-source *ssosync* filled that gap. Check current docs.)
4. Assign permission sets to those users/groups as usual.

Sign-in flow:
```
User → AWS access portal (awsapps.com/start) ─redirect─► Google login (+ Google MFA)
     ◄── SAML assertion (user email) ── Google
Identity Center matches the provisioned user → shows assigned accounts/permission sets
     → picks one → STS creds for AWSReservedSSO_<PermSet> role in that account
```
- Authentication (password, MFA) happens **at Google**; authorization (which accounts/roles) stays **in Identity Center**.
- Disable the user in Google → SCIM disables them in Identity Center → no new sessions.
- Identity Center external IdPs must speak **SAML 2.0**; Entra ID, Okta, Ping, JumpCloud work the same way.

### 6.2 Customers: Google → Cognito
- **Cognito user pool** with Google as a *social IdP* (OIDC/OAuth): app gets Cognito JWTs (ID/access tokens) → use with API Gateway / ALB authorizers.
- **Cognito identity pool**: exchanges those tokens for **temporary AWS creds** (AssumeRoleWithWebIdentity under the hood) for authenticated / unauthenticated (guest) roles → app calls S3/DynamoDB directly. ABAC/`${cognito-identity.amazonaws.com:sub}` scopes each user to their own data.
- Direct IAM OIDC federation with `accounts.google.com` is possible but AWS recommends Cognito for apps.

Exam cues: *"employees use Google Workspace, access multiple AWS accounts"* → Identity Center + external IdP (SAML + SCIM). *"Mobile app users sign in with Google/Facebook/Apple and upload to S3"* → **Cognito** user pool + identity pool.

### 6.3 How a Cognito identity pool links to IAM roles
> **Plain version:** there is only **one kind of role: IAM roles**. Cognito has no roles of its own. A user pool has **groups** (labels on users); the identity pool has **settings that point at IAM role ARNs**. Cognito's job is only to **pick** which IAM role this user gets, then fetch STS creds for it. Receptionist analogy: checks your badge (token), hands you the key to the right room; the rooms are built in IAM.
>
> `user → group/claim (Cognito) → IAM role ARN (identity pool setting) → STS temp creds`

**Three places make the link:**

**1. Role settings on the identity pool**
- **Authenticated role** (default for signed-in users) and **unauthenticated / guest role** (if guest access is enabled).
- Optional **role mapping per identity provider** (Google, a user pool, SAML ...):
  - *Use default*: the authenticated role.
  - *Choose role from token*: **user pool groups** each carry an IAM role ARN + precedence; the token's `cognito:roles` / `cognito:preferred_role` claims pick it.
  - *Choose role with rules*: claim-based rules, e.g. `custom:dept equals "finance"` → FinanceRole. First match wins.
  - If no rule matches / ambiguous: fall back to the authenticated role **or deny**.

**2. Trust policy on each role** (it trusts the identity pool, not Google)
```json
{
  "Effect": "Allow",
  "Principal": { "Federated": "cognito-identity.amazonaws.com" },
  "Action": ["sts:AssumeRoleWithWebIdentity", "sts:TagSession"],
  "Condition": {
    "StringEquals": { "cognito-identity.amazonaws.com:aud": "us-west-2:<identity-pool-id>" },
    "ForAnyValue:StringLike": { "cognito-identity.amazonaws.com:amr": "authenticated" }
  }
}
```
⚠️ Without the `aud` condition, **any** identity pool in any account could get this role. `amr` separates authenticated vs guest.

**3. Permissions policy scoped per user**
`${cognito-identity.amazonaws.com:sub}` = the user's identity ID, e.g. `arn:aws:s3:::app-uploads/${cognito-identity.amazonaws.com:sub}/*` so each user sees only their own prefix. Or ABAC: *attributes for access control* map token claims → principal tags.

**Runtime flow (enhanced flow)**
```
App → Google / user pool login → token
App → Cognito GetId(token)                      → identity ID (stable per user)
App → Cognito GetCredentialsForIdentity(token)  → Cognito picks role (defaults/rules)
                                                  and calls STS for you
    ← temporary AWS creds → App calls S3 / DynamoDB directly
```
(Basic/classic flow: app calls `GetOpenIdToken` and then `sts:AssumeRoleWithWebIdentity` itself with a role ARN it chooses. Enhanced flow also adds a scope-down session policy for guest roles.)

---

## 7. SAML vs OIDC
| | **SAML 2.0** | **OIDC** (OpenID Connect, on top of OAuth 2.0) |
|---|---|---|
| Token | **XML assertion**, signed with XML-DSig | **JWT** ID token: `header.payload.signature`, base64url JSON |
| Era / home | 2005, enterprise SSO | 2014, web, mobile, APIs, machines |
| Transport | Browser **POSTs** the assertion to the service | Redirects + back-channel token exchange (auth code + PKCE); tokens in HTTP headers |
| Good for | Employees signing in through a browser | Mobile/SPA apps, APIs, **workloads** (CI pipelines, Kubernetes pods) |
| Weak at | Mobile apps, CLI, machine-to-machine (needs browser-scraping helpers) | Older enterprise IdPs (though most now support both) |
| AWS STS call | `AssumeRoleWithSAML` | `AssumeRoleWithWebIdentity` |
| IAM object | **SAML provider** (upload IdP metadata XML) | **OIDC provider** (issuer URL + audience/client ID) |
| Typical AWS uses | AD FS → accounts; Okta/Entra/Google Workspace → **Identity Center** | **Cognito**, **EKS IRSA**, **GitHub Actions / CI**, Google/Apple/Facebook sign-in |

- **JWT = OIDC.** SAML never uses JWTs.
- Cognito user pools always issue **JWTs to your app**, even if the upstream IdP is SAML: Cognito accepts the SAML assertion and converts it.
- Both carry **claims/attributes** usable in trust-policy conditions and as **session tags** (ABAC).

Exam cues: *"corporate IdP supporting SAML 2.0, console access"* → SAML / Identity Center. *"CI/CD pipeline (GitHub Actions) deploys to AWS without stored keys"* or *"Kubernetes pods need per-pod AWS permissions"* → **OIDC provider + AssumeRoleWithWebIdentity** (IRSA, or EKS Pod Identity).

---

## 8. IAM account access manager (new Aug 2026, **not on SAP-C02**)
Launched 2026-08-10, after the SAP-C02 question bank was set → won't be tested. Good to know for real work / SAP-C03.
- An **IAM feature** that assigns **your own existing IAM roles** in each account to **Identity Center users and groups** (requires an Identity Center **organization instance**).
- Fills the gap between: per-account SAML federation into custom roles (flexible, but no single sign-in point) and permission sets (single sign-in, but roles are templated and immutable `AWSReservedSSO_*`).
- You build/own the roles (IaC or console), keep your own trust-policy conditions, role paths, tags/ABAC. Mapping user/group → role lives in account access manager.
- Users: **account access portal** in the browser; CLI via `aws login` (vs `aws configure sso` / `aws sso login` for permission sets). API namespace `account-access`. No extra cost.
- Can run **alongside** permission sets: permission sets for uniform baseline (ReadOnly, Admin); account access manager for custom per-account roles.

Sources: AWS What's New (2026-08) and IAM User Guide "Account access manager".

---

## Q&A 2026-11-12 · Dojo Q: "extend existing AD to AWS, SSO with Windows password" → Directory Service + trust, no Identity Center?
- The keyed answer works **on its own**: Managed Microsoft AD + **forest trust** to on-prem AD → on-prem users authenticate with their own passwords. Directory Service itself can give AD users/groups **console access via IAM roles** (access URL `<alias>.awsapps.com`) and SSO for AD-aware services (WorkSpaces, WorkDocs, QuickSight, RDS SQL Server, FSx for Windows). The "Enable single sign-on" in the option is Directory Service's own SSO setting (domain-joined PCs don't re-enter credentials).
- Question predates Identity Center being the default answer. The modern design = **Identity Center with identity source = Active Directory** (Managed AD trust or AD Connector). That isn't offered.
- Option B loses on two words: **"Create users and groups"** in Identity Center = new identities with new passwords, not the existing Windows password.
- Rule: *"existing AD password"* → AD must stay the identity source. Pick the option that connects to AD (Directory Service trust / AD Connector, or Identity Center **with AD as source**). Reject any option that creates users in IAM/Identity Center, or uses Cognito (customers, not workforce).
- *"Extend the domain to AWS"* → Managed Microsoft AD + trust. *"Just proxy auth to on-prem AD, no directory in AWS"* → AD Connector.
- **Follow-up: is it SAML under the hood?** Not for Directory Service console access. User authenticates to the directory at the access URL; the role trusts **`ds.amazonaws.com`**; **Directory Service calls `sts:AssumeRole`** and signs the user into the console with the temp creds (service-brokered, same shape as DHMC). SAML (`AssumeRoleWithSAML`, role trusts an IAM SAML provider) is the **AD FS** path (§5.1), and also what **Identity Center** permission-set roles use (`AWSReservedSSO_*` trust `saml-provider/AWSSSO_*`).

## Q&A 2026-11-12 · Dojo Q: on-prem LDAP (not SAML) → custom identity broker + AssumeRole
- **Federation** = AWS trusts an external IdP's statement of who the user is, with no IAM user. IAM federation speaks only **SAML 2.0 or OIDC** (IAM identity providers) → `AssumeRoleWithSAML` / `AssumeRoleWithWebIdentity`. **LDAP is a directory protocol, not a federation protocol**, so IAM can't federate with it directly.
- **Option 2 wrong:** "set up a federation between LDAP and IAM" is impossible (same flaw as option 4). The rest (look up role, AssumeRole) is what the broker does in option 1.
- **"Federated user credentials" (option 3)** = STS **`GetFederationToken`**. The broker calls it with **long-term IAM user keys**; result principal `arn:aws:sts::<acct>:federated-user/<name>`; permissions = intersection of that IAM user's policies and the session policy passed; 15 min–36 h; can't call IAM APIs. Valid legacy pattern but loses: long-term keys in the broker, one user's permissions cap everyone, no role per group. AWS recommends **roles** (`AssumeRole`).
- Rule: *LDAP / non-SAML directory* → **custom identity broker + `sts:AssumeRole`**. *SAML-capable (AD FS)* → SAML federation / Identity Center. *AD* → Directory Service / AD Connector / Identity Center with AD source.
- Stem (Q25): on-prem LDAP + IPSec VPN to the VPC; employees use the same corporate account. No SAML mentioned → plain LDAP = no SAML/OIDC IdP. **VPN** = lets a broker in the VPC reach LDAP privately (supporting detail, not the deciding one). Stem has no tie-breaker between options 1 and 3, so option 3 loses on best practice alone (roles > `GetFederationToken`).

## Q&A 2026-11-16 · Cognito: user pool only, or identity pool too?
- Users only use the app (frontend → backend API) → **user pool only**. It signs users in and issues JWTs (ID/access tokens). Backend checks them: **API Gateway Cognito authorizer**, **ALB `authenticate-cognito`**, or JWT validation in code. Backend (Lambda/ECS) reaches S3/DynamoDB with **its own IAM role**.
- **Identity pool** only when the **client itself calls AWS APIs** (browser/mobile → S3 upload, DynamoDB, IoT, Kinesis) and needs temporary AWS credentials, or for **guest (unauthenticated)** AWS access. User pool JWTs are not AWS credentials.
- Cues: *"authenticate users to the web app / API"* → user pool. *"mobile app uploads directly to S3 per-user prefix"* → identity pool (+ `${cognito-identity.amazonaws.com:sub}` in the role policy).
