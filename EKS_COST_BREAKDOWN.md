# EKS Cluster Cost Breakdown - t3.small

## 💰 Monthly Cost Estimate

### **Configuration:**
- **Instance Type**: t3.small (2 vCPU, 2 GB RAM)
- **Nodes**: 2 nodes (can scale 1-3)
- **Disk**: 20 GB gp3 per node
- **Region**: us-east-2 (Ohio)

---

## 📊 Cost Breakdown

### **1. EKS Control Plane**
```
$0.10 per hour × 730 hours = $73.00/month
```
- This is the Kubernetes control plane (managed by AWS)
- Fixed cost regardless of node count
- Includes high availability across 3 AZs

### **2. EC2 Worker Nodes (t3.small)**
```
Price per instance: $0.0208 per hour (us-east-2)
2 nodes × $0.0208 × 730 hours = $30.37/month
```
- **Why t3.small?**
  - Cheapest option that actually works for real workloads
  - t3.micro (1 vCPU, 1 GB) is too small for Kubernetes
  - t3.small provides good balance for learning

### **3. EBS Storage (gp3)**
```
20 GB × 2 nodes = 40 GB
$0.08 per GB-month × 40 GB = $3.20/month
```
- gp3 is cheaper and faster than gp2
- 20 GB is minimum for EKS nodes

### **4. Data Transfer**
```
Estimated: $1-3/month (minimal for dev)
```
- IN: FREE
- OUT to internet: $0.09 per GB
- Between AZs: $0.01 per GB

### **5. CloudWatch Logs**
```
Estimated: ~$0.50/month
```
- Control plane logs (7-day retention)
- Application logs (if using CloudWatch)

### **6. KMS Key (for encryption)**
```
$1/month per key
```
- Used to encrypt Kubernetes secrets

### **7. NAT Gateway (from VPC)**
```
$0.045 per hour × 730 hours = $32.85/month
$0.045 per GB processed (varies)
```
- This is for VPC (already counted earlier)
- Needed for nodes to pull images from ECR

---

## 🎯 Total Monthly Cost

| Component | Cost |
|-----------|------|
| EKS Control Plane | $73.00 |
| 2x t3.small nodes | $30.37 |
| 40 GB EBS (gp3) | $3.20 |
| CloudWatch Logs | $0.50 |
| KMS Key | $1.00 |
| Data Transfer | $2.00 |
| **TOTAL** | **~$110/month** |

**Plus VPC costs from earlier:**
- NAT Gateway: ~$35/month
- VPC Flow Logs: ~$1/month

**Grand Total: ~$146/month**

---

## 💡 Cost Optimization Strategies

### **For Learning (What We're Doing):**
✅ t3.small nodes (cheapest viable option)  
✅ 2 nodes minimum (for high availability testing)  
✅ Auto-scaling 1-3 (can scale down to 1 when not in use)  
✅ 20 GB disk (minimum needed)  
✅ Single NAT Gateway (not HA, but cheaper)  
✅ 7-day log retention (not months)  

### **To Save Even More:**
```
Manual Shutdown Strategy:
- Scale nodes to 0 when not using: SAVE $30/month
- Can't stop EKS control plane (always $73/month)
- Would need to scale back up to use cluster

Weekend Shutdown:
- If you stop cluster Friday-Monday:
  - Node costs: $30.37 × 0.57 = ~$17/month
  - Save ~$13/month
```

### **Cheaper Alternatives for Learning:**

1. **KIND (Kubernetes in Docker)**
   - Cost: $0 (runs locally)
   - Limitations: Not "real" AWS, no cloud integrations
   
2. **Minikube**
   - Cost: $0 (runs locally)
   - Limitations: Single node, not production-like

3. **EKS Fargate** (serverless)
   - Control Plane: $73/month
   - Per pod: $0.04048 per vCPU/hour + $0.004445 per GB/hour
   - Good for: Bursty workloads
   - Bad for: Always-on apps (more expensive than EC2)

4. **Use EKS for interview prep, then delete**
   - Create cluster when needed
   - Practice for a few hours
   - Delete everything
   - Cost: ~$5-10 per practice session

---

## 📈 Comparison with Other Sizes

| Instance Type | vCPU | RAM | Price/hour | Monthly (2 nodes) | Use Case |
|---------------|------|-----|------------|-------------------|----------|
| t3.micro      | 2    | 1 GB| $0.0104    | $15.18           | Too small for K8s |
| **t3.small**  | 2    | 2 GB| $0.0208    | **$30.37**       | **Best for learning** |
| t3.medium     | 2    | 4 GB| $0.0416    | $60.74           | Comfortable dev |
| t3.large      | 2    | 8 GB| $0.0832    | $121.47          | Small prod |
| t3.xlarge     | 4    | 16 GB| $0.1664   | $242.94          | Production |

**Why not t3.micro?**
- Kubernetes itself uses ~600-800 MB RAM
- System pods (CoreDNS, kube-proxy, etc.) use ~300 MB
- Leaves only ~100 MB for your app (not enough!)

**Why t3.small is perfect:**
- 2 GB RAM → ~1 GB available for apps
- Can run 2-3 small Spring Boot apps
- Enough to demonstrate CI/CD for interview

---

## 🎓 Interview Talking Points

**Q: How do you optimize EKS costs?**

*"I use **t3.small instances** for development, which provide 2 vCPU and 2 GB RAM at $0.0208/hour. I enable **auto-scaling** (min 1, max 3) so nodes scale down during off-hours. For storage, I use **gp3 EBS volumes** instead of gp2 for better price-performance. I also configure **7-day log retention** instead of indefinite to reduce CloudWatch costs. For production, I'd implement **Cluster Autoscaler** and **Karpenter** for better bin-packing and spot instance support."*

**Q: What's the minimum viable EKS setup?**

*"The minimum is **1 t3.small node**, but I prefer **2 nodes** for high availability and zero-downtime deployments. The control plane costs $73/month regardless of size, so the incremental cost of a second node is just $15. This allows for rolling updates and node maintenance without downtime."*

**Q: How would you reduce this cost in production?**

*"I'd use **Spot Instances** for non-critical workloads (70% cost savings), implement **Karpenter** for intelligent node provisioning, use **Fargate** for bursty workloads, enable **Cluster Autoscaler** to scale nodes based on demand, and consider **EKS Savings Plans** for committed usage. I'd also use **VPC Endpoints** instead of NAT Gateway to reduce data transfer costs for AWS service access."*

---

## ⚠️ Important Notes

1. **EKS Control Plane Cannot Be Stopped**
   - Even if you scale nodes to 0, you still pay $73/month
   - To fully stop charges, you must delete the cluster

2. **First Month Might Be Higher**
   - AWS Free Tier doesn't cover EKS
   - Some EBS free tier might apply (30 GB/month for 12 months)

3. **Monitor Your Costs**
   - Enable AWS Cost Explorer
   - Set up billing alerts
   - Use tags (we already have them!) to track costs

4. **Cleanup is Important**
   - Don't forget to delete when done practicing
   - LoadBalancers created by K8s must be deleted manually first
   - EBS volumes created by pods must be deleted

---

Ready to deploy? This will cost ~$110/month while active! 🚀
