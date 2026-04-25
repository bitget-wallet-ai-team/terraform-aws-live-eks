# 资源归属矩阵

## Stack 职责边界

| Stack | 负责资源 | 不负责的边界 |
|-------|----------|--------------|
| **network** | VPC, Subnets, IGW, NAT Gateway, Route Tables | 安全组规则 |
| **security** | 共享基础安全组, 基础 IAM 角色 | 应用专属 SG, EKS/ALB 专属 SG |
| **storage** | 基础设施 S3 buckets, 加密/版本控制 | 应用业务 bucket |
| **ingress** | ALB, Target Groups, Listeners, ALB SG | EKS Service/Ingress 资源 |
| **eks** | EKS Cluster, Node Groups, Cluster SG, OIDC | 业务 Namespace, Service |
| **compute** | EC2, Launch Template, ASG, EC2 SG | 容器工作负载 |

## 资源归属详细表

### Network Stack

| 资源类型 | 资源示例 | 归属 |
|----------|----------|------|
| aws_vpc | test-ops-network | network |
| aws_subnet | public/private subnets | network |
| aws_internet_gateway | test-ops-network-igw | network |
| aws_nat_gateway | test-ops-network-nat | network |
| aws_route_table | public/private RT | network |
| aws_vpc_endpoint | S3/EC2 endpoints | network |

### Security Stack

| 资源类型 | 资源示例 | 归属 |
|----------|----------|------|
| aws_security_group | shared-bastion-sg | security |
| aws_security_group_rule | shared rules | security |
| aws_iam_role | shared-ops-role | security |

**注意**: 以下资源**不归** security stack：
- EKS Cluster SG → eks stack
- ALB SG → ingress stack
- EC2 App SG → compute stack

### Storage Stack

| 资源类型 | 资源示例 | 归属 |
|----------|----------|------|
| aws_s3_bucket | terraform-state-* | storage |
| aws_s3_bucket_versioning | state bucket | storage |
| aws_s3_bucket_encryption | state bucket | storage |

### Ingress Stack

| 资源类型 | 资源示例 | 归属 |
|----------|----------|------|
| aws_lb | test-ops-alb | ingress |
| aws_lb_target_group | test-ops-tg-* | ingress |
| aws_lb_listener | HTTP/HTTPS listeners | ingress |
| aws_security_group | alb-sg | ingress |

### EKS Stack

| 资源类型 | 资源示例 | 归属 |
|----------|----------|------|
| aws_eks_cluster | test-ops | eks |
| aws_eks_node_group | default-node-group | eks |
| aws_iam_role | cluster/node-group roles | eks |
| aws_iam_openid_connect_provider | oidc-provider | eks |
| aws_security_group | cluster-sg, node-sg | eks |

### Compute Stack

| 资源类型 | 资源示例 | 归属 |
|----------|----------|------|
| aws_instance | app servers | compute |
| aws_launch_template | app-lt | compute |
| aws_autoscaling_group | app-asg | compute |
| aws_security_group | app-sg | compute |

## 跨 Stack 引用

通过 `terraform_remote_state` 传递：

```
network ──[vpc_id, subnet_ids]──▶ eks
network ──[vpc_id, subnet_ids]──▶ ingress
network ──[vpc_id, subnet_ids]──▶ compute
```

禁止：
- ❌ 直接引用其他 stack 的资源定义
- ❌ 一个资源被多个 stack 管理
