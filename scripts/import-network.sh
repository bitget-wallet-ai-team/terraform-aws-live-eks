#!/bin/bash
# import-network.sh - Network Stack Import 脚本
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
STACK_DIR="${REPO_ROOT}/envs/test/ops/stacks/network"

echo "========================================"
echo "Network Stack Import"
echo "========================================"

# 检查 AWS 凭证
echo "Step 1: 检查 AWS 凭证..."
aws sts get-caller-identity > /dev/null 2>&1 || {
    echo "Error: AWS 凭证无效，请先执行: aws sso login --profile 151062088992_AdministratorAccess"
    exit 1
}
echo "✓ AWS 凭证有效"

# 发现 VPC
echo ""
echo "现有 VPC 列表:"
aws ec2 describe-vpcs --query 'Vpcs[].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table

echo ""
echo "请输入要导入的 VPC ID (例如: vpc-xxxxxxxxxxxxxxxxx):"
read -r VPC_ID

if [ -z "$VPC_ID" ]; then
    echo "Error: VPC ID 不能为空"
    exit 1
fi

# 获取详情
echo ""
echo "VPC 详情:"
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].[VpcId,CidrBlock,State]' --output table

echo ""
echo "子网:"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0],MapPublicIpOnLaunch]' \
    --output table

echo ""
echo "IGW:"
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[].[InternetGatewayId]' --output text

echo ""
echo "NAT Gateways:"
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" \
    --query 'NatGateways[].[NatGatewayId,SubnetId,State]' --output table

echo ""
echo "========================================"
echo "准备导入..."
echo "========================================"

cd "$STACK_DIR"

# 初始化
echo "Step 2: 初始化 Terraform..."
terraform init -backend-config=backend.hcl

# 备份
echo "Step 3: 备份 state..."
terraform state pull > "${REPO_ROOT}/backup-network-$(date +%Y%m%d-%H%M%S).tfstate" 2>/dev/null || echo "No existing state"

# Import VPC
echo ""
echo "Step 4: Import VPC..."
echo "terraform import module.vpc.aws_vpc.this $VPC_ID"
read -p "确认? (yes/no): " CONFIRM
if [ "$CONFIRM" = "yes" ]; then
    terraform import module.vpc.aws_vpc.this "$VPC_ID"
    echo "✓ VPC 导入完成"
fi

# Import IGW
echo ""
echo "Step 5: Import IGW..."
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[0].InternetGatewayId' --output text)
if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
    echo "IGW: $IGW_ID"
    echo "terraform import module.vpc.aws_internet_gateway.this $IGW_ID"
    read -p "确认? (yes/no): " CONFIRM
    if [ "$CONFIRM" = "yes" ]; then
        terraform import module.vpc.aws_internet_gateway.this "$IGW_ID"
        echo "✓ IGW 导入完成"
    fi
fi

# Import Subnets
echo ""
echo "Step 6: Import Subnets..."
echo "请根据 MapPublicIpOnLaunch 区分 public/private"

SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[].[SubnetId,MapPublicIpOnLaunch]' --output text)

echo "子网列表: $SUBNETS"

# Public subnets
echo ""
echo "导入 Public Subnets (MapPublicIpOnLaunch=True)..."
INDEX=0
echo "$SUBNETS" | while IFS=$'\t' read -r SUBNET_ID IS_PUBLIC; do
    if [ "$IS_PUBLIC" = "True" ]; then
        echo "Public[$INDEX]: $SUBNET_ID"
        echo "terraform import 'module.vpc.aws_subnet.public[$INDEX]' $SUBNET_ID"
        read -p "确认? (yes/no): " CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            terraform import "module.vpc.aws_subnet.public[$INDEX]" "$SUBNET_ID"
            echo "✓ Public Subnet [$INDEX] 导入完成"
        fi
        INDEX=$((INDEX + 1))
    fi
done

# Private subnets
echo ""
echo "导入 Private Subnets (MapPublicIpOnLaunch=False)..."
INDEX=0
echo "$SUBNETS" | while IFS=$'\t' read -r SUBNET_ID IS_PUBLIC; do
    if [ "$IS_PUBLIC" = "False" ]; then
        echo "Private[$INDEX]: $SUBNET_ID"
        echo "terraform import 'module.vpc.aws_subnet.private[$INDEX]' $SUBNET_ID"
        read -p "确认? (yes/no): " CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            terraform import "module.vpc.aws_subnet.private[$INDEX]" "$SUBNET_ID"
            echo "✓ Private Subnet [$INDEX] 导入完成"
        fi
        INDEX=$((INDEX + 1))
    fi
done

# Import NAT Gateways
echo ""
echo "Step 7: Import NAT Gateways..."
NAT_GWS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" \
    --query 'NatGateways[?State==`available`].[NatGatewayId]' --output text)
if [ -n "$NAT_GWS" ] && [ "$NAT_GWS" != "None" ]; then
    INDEX=0
    for NAT_GW_ID in $NAT_GWS; do
        echo "NAT[$INDEX]: $NAT_GW_ID"
        echo "terraform import 'module.vpc.aws_nat_gateway.this[$INDEX]' $NAT_GW_ID"
        read -p "确认? (yes/no): " CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            terraform import "module.vpc.aws_nat_gateway.this[$INDEX]" "$NAT_GW_ID"
            echo "✓ NAT Gateway [$INDEX] 导入完成"
        fi
        INDEX=$((INDEX + 1))
    done
fi

# Import Elastic IPs
echo ""
echo "Step 8: Import Elastic IPs..."
EIPS=$(aws ec2 describe-addresses --query 'Addresses[?AssociationId!=`null`].[AllocationId]' --output text)
if [ -n "$EIPS" ] && [ "$EIPS" != "None" ]; then
    INDEX=0
    for ALLOC_ID in $EIPS; do
        echo "EIP[$INDEX]: $ALLOC_ID"
        echo "terraform import 'module.vpc.aws_eip.nat[$INDEX]' $ALLOC_ID"
        read -p "确认? (yes/no): " CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            terraform import "module.vpc.aws_eip.nat[$INDEX]" "$ALLOC_ID"
            echo "✓ Elastic IP [$INDEX] 导入完成"
        fi
        INDEX=$((INDEX + 1))
    done
fi

# 验证 Plan
echo ""
echo "========================================"
echo "Step 9: 验证 Plan"
echo "========================================"
read -p "执行 terraform plan? (yes/no): " CONFIRM
if [ "$CONFIRM" = "yes" ]; then
    terraform plan
fi

echo ""
echo "========================================"
echo "Network Stack Import 完成"
echo "========================================"
