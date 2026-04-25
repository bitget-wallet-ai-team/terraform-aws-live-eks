#!/bin/bash
# detect_changed_stacks.sh
# 检测变更的 stack 目录

set -e

# 获取变更的文件列表
if [ -n "$GITHUB_BASE_REF" ]; then
    # PR 模式
    CHANGED_FILES=$(git diff --name-only origin/${GITHUB_BASE_REF} HEAD)
else
    # Push 模式 (取最近两次 commit)
    CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD)
fi

echo "Changed files:" >&2
echo "$CHANGED_FILES" >&2

# 检测变更的 stacks
STACKS=()

# 检查 envs 目录下的变更
for file in $CHANGED_FILES; do
    if [[ "$file" =~ ^envs/[^/]+/ops/stacks/([^/]+)/ ]]; then
        STACK="envs/test/ops/stacks/${BASH_REMATCH[1]}"
        if [[ ! " ${STACKS[@]} " =~ " ${STACK} " ]]; then
            STACKS+=("$STACK")
        fi
    fi
done

# 如果 modules 目录变更，需要检测哪些 stack 引用了该模块
for file in $CHANGED_FILES; do
    if [[ "$file" =~ ^modules/ ]]; then
        # 简单策略：如果 modules 变更，所有 stacks 都需要重新 plan
        # 生产环境可以用更精细的依赖分析
        for stack_dir in envs/test/ops/stacks/*/; do
            if [ -d "$stack_dir" ]; then
                STACK="${stack_dir%/}"
                if [[ ! " ${STACKS[@]} " =~ " ${STACK} " ]]; then
                    STACKS+=("$STACK")
                fi
            fi
        done
        break
    fi
done

# 输出 JSON 数组
if [ ${#STACKS[@]} -eq 0 ]; then
    echo '[]'
else
    # 使用 printf 输出 JSON 数组格式
    echo -n '['
    for i in "${!STACKS[@]}"; do
        if [ $i -gt 0 ]; then
            echo -n ','
        fi
        printf '"%s"' "${STACKS[$i]}"
    done
    echo ']'
fi
