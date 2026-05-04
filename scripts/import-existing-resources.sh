#!/bin/bash
# import-existing-resources.sh - 导入现网资源
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "========================================"
echo "Import 现网 AWS 资源"
echo "Account: $(aws sts get-caller-identity --query Account --output text)"
echo "========================================"
echo ""

# 检查 AWS 凭证
echo "检查 AWS 凭证..."
aws sts get-caller-identity > /dev/null 2>&1 || {
    echo "Error: AWS 凭证无效"
    exit 1
}
echo "✓ AWS 凭证有效"
echo ""

# ========================================
# NETWORK STACK IMPORT
# ========================================
echo "========================================"
echo "NETWORK STACK IMPORT"
echo "========================================"
echo ""

NETWORK_DIR="$REPO_ROOT/envs/test/ops/stacks/network"
cd "$NETWORK_DIR"

echo "Step 1: 初始化 Terraform (remote S3 backend)..."
terraform init -backend-config=backend.hcl -backend-config=backend.local

echo ""
echo "Step 2: 备份当前 state..."
terraform state pull > "$REPO_ROOT/backup-network-$(date +%Y%m%d-%H%M%S).tfstate" 2>/dev/null || echo "No existing state"

echo ""
echo "Step 3: Import VPC..."
echo "VPC ID: vpc-00bf986ffca53c8c1"
terraform import module.vpc.aws_vpc.this vpc-00bf986ffca53c8c1
echo "✓ VPC 导入完成"

echo ""
echo "Step 4: Import Internet Gateway..."
echo "IGW ID: igw-077404611faa31ec6"
terraform import module.vpc.aws_internet_gateway.this igw-077404611faa31ec6
echo "✓ IGW 导入完成"

echo ""
echo "Step 5: Import NAT Gateway..."
echo "NAT ID: nat-0e751a309621b4757"
terraform import 'module.vpc.aws_nat_gateway.this[0]' nat-0e751a309621b4757
echo "✓ NAT Gateway 导入完成"

echo ""
echo "Step 6: Import Elastic IP..."
echo "EIP Allocation ID: eipalloc-06d1d533fe0e67004"
terraform import 'module.vpc.aws_eip.nat[0]' eipalloc-06d1d533fe0e67004
echo "✓ Elastic IP 导入完成"

echo ""
echo "Step 7: Import Subnets..."
echo "导入 Public Subnets..."

# Public subnets (名称含 public)
terraform import 'module.vpc.aws_subnet.public[0]' subnet-0830a050965bb18e9
echo "✓ Public Subnet [0] 导入完成 (subnet-0830a050965bb18e9)"

terraform import 'module.vpc.aws_subnet.public[1]' subnet-0b1a28a213f2427eb
echo "✓ Public Subnet [1] 导入完成 (subnet-0b1a28a213f2427eb)"

echo ""
echo "导入 Private Subnets..."
terraform import 'module.vpc.aws_subnet.private[0]' subnet-05ae3ba1693c5e037
echo "✓ Private Subnet [0] 导入完成 (subnet-05ae3ba1693c5e037 - nat-gateway)"

terraform import 'module.vpc.aws_subnet.private[1]' subnet-0a50ee011a48f6e54
echo "✓ Private Subnet [1] 导入完成 (subnet-0a50ee011a48f6e54 - server-igw-a)"

terraform import 'module.vpc.aws_subnet.private[2]' subnet-071974a11d7e4a6f5
echo "✓ Private Subnet [2] 导入完成 (subnet-071974a11d7e4a6f5 - server-igw-c)"

terraform import 'module.vpc.aws_subnet.private[3]' subnet-00bbd65570e45ae0b
echo "✓ Private Subnet [3] 导入完成 (subnet-00bbd65570e45ae0b - egress-alb-a)"

terraform import 'module.vpc.aws_subnet.private[4]' subnet-0a9862879288f982b
echo "✓ Private Subnet [4] 导入完成 (subnet-0a9862879288f982b - egress-alb-c)"

terraform import 'module.vpc.aws_subnet.private[5]' subnet-0106f2a513b0c212d
echo "✓ Private Subnet [5] 导入完成 (subnet-0106f2a513b0c212d - bgw-infra-1a)"

terraform import 'module.vpc.aws_subnet.private[6]' subnet-054fe4e7d3724df28
echo "✓ Private Subnet [6] 导入完成 (subnet-054fe4e7d3724df28 - bgw-infra-1c)"

terraform import 'module.vpc.aws_subnet.private[7]' subnet-070bcd20a6278ec44
echo "✓ Private Subnet [7] 导入完成 (subnet-070bcd20a6278ec44 - endpoint-c)"

terraform import 'module.vpc.aws_subnet.private[8]' subnet-0ad68e49bf60d36ac
echo "✓ Private Subnet [8] 导入完成 (subnet-0ad68e49bf60d36ac - endpoint-a)"

echo ""
echo "Step 8: 验证 Network Plan..."
terraform plan -detailed-exitcode || EXIT_CODE=$?
if [ "${EXIT_CODE:-0}" -eq 2 ]; then
    echo "⚠ Plan 显示有变更，可能需要调整配置"
elif [ "${EXIT_CODE:-0}" -eq 0 ]; then
    echo "✓ No changes. Infrastructure is up-to-date."
fi

echo ""
echo "========================================"
echo "NETWORK STACK IMPORT 完成"
echo "========================================"
echo ""

# ========================================
# EKS STACK IMPORT
# ========================================
echo "========================================"
echo "EKS STACK IMPORT"
echo "========================================"
echo ""

EKS_DIR="$REPO_ROOT/envs/test/ops/stacks/eks"
cd "$EKS_DIR"

echo "Step 1: 初始化 Terraform (remote S3 backend)..."
terraform init -backend-config=backend.hcl -backend-config=../network/backend.local

echo ""
echo "Step 2: 备份当前 state..."
terraform state pull > "$REPO_ROOT/backup-eks-$(date +%Y%m%d-%H%M%S).tfstate" 2>/dev/null || echo "No existing state"

echo ""
echo "Step 3: Import EKS Cluster..."
echo "Cluster: bgw-infra-eks-01"
terraform import module.eks.aws_eks_cluster.this bgw-infra-eks-01
echo "✓ EKS Cluster 导入完成"

echo ""
echo "Step 4: Import IAM Roles..."
echo "Cluster Role: AmazonEKSAutoClusterRole"
terraform import module.eks.aws_iam_role.cluster AmazonEKSAutoClusterRole
echo "✓ Cluster Role 导入完成"

echo ""
echo "Node Group Role: bgw-eks-node-role-test"
terraform import module.eks.aws_iam_role.node_group bgw-eks-node-role-test
echo "✓ Node Group Role 导入完成"

echo ""
echo "Step 5: Import Node Group..."
echo "Node Group: bgw-infra-ec2-group"
terraform import 'module.eks.aws_eks_node_group.this["bgw-infra-ec2-group"]' 'bgw-infra-eks-01:bgw-infra-ec2-group'
echo "✓ Node Group 导入完成"

echo ""
echo "Step 6: Import OIDC Provider..."
echo "OIDC ARN: arn:aws:iam::151062088992:oidc-provider/oidc.eks.ap-northeast-1.amazonaws.com/id/5B1E681C88E9BF64FC446C79C9C8EF5F"
terraform import 'module.eks.aws_iam_openid_connect_provider.this[0]' 'arn:aws:iam::151062088992:oidc-provider/oidc.eks.ap-northeast-1.amazonaws.com/id/5B1E681C88E9BF64FC446C79C9C8EF5F'
echo "✓ OIDC Provider 导入完成"

echo ""
echo "Step 7: 验证 EKS Plan..."
terraform plan -detailed-exitcode || EXIT_CODE=$?
if [ "${EXIT_CODE:-0}" -eq 2 ]; then
    echo "⚠ Plan 显示有变更，可能需要调整配置"
elif [ "${EXIT_CODE:-0}" -eq 0 ]; then
    echo "✓ No changes. Infrastructure is up-to-date."
fi

echo ""
echo "========================================"
echo "EKS STACK IMPORT 完成"
echo "========================================"
echo ""

# 返回根目录
cd "$REPO_ROOT"

echo "Import 摘要:"
echo "- Network Stack: vpc-00bf986ffca53c8c1 及子网/IGW/NAT"
echo "- EKS Stack: bgw-infra-eks-01 及节点组"
echo ""
echo "下一步:"
echo "1. 检查 plan 输出，确认无意外变更"
echo "2. 保持远程 S3 backend 作为唯一共享 state 来源"
echo "3. 如需调整 backend 参数，仅修改未提交的 backend.local 覆盖文件"
