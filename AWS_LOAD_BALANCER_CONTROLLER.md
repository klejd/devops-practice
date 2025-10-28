# AWS Load Balancer Controller Setup

## Overview
The AWS Load Balancer Controller manages AWS Elastic Load Balancers (ALB/NLB) for your Kubernetes cluster. It watches for Ingress resources and automatically provisions Application Load Balancers.

## What We've Done (Terraform)

✅ Created IAM policy with all required permissions for the controller
✅ Created IAM role using IRSA (IAM Roles for Service Accounts)
✅ Role can be assumed by the `aws-load-balancer-controller` service account in the `kube-system` namespace

## Installation Methods

### Method 1: Helm (Recommended) ✨

The AWS Load Balancer Controller is installed via Helm chart, not as an EKS add-on.

#### Prerequisites
- kubectl configured to connect to your cluster
- Helm 3 installed

#### Installation Steps

1. **Configure kubectl** (if not done already):
```bash
aws eks update-kubeconfig --region us-east-2 --name dev-eks-cluster
```

2. **Add the EKS Helm repository**:
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

3. **Install the AWS Load Balancer Controller**:
```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=dev-eks-cluster \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<LOAD_BALANCER_CONTROLLER_ROLE_ARN>
```

**Note**: Replace `<LOAD_BALANCER_CONTROLLER_ROLE_ARN>` with the actual ARN from Terraform outputs:
```bash
terraform output aws_load_balancer_controller_role_arn
```

4. **Verify Installation**:
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller
```

### Method 2: kubectl + YAML Manifests

Alternatively, you can install using raw Kubernetes manifests:

1. Download the controller manifest:
```bash
curl -Lo v2_8_0_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.8.0/v2_8_0_full.yaml
```

2. Edit the manifest to:
   - Set `--cluster-name=dev-eks-cluster`
   - Remove the ServiceAccount creation section (Terraform creates this via IRSA)
   - Add the IAM role annotation

3. Apply the manifest:
```bash
kubectl apply -f v2_8_0_full.yaml
```

## How It Works

### IRSA (IAM Roles for Service Accounts)
- The controller runs as a pod with a Kubernetes service account
- The service account is annotated with the IAM role ARN
- When the pod makes AWS API calls, it assumes the IAM role
- No need for hardcoded AWS credentials!

### What It Does
1. **Watches Ingress Resources**: Monitors Kubernetes Ingress objects
2. **Provisions ALBs**: Automatically creates Application Load Balancers
3. **Configures Target Groups**: Sets up ALB target groups pointing to your pods
4. **Manages Security Groups**: Creates and manages security groups for the ALB
5. **Updates Routes**: Configures ALB listener rules based on Ingress annotations

## Example Ingress Resource

Once installed, you can create an Ingress to get an ALB:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  namespace: default
  annotations:
    # This tells it to use the AWS Load Balancer Controller
    kubernetes.io/ingress.class: alb
    
    # ALB will be internet-facing
    alb.ingress.kubernetes.io/scheme: internet-facing
    
    # Use IP targets (required for Fargate, recommended for EC2)
    alb.ingress.kubernetes.io/target-type: ip
    
    # Health check settings
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    
    # Optional: SSL certificate ARN for HTTPS
    # alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-2:ACCOUNT:certificate/CERT_ID
    
    # Optional: Listen on HTTPS
    # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    
    # Optional: Redirect HTTP to HTTPS
    # alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  rules:
  - host: api.example.com  # Optional: specify hostname
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-service
            port:
              number: 8080
```

## Important Annotations

### Common ALB Configurations

| Annotation | Purpose | Example |
|------------|---------|---------|
| `alb.ingress.kubernetes.io/scheme` | Internal or internet-facing | `internet-facing` or `internal` |
| `alb.ingress.kubernetes.io/target-type` | How to route to pods | `ip` (recommended) or `instance` |
| `alb.ingress.kubernetes.io/certificate-arn` | SSL certificate | ARN from ACM |
| `alb.ingress.kubernetes.io/listen-ports` | Ports to listen on | `[{"HTTP": 80}, {"HTTPS": 443}]` |
| `alb.ingress.kubernetes.io/ssl-redirect` | Redirect HTTP to HTTPS | `443` |
| `alb.ingress.kubernetes.io/subnets` | Which subnets to use | Subnet IDs (comma-separated) |
| `alb.ingress.kubernetes.io/tags` | AWS tags for the ALB | `Environment=dev,Team=platform` |
| `alb.ingress.kubernetes.io/load-balancer-attributes` | ALB attributes | `idle_timeout.timeout_seconds=60` |

### Health Check Configurations

| Annotation | Purpose | Example |
|------------|---------|---------|
| `alb.ingress.kubernetes.io/healthcheck-path` | Health check endpoint | `/health` or `/actuator/health` |
| `alb.ingress.kubernetes.io/healthcheck-protocol` | Protocol for health checks | `HTTP` or `HTTPS` |
| `alb.ingress.kubernetes.io/healthcheck-port` | Port for health checks | `traffic-port` (default) |
| `alb.ingress.kubernetes.io/healthcheck-interval-seconds` | Check interval | `15` |
| `alb.ingress.kubernetes.io/healthcheck-timeout-seconds` | Timeout | `5` |
| `alb.ingress.kubernetes.io/healthy-threshold-count` | Healthy threshold | `2` |
| `alb.ingress.kubernetes.io/unhealthy-threshold-count` | Unhealthy threshold | `2` |

## Subnet Tagging Requirements

For the controller to discover subnets automatically, they must be tagged:

**Public subnets** (for internet-facing ALBs):
```
kubernetes.io/role/elb = 1
```

**Private subnets** (for internal ALBs):
```
kubernetes.io/role/internal-elb = 1
```

✅ **Good news**: Our VPC module already adds these tags! Check `terraform/modules/vpc/main.tf`.

## Security Considerations

1. **IAM Role Scoping**: The IAM policy allows the controller to create/modify load balancers and security groups
2. **Network Security**: ALBs created will be in public subnets with security groups allowing HTTP/HTTPS
3. **Pod Security**: Target pods should have proper security contexts and network policies
4. **SSL/TLS**: Use ACM certificates and enforce HTTPS for production

## Costs

**ALB Pricing** (us-east-2):
- **Fixed**: ~$16.20/month per ALB (730 hours × $0.0225/hour)
- **LCU-based**: Variable based on:
  - New connections/sec
  - Active connections
  - Processed bytes
  - Rule evaluations

**Estimated Monthly Cost**:
- 1 ALB with light traffic: ~$18-25/month
- 1 ALB with moderate traffic: ~$30-50/month

**Cost Optimization**:
- Share one ALB across multiple Ingress resources (use different paths/hosts)
- Use IngressGroup to group Ingresses on the same ALB
- Example:
  ```yaml
  alb.ingress.kubernetes.io/group.name: shared-alb
  ```

## Next Steps After Installation

1. ✅ Verify controller is running
2. ✅ Create a test Ingress resource
3. ✅ Check ALB creation in AWS Console
4. ✅ Test connectivity to your application
5. ✅ Configure SSL/TLS certificate (optional)
6. ✅ Set up DNS (Route53 or other)
7. ✅ Configure monitoring and logging

## Troubleshooting

### Check controller logs:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Check Ingress events:
```bash
kubectl describe ingress <ingress-name>
```

### Common Issues:

1. **Pods not getting traffic**:
   - Check target-type is set to `ip`
   - Verify pod security groups allow inbound traffic
   - Check pod readiness probes

2. **ALB not created**:
   - Verify controller is running
   - Check IAM role permissions
   - Verify subnet tags

3. **Health checks failing**:
   - Verify health check path exists
   - Check pod health endpoint responds with 200
   - Verify security group rules

## References

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Ingress Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.8/guide/ingress/annotations/)
- [ALB Pricing](https://aws.amazon.com/elasticloadbalancing/pricing/)
