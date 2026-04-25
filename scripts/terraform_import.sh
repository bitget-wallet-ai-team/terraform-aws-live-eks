#!/bin/bash
# terraform_import.sh
# 受控的 import 脚本 - 需要审批后执行

set -e

STACK_DIR="$1"
RESOURCE_ADDR="$2"
RESOURCE_ID="$3"

if [ -z "$STACK_DIR" ] || [ -z "$RESOURCE_ADDR" ] || [ -z "$RESOURCE_ID" ]; then
    echo "Usage: $0 <stack_dir> <resource_address> <resource_id>"
    echo "Example: $0 envs/test/ops/stacks/network module.vpc.aws_vpc.this vpc-12345678"
    exit 1
fi

echo "========================================"
echo "Terraform Import Operation"
echo "========================================"
echo "Stack: $STACK_DIR"
echo "Resource: $RESOURCE_ADDR"
echo "Resource ID: $RESOURCE_ID"
echo "========================================"

# 确认
echo "确认要执行 import? (yes/no)"
read -r CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted"
    exit 1
fi

cd "$STACK_DIR"

echo "Initializing Terraform..."
terraform init -backend-config=backend.hcl

echo "Executing import..."
terraform import "$RESOURCE_ADDR" "$RESOURCE_ID"

echo "Import completed. Running plan to verify..."
terraform plan

echo "========================================"
echo "Import verification complete"
echo "请检查 plan 输出，确认无意外变更"
echo "========================================"
