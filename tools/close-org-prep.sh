#!/usr/bin/env bash
# Prepare an AWS Organization for closure (run in CloudShell of the MANAGEMENT account).
#
#   bash close-org-prep.sh                  # REPORT ONLY: cost by service (last 7 days),
#                                           #   billable resources in every Region, member accounts
#   bash close-org-prep.sh --close-members  # also CLOSE every ACTIVE member account (asks to confirm)
#   Regions: US only by default; REGIONS="us-west-2" or ALL_REGIONS=1 to change
#
# Afterwards, close the management account by hand: sign in as ROOT → Account page → Close account.
# (AWS does not allow closing the management account via CLI/API.)
set -u
export AWS_PAGER=""
CLOSE=0; [[ "${1:-}" == "--close-members" ]] && CLOSE=1
say(){ echo -e "\n==== $* ===="; }
q(){ "$@" 2>/dev/null || true; }

ME=$(aws sts get-caller-identity --query Account --output text)
MGMT=$(q aws organizations describe-organization --query Organization.MasterAccountId --output text)
say "Caller account $ME · Management account ${MGMT:-<no organization>}"
if [[ -n "$MGMT" && "$MGMT" != "$ME" ]]; then echo "Run this from the management account ($MGMT)."; exit 1; fi

# ---------- 1. What is costing money (Cost Explorer, last 7 days, by service) ----------
say "Cost by service, last 7 days (USD, unblended; Cost Explorer lags ~24 h)"
echo "  Querying Cost Explorer..."
START=$(date -u -d '7 days ago' +%F); END=$(date -u +%F)
q aws ce get-cost-and-usage --time-period Start=$START,End=$END --granularity DAILY \
  --metrics UnblendedCost --group-by Type=DIMENSION,Key=SERVICE --output json \
| python3 -c '
import json,sys,collections
try: d=json.load(sys.stdin)
except Exception: print("  (Cost Explorer not available)"); sys.exit()
tot=collections.defaultdict(float); days=collections.defaultdict(float)
for r in d.get("ResultsByTime",[]):
    for g in r["Groups"]:
        a=float(g["Metrics"]["UnblendedCost"]["Amount"]); tot[g["Keys"][0]]+=a; days[r["TimePeriod"]["Start"]]+=a
for s,a in sorted(tot.items(),key=lambda x:-x[1]):
    if a>=0.01: print(f"  {a:9.2f}  {s}")
print("  per day:", "  ".join(f"{k[5:]}={v:.2f}" for k,v in sorted(days.items())))'

# ---------- 2. Billable resources in every Region (parallel, with progress) ----------
say "Billable resources still present (scanning Regions in parallel; empty Regions are skipped)"
export TMPD=$(mktemp -d)
export AWS_CLI_OPTS="--cli-connect-timeout 5 --cli-read-timeout 15"
scan_region(){
  local r="$1" t0=$SECONDS out=""
  add(){ local label="$1"; shift; local v
         v=$(timeout 30 "$@" --region "$r" --output text $AWS_CLI_OPTS 2>/dev/null)
         [[ -n "$v" && "$v" != "None" ]] && out+="    $label: $(echo $v | tr '\n' ' ')\n"; }
  add "EC2 instances"        aws ec2 describe-instances --filters Name=instance-state-name,Values=running,pending,stopped --query "Reservations[].Instances[].[InstanceId,State.Name]"
  add "NAT gateways"         aws ec2 describe-nat-gateways --filter Name=state,Values=available,pending --query "NatGateways[].NatGatewayId"
  add "Elastic IPs"          aws ec2 describe-addresses --query "Addresses[].PublicIp"
  add "Load balancers"       aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName"
  add "Classic ELBs"         aws elb describe-load-balancers --query "LoadBalancerDescriptions[].LoadBalancerName"
  add "Resolver endpoints"   aws route53resolver list-resolver-endpoints --query "ResolverEndpoints[].[Id,Name]"
  add "Client VPN"           aws ec2 describe-client-vpn-endpoints --query "ClientVpnEndpoints[].ClientVpnEndpointId"
  add "Site-to-Site VPN"     aws ec2 describe-vpn-connections --filters Name=state,Values=available,pending --query "VpnConnections[].VpnConnectionId"
  add "Transit gateways"     aws ec2 describe-transit-gateways --filters Name=state,Values=available,pending --query "TransitGateways[].TransitGatewayId"
  add "Interface endpoints"  aws ec2 describe-vpc-endpoints --filters Name=vpc-endpoint-type,Values=Interface --query "VpcEndpoints[].VpcEndpointId"
  add "EBS volumes"          aws ec2 describe-volumes --query "Volumes[].VolumeId"
  add "RDS instances"        aws rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier"
  add "RDS/Aurora clusters"  aws rds describe-db-clusters --query "DBClusters[].DBClusterIdentifier"
  add "ElastiCache"          aws elasticache describe-cache-clusters --query "CacheClusters[].CacheClusterId"
  add "EKS clusters"         aws eks list-clusters --query "clusters"
  add "ECS clusters"         aws ecs list-clusters --query "clusterArns"
  add "EFS file systems"     aws efs describe-file-systems --query "FileSystems[].FileSystemId"
  add "FSx file systems"     aws fsx describe-file-systems --query "FileSystems[].FileSystemId"
  add "OpenSearch domains"   aws opensearch list-domain-names --query "DomainNames[].DomainName"
  add "Kinesis streams"      aws kinesis list-streams --query "StreamNames"
  add "MSK clusters"         aws kafka list-clusters-v2 --query "ClusterInfoList[].ClusterName"
  add "CloudFormation stacks" aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE DELETE_FAILED UPDATE_ROLLBACK_COMPLETE --query "StackSummaries[].StackName"
  [[ -n "$out" ]] && echo -e "  == $r\n$out" > "$TMPD/$r.txt"
  local found="clean"; [[ -n "$out" ]] && found="RESOURCES FOUND"
  echo "  ✓ $(printf '%-16s' "$r") $((SECONDS-t0))s  $found" >&2
}
export -f scan_region
# Default: the four US Regions only (the org restricts usage to US Regions).
# Override:  REGIONS="us-west-2" bash close-org-prep.sh   or   ALL_REGIONS=1 bash close-org-prep.sh
if [[ "${ALL_REGIONS:-0}" == "1" ]]; then
  REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)
else
  REGIONS="${REGIONS:-us-east-1 us-east-2 us-west-1 us-west-2}"
fi
N=$(echo $REGIONS | wc -w)
echo "  Scanning $N Region(s): $REGIONS (22 resource types each, in parallel)..."
T0=$SECONDS
echo $REGIONS | tr ' ' '\n' | xargs -P 8 -I{} bash -c 'scan_region "$@"' _ {}
echo "  Scan finished in $((SECONDS-T0))s"
if ls "$TMPD"/*.txt >/dev/null 2>&1; then cat "$TMPD"/*.txt; else echo "  No billable resources found in any Region ✅"; fi
rm -rf "$TMPD"
say "Global resources"
echo "  Checking Route 53, CloudFront, S3..."
echo "  Hosted zones:     $(q aws route53 list-hosted-zones --query 'HostedZones[].Name' --output text)"
echo "  CloudFront:       $(q aws cloudfront list-distributions --query 'DistributionList.Items[].Id' --output text)"
echo "  S3 buckets:       $(q aws s3api list-buckets --query 'Buckets[].Name' --output text | wc -w) bucket(s)"
echo "  (Resources in MEMBER accounts are not listed here; closing those accounts removes them.)"

# ---------- 3. Member accounts ----------
[[ -z "$MGMT" ]] && { say "No organization: close this account from the Account page as root."; exit 0; }
say "Member accounts"
echo "  Listing accounts in the organization..."
aws organizations list-accounts --query "Accounts[].[Id,Name,Status]" --output table
ACTIVE=$(aws organizations list-accounts --query "Accounts[?Status=='ACTIVE' && Id!='$MGMT'].Id" --output text)

if [[ $CLOSE -eq 0 ]]; then
  say "REPORT ONLY. To close the active member accounts above, re-run with --close-members"
  exit 0
fi
[[ -z "$ACTIVE" ]] && { say "No active member accounts left. Next: close the management account (root, Account page)."; exit 0; }

echo -e "\nAbout to CLOSE these member accounts (reversible for 90 days via AWS Support): $ACTIVE"
read -r -p "Type CLOSE to continue: " ans
[[ "$ans" == "CLOSE" ]] || { echo "Aborted."; exit 1; }
for a in $ACTIVE; do
  echo "  closing $a ..."
  aws organizations close-account --account-id "$a" 2>&1 | sed 's/^/    /' || true
done
sleep 10
say "Status after request (PENDING_CLOSURE / SUSPENDED / CLOSED all count as closed for the next step)"
aws organizations list-accounts --query "Accounts[].[Id,Name,Status]" --output table
cat <<'EOF'

NEXT (manual, required by AWS):
  1. Sign out, then sign in to the management account as the ROOT user.
  2. Top-right account menu → Account → scroll to "Close account".
  3. Tick the acknowledgements, enter the account ID, Close account.
  You'll get a confirmation email; a final bill arrives next month for usage up to today.
If close-account returned a quota error, AWS limits how many member accounts can be closed
in a 30-day window: close the rest later, or ask AWS Support (Account and billing case).
EOF
