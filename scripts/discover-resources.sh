#!/bin/bash
# discover-resources.sh - 发现现网资源
set -e

echo "========================================"
echo "AWS 资源发现"
echo "Account: $(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo 'Not logged in')"
echo "========================================"
echo ""

echo "## VPC ##"
aws ec2 describe-vpcs --query 'Vpcs[].[VpcId,CidrBlock,IsDefault,Tags[?Key==`Name`].Value|[0]]' --output table

echo ""
echo "## Subnets ##"
aws ec2 describe-subnets --query 'Subnets[].[SubnetId,VpcId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' --output table

echo ""
echo "## Internet Gateways ##"
aws ec2 describe-internet-gateways --query 'InternetGateways[].[InternetGatewayId,Attachments[0].VpcId]' --output table

echo ""
echo "## NAT Gateways ##"
aws ec2 describe-nat-gateways --query 'NatGateways[?State==`available`].[NatGatewayId,VpcId,SubnetId]' --output table

echo ""
echo "## EKS Clusters ##"
aws eks list-clusters --output table 2>/dev/null || echo "No EKS clusters or no permission"

echo ""
echo "## Security Groups ##"
aws ec2 describe-security-groups --query 'SecurityGroups[].[GroupId,GroupName,VpcId]' --output table | head -20

echo ""
echo "## S3 Buckets ##"
aws s3api list-buckets --query 'Buckets[].[Name]' --output table | head -20

echo ""
echo "## Load Balancers ##"
aws elbv2 describe-load-balancers --query 'LoadBalancers[].[LoadBalancerName,Type,VPCId]' --output table 2>/dev/null || echo "No ALB or no permission"

echo ""
echo "========================================"
echo "资源发现完成"
echo "========================================"
