# terraform-aws-live-eks

Terraform AWS Live Infrastructure - EKS Stack for Test Environment

## 设计原则

- **多 AWS 账号**: 按环境拆分 (当前仅 test)
- **CI/CD 唯一通道**: GitHub Actions 是唯一 apply 入口
- **资源边界固定**: 禁止跨 stack 共管同一资源
- **模块治理**: 平台团队统一提供模块，工程师只传参数

## 目录结构

```
terraform-aws-live-eks/
├── modules/                    # 平台团队维护的模块
│   ├── network/vpc/
│   ├── security/base_security_groups/
│   ├── compute/ec2_asg/
│   ├── eks/cluster/
│   ├── ingress/alb/
│   ├── storage/s3_bucket/
│   └── shared/{tags,naming}/
│
├── envs/test/ops/stacks/       # 可独立执行的 stack
│   ├── network/               # VPC, Subnets, IGW, NAT
│   ├── security/              # 共享基础安全组
│   ├── storage/               # S3 buckets
│   ├── ingress/               # ALB
│   ├── eks/                   # EKS cluster
│   └── compute/               # EC2/ASG
│
├── global/bootstrap/          # Bootstrap 基础设施
├── policies/                  # 安全策略 (checkov, tflint)
├── scripts/                   # 辅助脚本
└── .github/workflows/         # GitHub Actions
```

## Stack 依赖顺序

```
network → security → storage → ingress → eks → compute
```

## GitHub Actions 工作流

| 工作流 | 触发条件 | 说明 |
|--------|----------|------|
| `terraform-plan.yml` | PR 到 main | fmt/validate/tflint/checkov/plan |
| `terraform-apply.yml` | Merge 到 main | 人工审批后 apply |
| `terraform-drift.yml` | 定时 (每日) | Drift 检测并告警 |

## 变更流程

1. 工程师修改 `envs/test/ops/stacks/<stack>/terraform.tfvars`
2. 创建 PR，自动触发 plan
3. Code Review (CODEOWNERS 控制)
4. Merge 到 main
5. GitHub Environment 人工审批
6. Apply 执行

## 审批矩阵

| 目录 | 审批人 |
|------|--------|
| `/modules/` | platform-team |
| `/envs/test/ops/stacks/` | ops-team |
| `/envs/test/ops/stacks/eks/` | ops-team + platform-team |
| `/global/bootstrap/` | platform-admin |

## 禁止事项

1. ❌ 本地 `terraform apply`
2. ❌ 手工修改 AWS 资源
3. ❌ 直接修改 state 文件
4. ❌ 跨 stack 共管资源
5. ❌ 绕过审查直接 merge

## 存量资源 Import

见 `docs/import-runbook.md`

## 文档

- `docs/architecture.md` - 架构设计
- `docs/ownership-matrix.md` - 资源归属矩阵
- `docs/import-runbook.md` - Import 操作手册
- `docs/change-process.md` - 变更流程
