# Import 操作指南

## 前置条件

1. AWS SSO 登录
```bash
aws sso login --profile 151062088992_AdministratorAccess
```

2. 安装 Terraform >= 1.8.0

3. 克隆仓库
```bash
git clone https://github.com/bitget-wallet-ai-team/terraform-aws-live-eks.git
cd terraform-aws-live-eks
```

## 导入顺序

```
network → security → storage → ingress → eks → compute
```

## 快速开始

### Step 1: 发现资源

```bash
cd scripts
chmod +x *.sh
./discover-resources.sh
```

### Step 2: 导入 Network Stack

```bash
./import-network.sh
```

按提示逐步导入 VPC 及其依赖资源。

### Step 3: 验证并提交

```bash
cd envs/test/ops/stacks/network
terraform plan  # 应该显示 No changes

# 提交到 git
git add -A
git commit -m "Import network stack resources"
git push origin main
```

## Import 记录表

| Stack | 资源 | 资源ID | Import命令 | 执行日期 | Plan结果 |
|-------|------|--------|-----------|----------|----------|
| network | VPC | vpc-xxx | `terraform import module.vpc.aws_vpc.this vpc-xxx` | | |
| network | IGW | igw-xxx | `terraform import module.vpc.aws_internet_gateway.this igw-xxx` | | |
| network | Subnet | subnet-xxx | `terraform import module.vpc.aws_subnet.public[0] subnet-xxx` | | |
| eks | Cluster | test-ops | `terraform import module.eks.aws_eks_cluster.this test-ops` | | |

## 注意事项

1. **必须先备份 state** - 脚本会自动备份
2. **逐个确认** - 每个 import 都需要手动确认
3. **验证 plan** - import 后必须执行 plan 确认无变更
4. **注意索引** - 子网和 NAT Gateway 使用数组索引
5. **区分 public/private** - 根据 MapPublicIpOnLaunch 判断
