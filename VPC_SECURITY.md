# VPC Security with NAT Gateway

## 🔒 Security Model

### Network Topology
```
┌─────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                    │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Private Subnets (Where Your App Lives)         │  │
│  │  10.0.1.0/24 (AZ1) | 10.0.2.0/24 (AZ2)          │  │
│  │                                                  │  │
│  │  🔒 NO PUBLIC IP                                 │  │
│  │  🔒 NO INBOUND INTERNET ACCESS                   │  │
│  │  ✅ OUTBOUND INTERNET (via NAT)                  │  │
│  │                                                  │  │
│  │  Resources:                                      │  │
│  │  - EKS Worker Nodes (10.0.1.x)                   │  │
│  │  - Application Pods (10.0.1.y)                   │  │
│  │  - Databases (10.0.2.z)                          │  │
│  │                                                  │  │
│  │  Security Groups (Firewall):                     │  │
│  │  - Inbound: Only from Load Balancer              │  │
│  │  - Outbound: HTTPS, DNS                          │  │
│  └──────────────────┬───────────────────────────────┘  │
│                     │ (outbound only)                   │
│                     ▼                                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Public Subnets (Internet-Facing Resources)     │  │
│  │  10.0.101.0/24 (AZ1) | 10.0.102.0/24 (AZ2)      │  │
│  │                                                  │  │
│  │  Resources:                                      │  │
│  │  - NAT Gateway (one-way outbound proxy)          │  │
│  │  - Load Balancer (receives user traffic)         │  │
│  │                                                  │  │
│  └──────────────────┬───────────────────────────────┘  │
│                     │                                   │
│         ┌───────────▼──────────┐                        │
│         │  Internet Gateway    │                        │
│         └───────────┬──────────┘                        │
└─────────────────────┼────────────────────────────────────┘
                      │
                 ┌────▼─────┐
                 │ Internet │
                 └──────────┘
```

## 🛡️ Security Controls

### 1. Network Isolation
**Private Subnets (Your Application):**
- ❌ No public IP addresses
- ❌ No direct internet access
- ❌ Cannot be reached from internet
- ✅ Can make outbound requests via NAT

**Public Subnets:**
- Only NAT Gateway and Load Balancers
- No application servers

### 2. NAT Gateway Security
**How NAT Gateway Protects You:**

```
Outbound (ALLOWED):
Your App (10.0.1.50:random) → NAT Gateway
                            → Translates to Public IP
                            → Internet

Inbound (BLOCKED):
Internet → NAT Gateway → ❌ DROPPED (NAT doesn't route inbound)
```

**Key Point:** NAT Gateway does NOT accept inbound connections from internet!

### 3. Security Group Rules (Firewall)

**EKS Pod Security Group:**
```hcl
Inbound:
- Port 8080 from Load Balancer Security Group ONLY
- NO public internet access

Outbound:
- Port 443 (HTTPS) to 0.0.0.0/0  # Pull Docker images, call APIs
- Port 53 (DNS) to 0.0.0.0/0     # DNS resolution
```

**Load Balancer Security Group:**
```hcl
Inbound:
- Port 80/443 from 0.0.0.0/0  # Users can access

Outbound:
- Port 8080 to EKS Pod Security Group  # Forward to app
```

### 4. Defense in Depth

```
Attack Vector: Hacker trying to reach your app

Layer 1 - Routing ❌
└─ No route exists from internet to private subnet
   (Private subnet route table only has route to NAT, not FROM NAT)

Layer 2 - No Public IP ❌
└─ Your pods have 10.0.1.x (private, non-routable from internet)

Layer 3 - Security Groups ❌
└─ Inbound rules ONLY allow traffic from Load Balancer

Layer 4 - Network ACLs ❌
└─ Subnet-level firewall blocks unexpected sources

Layer 5 - Application Security ✅
└─ Even if someone got through, app has authentication/authorization
```

## 📊 Traffic Examples

### ✅ Scenario 1: User Accesses Your App
```
1. User (1.2.3.4) → HTTPS → Load Balancer (public subnet)
2. Load Balancer → Port 8080 → EKS Pod (private subnet)
3. EKS Pod → Response → Load Balancer
4. Load Balancer → Response → User

✅ ALLOWED: Load Balancer has security group rule allowing this
```

### ✅ Scenario 2: Your App Pulls Docker Image
```
1. EKS Pod (10.0.1.50) → "Need image from ECR"
2. EKS Pod → NAT Gateway (public subnet)
3. NAT Gateway → Internet Gateway → ECR
4. ECR → Returns image → NAT Gateway
5. NAT Gateway → EKS Pod

✅ ALLOWED: Outbound through NAT is permitted
```

### ❌ Scenario 3: Hacker Tries Direct Access
```
1. Hacker (6.6.6.6) → Tries to connect to 10.0.1.50
2. Internet → Internet Gateway
3. Internet Gateway → "10.0.1.50 is private IP, no route"
4. ❌ BLOCKED at routing layer

Even if they somehow got through:
5. Security Group → "Source 6.6.6.6 not allowed"
6. ❌ BLOCKED at firewall layer
```

### ❌ Scenario 4: Hacker Tries Via NAT Gateway
```
1. Hacker (6.6.6.6) → NAT Gateway Public IP
2. NAT Gateway → "I only route OUTBOUND traffic"
3. ❌ BLOCKED - NAT Gateway drops inbound connections
```

## 💰 Cost (Simplified Setup)

```
Monthly Infrastructure Costs:

NAT Gateway:
├─ Hourly charge: $0.045/hour × 730 hours = $32.85
├─ Data processing: $0.045/GB
└─ Total: ~$32-50/month (depending on data transfer)

Internet Gateway:
└─ FREE (no hourly charge, only data transfer)

Security Groups / NACLs:
└─ FREE
```

## 🎤 Interview Answer

**Q: How do you secure your VPC?**

*"I use a multi-layered security approach. My application runs in **private subnets** with no public IP addresses or direct internet access. For outbound connectivity—like pulling Docker images or calling APIs—I use a **NAT Gateway**, which only allows outbound connections and blocks all inbound internet traffic.*

*I implement **Security Groups** as stateful firewalls that only allow traffic from the Load Balancer to reach my application. The Load Balancer itself is in a **public subnet**, acting as the only internet-facing entry point.*

*This creates **defense in depth**: routing isolation, no public IPs, security group rules, and network ACLs all work together to prevent unauthorized access while still allowing my application to function."*

## 🔄 Comparison

| Feature | Private Subnet + NAT | Public Subnet |
|---------|---------------------|---------------|
| **Public IP** | ❌ No | ✅ Yes |
| **Direct Internet Access** | ❌ No | ✅ Yes |
| **Inbound from Internet** | ❌ Blocked | ✅ Allowed |
| **Outbound to Internet** | ✅ Via NAT | ✅ Direct |
| **Security** | 🔒 High | ⚠️ Medium |
| **Use Case** | Application servers | Load Balancers, NAT |

## 📚 Best Practices

1. ✅ **Always use private subnets for application workloads**
2. ✅ **Use Security Groups (not just NACLs)**
3. ✅ **Single NAT for dev** (cost), **Multi-NAT for prod** (HA)
4. ✅ **Enable VPC Flow Logs** for security monitoring
5. ✅ **Principle of least privilege** in security group rules
