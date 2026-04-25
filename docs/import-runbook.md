# Import Runbook - 存量资源接管手册

## 总体原则

1. **按 stack 分批导入** - 不要一次性导入所有资源
2. **从底层到上层** - network → security → storage → ingress → eks → compute
3. **先接管，再优化** - 导入后先确保 plan = no changes，再考虑优化
4. **禁止边导入边大改** - 导入阶段只接管，不重构

## 导入顺序

```
network → security → storage → ingress → eks → compute
```

## Import 流程

### 步骤 1: 明确归属

确认资源归属哪个 stack。例如：
- VPC → `envs/test/ops/stacks/network`
- EKS Cluster → `envs/test/ops/stacks/eks`
- ALB → `envs/test/ops/stacks/ingress`

### 步骤 2: 编写 Terraform 配置

先完成目标 stack 的 Terraform 配置，参数尽量接近现网：

```bash
cd envs/test/ops/stacks/network

# 编辑 main.tf, variables.tf, terraform.tfvars
# 确保配置与现网资源属性一致
```

### 步骤 3: 执行 Import

**重要**: Import 需要专用角色 `TerraformImportOpsRole`，需平台管理员审批

```bash
# 使用脚本执行（推荐）
../../scripts/terraform_import.sh \
  envs/test/ops/stacks/network \
  module.vpc.aws_vpc.this \
  vpc-xxxxxxxxxxxxxxxxx

# 或手动执行
cd envs/test/ops/stacks/network
terraform init -backend-config=backend.hcl
terraform import module.vpc.aws_vpc.this vpc-xxxxxxxxxxxxxxxxx
```

### 步骤 4: 逐个导入依赖资源

按依赖顺序逐个导入：

```bash
# VPC 子网
terraform import module.vpc.aws_subnet.public[0] subnet-xxxxxxxxxxxxxxxxx
terraform import module.vpc.aws_subnet.public[1] subnet-yyyyyyyyyyyyyyyyy
terraform import module.vpc.aws_subnet.private[0] subnet-zzzzzzzzzzzzzzzzz

# IGW
terraform import module.vpc.aws_internet_gateway.this igw-xxxxxxxxxxxxxxxxx

# NAT Gateway
terraform import module.vpc.aws_nat_gateway.this[0] nat-xxxxxxxxxxxxxxxxx
terraform import module.vpc.aws_eip.nat[0] eipalloc-xxxxxxxxxxxxxxxxx

# Route Tables
terraform import module.vpc.aws_route_table.public rtb-xxxxxxxxxxxxxxxxx
terraform import module.vpc.aws_route_table.private[0] rtb-yyyyyyyyyyyyyyyyy
```

### 步骤 5: 验证 Plan

目标是达到 `No changes. Infrastructure is up-to-date.`

```bash
terraform plan
```

如果显示有变更，需要调整配置使其与现网一致。

## Import 记录模板

每次 Import 必须记录：

| 字段 | 值 |
|------|-----|
| 资源名称 | VPC |
| 资源 ID | vpc-xxxxxxxxxxxxxxxxx |
| 归属 Stack | envs/test/ops/stacks/network |
| Import 命令 | `terraform import module.vpc.aws_vpc.this vpc-xxxxxxxxxxxxxxxxx` |
| Import 后 Plan 结果 | No changes |
| 审核人 | @platform-admin |
| 执行人 | @ops-engineer |
| 日期 | 2024-XX-XX |

## 常见资源 Import 命令参考

### Network Stack

```bash
# VPC
terraform import module.vpc.aws_vpc.this vpc-xxx

# Subnets
terraform import module.vpc.aws_subnet.public[0] subnet-xxx
terraform import module.vpc.aws_subnet.private[0] subnet-xxx

# IGW
terraform import module.vpc.aws_internet_gateway.this igw-xxx

# NAT Gateway
terraform import module.vpc.aws_nat_gateway.this[0] nat-xxx
terraform import module.vpc.aws_eip.nat[0] eipalloc-xxx

# Route Tables
terraform import module.vpc.aws_route_table.public rtb-xxx
```

### EKS Stack

```bash
# EKS Cluster
terraform import module.eks.aws_eks_cluster.this test-ops

# IAM Roles
terraform import module.eks.aws_iam_role.cluster test-ops-cluster-role
terraform import module.eks.aws_iam_role.node_group test-ops-node-group-role

# OIDC Provider
terraform import module.eks.aws_iam_openid_connect_provider.this[0] arn:aws:iam::151062088992:oidc-provider/oidc.eks.ap-northeast-1.amazonaws.com/id/xxx

# Node Groups
terraform import module.eks.aws_eks_node_group.this[\"default\"] test-ops:default-node-group
```

## 注意事项

1. **Import 前必须备份 state**: `terraform state pull > backup.tfstate`
2. **Import 后必须验证 plan**: 确保无意外变更
3. **复杂资源分批导入**: 如 EKS，先 cluster，再 node groups，再 addons
4. **遇到问题及时回滚**: `terraform state push backup.tfstate`

## 审批流程

所有 Import 操作必须经过：

1. 运维工程师提交 Import 申请
2. 平台管理员审批
3. 使用专用 Import 角色执行
4. 执行后验证并记录
