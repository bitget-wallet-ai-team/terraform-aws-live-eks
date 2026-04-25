# 架构设计

## 总体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ terraform-  │  │ terraform-  │  │   terraform-drift   │  │
│  │   plan.yml  │  │  apply.yml  │  │      .yml           │  │
│  └──────┬──────┘  └──────┬──────┘  └─────────────────────┘  │
│         │                │                                   │
│         ▼                ▼                                   │
│  ┌─────────────┐  ┌─────────────┐                            │
│  │  PR Plan    │  │ Merge Apply │                            │
│  │  (自动)     │  │ (审批后)    │                            │
│  └─────────────┘  └─────────────┘                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      AWS Account (test)                      │
│                                                              │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│   │   Network   │───▶│   Security  │───▶│   Storage   │     │
│   │   (VPC)     │    │    (SG)     │    │   (S3)      │     │
│   └─────────────┘    └─────────────┘    └─────────────┘     │
│          │                                        │          │
│          ▼                                        ▼          │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│   │   Ingress   │◀───│     EKS     │◀───│   Compute   │     │
│   │   (ALB)     │    │  (Cluster)  │    │  (EC2/ASG)  │     │
│   └─────────────┘    └─────────────┘    └─────────────┘     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Stack 依赖关系

```
network (底层，无依赖)
    │
    ├──▶ security
    │       │
    │       ├──▶ storage
    │       │
    │       └──▶ ingress ──▶ eks ──▶ compute
    │
    └──▶ (所有 stack 都依赖 network)
```

## 执行顺序

从底层到上层：

1. **network** - VPC, Subnets, IGW, NAT
2. **security** - Shared Security Groups
3. **storage** - S3 Buckets
4. **ingress** - ALB
5. **eks** - EKS Cluster, Node Groups
6. **compute** - EC2, ASG

## 状态管理

```
S3 Bucket: terraform-state-<account-id>
├── test/
│   └── ops/
│       ├── network/terraform.tfstate
│       ├── security/terraform.tfstate
│       ├── storage/terraform.tfstate
│       ├── ingress/terraform.tfstate
│       ├── eks/terraform.tfstate
│       └── compute/terraform.tfstate
```

## 权限模型

| 角色 | 用途 | 权限 |
|------|------|------|
| `OpsPlanRole` | PR Plan | 只读 + Plan |
| `OpsApplyRole` | Merge Apply | 读写 + Apply |
| `TerraformImportOpsRole` | Import | 扩展只读 + Import |

## 模块治理

```
modules/ (平台团队维护)
├── network/vpc/           # VPC 模块
├── security/              # 安全组模块
├── eks/cluster/           # EKS 模块
├── ingress/alb/           # ALB 模块
├── storage/s3_bucket/     # S3 模块
├── compute/ec2_asg/       # EC2 模块
└── shared/                # 共享工具
    ├── tags/              # 标签模块
    └── naming/            # 命名模块
```

工程师只能：
- 修改 `envs/<env>/ops/stacks/<stack>/terraform.tfvars`
- 调整 root module 的参数传递

禁止直接修改 `modules/` 目录。

## GitHub OIDC 认证

```
GitHub Actions ──OIDC──▶ AWS STS ──▶ Assume Role
                              │
                              ▼
                    ┌─────────────────┐
                    │  OpsPlanRole    │ (PR Plan)
                    │  OpsApplyRole   │ (Merge Apply)
                    │  ImportOpsRole  │ (Import)
                    └─────────────────┘
```

## Drift 检测

定时任务（每日 UTC 02:00）：
- 遍历所有 stack
- 执行 `terraform plan -detailed-exitcode`
- 检测到 drift 时创建 GitHub Issue
