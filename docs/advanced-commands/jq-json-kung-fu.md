# JQ JSON Kung Fu for DevOps Engineers

Master JQ for powerful JSON manipulation, API response parsing, and cloud CLI output processing.

## Table of Contents
- [Why JQ for DevOps](#why-jq-for-devops)
- [JQ Basics](#jq-basics)
- [Essential Filters](#essential-filters)
- [Real-World Cloud Examples](#real-world-cloud-examples)
- [Advanced Techniques](#advanced-techniques)
- [Performance Tips](#performance-tips)

---

## Why JQ for DevOps

Modern cloud platforms (AWS, GCP, Azure) and APIs return JSON. JQ is essential for:
- ✅ **Parsing cloud CLI output** (aws, gcloud, az)
- ✅ **Extracting specific fields** from complex JSON
- ✅ **Transforming data structures**
- ✅ **Building automation scripts**
- ✅ **Creating custom reports**

---

## JQ Basics

### Simple Field Access
```bash
# Input JSON
echo '{"name": "web-server", "status": "running", "port": 8080}' | jq '.'

# Access field
echo '{"name": "web-server", "status": "running"}' | jq '.name'
# Output: "web-server"

# Access nested field
echo '{"server": {"name": "web-01", "ip": "10.0.1.5"}}' | jq '.server.name'
# Output: "web-01"
```

### Array Access
```bash
# First element
echo '[1, 2, 3, 4, 5]' | jq '.[0]'
# Output: 1

# Last element
echo '[1, 2, 3, 4, 5]' | jq '.[-1]'
# Output: 5

# Slice
echo '[1, 2, 3, 4, 5]' | jq '.[1:3]'
# Output: [2, 3]

# All elements
echo '[{"name": "web-01"}, {"name": "web-02"}]' | jq '.[] | .name'
# Output:
# "web-01"
# "web-02"
```

---

## Essential Filters

### 1. Pipe Operator (`|`)
Chain multiple operations:
```bash
echo '{"servers": [{"name": "web-01", "cpu": 45}, {"name": "web-02", "cpu": 89}]}' | \
  jq '.servers[] | select(.cpu > 50) | .name'
# Output: "web-02"
```

### 2. Select Filter
Filter based on conditions:
```bash
# Equal
jq '.[] | select(.status == "running")'

# Greater than
jq '.[] | select(.cpu > 80)'

# Contains
jq '.[] | select(.tags | contains(["production"]))'

# Regex match
jq '.[] | select(.name | test("^web-"))'
```

### 3. Map Function
Transform arrays:
```bash
echo '[{"name": "server1", "cpu": 45}, {"name": "server2", "cpu": 89}]' | \
  jq 'map(.name)'
# Output: ["server1", "server2"]

# Extract multiple fields
jq 'map({name: .name, cpu: .cpu})'
```

### 4. Keys and Values
```bash
# Get all keys
echo '{"name": "web", "cpu": 45, "mem": 67}' | jq 'keys'
# Output: ["cpu", "mem", "name"]

# Get all values
jq 'values'
```

---

## Real-World Cloud Examples

### AWS EC2 Instances

```bash
# List all running instances with their names
aws ec2 describe-instances --region us-east-1 | \
  jq -r '.Reservations[].Instances[] |
    select(.State.Name == "running") |
    [.InstanceId, (.Tags[]? | select(.Key == "Name") | .Value), .PrivateIpAddress] |
    @tsv'

# Output:
# i-1234567890abcdef0    web-server-01    10.0.1.5
# i-0987654321fedcba0    db-server-01     10.0.2.10
```

### Find Instances Without Required Tags
```bash
aws ec2 describe-instances | \
  jq -r '.Reservations[].Instances[] |
    select(.Tags == null or
           (.Tags | map(.Key) | contains(["Environment", "Owner"]) | not)) |
    .InstanceId'
```

### Calculate Total EBS Volume Cost
```bash
aws ec2 describe-volumes --region us-east-1 | \
  jq '[.Volumes[] | .Size] | add as $total_gb |
      ($total_gb * 0.10) as $monthly_cost |
      "Total: \($total_gb)GB, Cost: $\($monthly_cost)/month"'
```

---

### AWS S3 Buckets

```bash
# Find buckets without encryption
aws s3api list-buckets | jq -r '.Buckets[].Name' | while read bucket; do
  encryption=$(aws s3api get-bucket-encryption --bucket "$bucket" 2>&1)
  if echo "$encryption" | grep -q "ServerSideEncryptionConfigurationNotFoundError"; then
    echo "$bucket - NO ENCRYPTION"
  fi
done

# List large objects
aws s3api list-objects-v2 --bucket my-bucket | \
  jq -r '.Contents[] | select(.Size > 1073741824) |
    [.Key, (.Size / 1073741824 | floor | tostring + "GB")] | @tsv'
```

---

### GCP Compute Instances

```bash
# List instances with high CPU
gcloud compute instances list --format=json | \
  jq -r '.[] | select(.status == "RUNNING") |
    [.name, .zone, .machineType] | @tsv'

# Find instances in wrong zone
gcloud compute instances list --format=json | \
  jq -r '.[] | select(.zone | contains("us-central") | not) |
    .name + " is in " + .zone'
```

---

### Kubernetes

```bash
# Find pods using more than 100Mi memory
kubectl top pods --all-namespaces -o json | \
  jq -r '.items[] |
    select(.containers[].usage.memory | gsub("Mi"; "") | tonumber > 100) |
    [.metadata.namespace, .metadata.name, .containers[].usage.memory] | @tsv'

# List pods with restarts
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] |
    select(.status.containerStatuses[]?.restartCount > 0) |
    [.metadata.namespace, .metadata.name,
     (.status.containerStatuses[].restartCount | tostring)] | @tsv'
```

---

### Docker

```bash
# Find containers using more than 1GB memory
docker stats --no-stream --format=json | \
  jq -r '. | select(.MemUsage | split("/")[0] | gsub("GiB"; "") | tonumber > 1) |
    [.Name, .MemUsage, .CPUPerc] | @tsv'

# List stopped containers
docker ps -a --format=json | \
  jq -r 'select(.State != "running") |
    [.Names, .State, .Status] | @tsv'
```

---

## Advanced Techniques

### 1. Building Custom Objects
```bash
# Transform structure
aws ec2 describe-instances | \
  jq '.Reservations[].Instances[] | {
    instance_id: .InstanceId,
    name: (.Tags[]? | select(.Key == "Name") | .Value),
    type: .InstanceType,
    state: .State.Name,
    private_ip: .PrivateIpAddress,
    public_ip: .PublicIpAddress // "none"
  }'
```

### 2. Group By
```bash
# Group EC2 instances by instance type
aws ec2 describe-instances | \
  jq '[.Reservations[].Instances[]] |
      group_by(.InstanceType) |
      map({
        instance_type: .[0].InstanceType,
        count: length,
        instance_ids: map(.InstanceId)
      })'
```

### 3. Flatten Nested Arrays
```bash
# Flatten security groups
aws ec2 describe-instances | \
  jq '[.Reservations[].Instances[].SecurityGroups[]] | unique_by(.GroupId)'
```

### 4. Calculations and Aggregations
```bash
# Sum values
echo '[{"size": 100}, {"size": 200}, {"size": 300}]' | \
  jq '[.[].size] | add'
# Output: 600

# Average
jq '[.[].value] | add / length'

# Min/Max
jq '[.[].value] | min'
jq '[.[].value] | max'
```

### 5. Conditional Logic
```bash
# if-then-else
jq '.instances[] |
  if .cpu > 80 then
    "HIGH: " + .name
  elif .cpu > 50 then
    "MEDIUM: " + .name
  else
    "LOW: " + .name
  end'
```

---

## Complex Real-World Examples

### Example 1: AWS Cost Report by Service
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE | \
jq -r '.ResultsByTime[].Groups[] |
  select(.Metrics.BlendedCost.Amount | tonumber > 10) |
  [.Keys[0], (.Metrics.BlendedCost.Amount | tonumber | floor | tostring)] |
  @tsv' | \
  sort -k2 -rn | \
  column -t
```

### Example 2: Security Group Audit
```bash
# Find security groups with 0.0.0.0/0 access
aws ec2 describe-security-groups | \
  jq -r '.SecurityGroups[] |
    select(.IpPermissions[]?.IpRanges[]?.CidrIp == "0.0.0.0/0") |
    {
      group_id: .GroupId,
      group_name: .GroupName,
      vpc_id: .VpcId,
      open_ports: [.IpPermissions[] |
        select(.IpRanges[]?.CidrIp == "0.0.0.0/0") |
        if .FromPort then
          "\(.FromPort)-\(.ToPort)/\(.IpProtocol)"
        else
          "all/\(.IpProtocol)"
        end
      ]
    }' | \
  jq -s '.'
```

### Example 3: Multi-Cloud Inventory
```bash
#!/bin/bash
# Combine AWS, GCP, Azure inventories

{
  # AWS
  aws ec2 describe-instances | \
    jq '.Reservations[].Instances[] | {
      cloud: "AWS",
      id: .InstanceId,
      name: (.Tags[]? | select(.Key == "Name") | .Value),
      type: .InstanceType,
      state: .State.Name
    }'

  # GCP
  gcloud compute instances list --format=json | \
    jq '.[] | {
      cloud: "GCP",
      id: (.id | tostring),
      name: .name,
      type: .machineType,
      state: .status
    }'
} | jq -s 'group_by(.cloud) | map({cloud: .[0].cloud, count: length})'
```

---

## Performance Tips

### 1. Use `--raw-output` (`-r`) for Text
```bash
# Without -r (includes quotes)
echo '{"name": "server"}' | jq '.name'
# Output: "server"

# With -r (raw text)
echo '{"name": "server"}' | jq -r '.name'
# Output: server
```

### 2. Use `--compact-output` (`-c`) for Logging
```bash
# Compact JSON (one line)
jq -c '.'
```

###  3. Stream Large Files with `--stream`
```bash
# Process huge JSON files line by line
jq --stream 'select(length == 2)' huge.json
```

### 4. Use `limit` for Testing
```bash
# Test on first 10 items
jq 'limit(10; .items[])'
```

---

## JQ vs Other Tools

| Task | JQ | Alternative |
|------|-----|------------|
| Parse JSON | ⭐⭐⭐⭐⭐ | `python -m json.tool`, `yq` |
| Extract fields | ⭐⭐⭐⭐⭐ | `grep`, `awk` (harder) |
| Transform structure | ⭐⭐⭐⭐⭐ | Python script |
| Filter arrays | ⭐⭐⭐⭐⭐ | Python, `awk` (flatter data) |
| YAML support | ❌ | Use `yq` instead |

---

## Common Patterns Cheat Sheet

```bash
# Pretty print
jq '.'

# Access field
jq '.field'

# Array element
jq '.[0]'

# All array elements
jq '.[]'

# Filter
jq '.[] | select(.key == "value")'

# Map
jq 'map(.field)'

# First N items
jq '.[:10]'

# Keys
jq 'keys'

# Length
jq 'length'

# Unique values
jq 'unique'

# Sort
jq 'sort_by(.field)'

# Group by
jq 'group_by(.field)'

# Add (sum)
jq '[.[].value] | add'

# Regex match
jq 'select(.field | test("regex"))'

# String interpolation
jq '"Value: \(.field)"'

# TSV output
jq -r '[.f1, .f2] | @tsv'

# CSV output
jq -r '[.f1, .f2] | @csv'
```

---

## Debugging JQ

```bash
# See data at each step
echo '{"a": {"b": {"c": 42}}}' | jq '.a | .b | .c'

# Use debug
jq '.servers | debug | .[]'

# Check types
jq '.field | type'
```

---

## Resources

- [Official JQ Manual](https://stedolan.github.io/jq/manual/)
- [JQ Play](https://jqplay.org/) - Interactive JQ playground
- [JQ Cookbook](https://github.com/stedolan/jq/wiki/Cookbook)

---

**Master JQ and unlock the full power of cloud CLI tools!** ☁️🔧
