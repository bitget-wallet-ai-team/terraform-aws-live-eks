# 变更流程

## 标准变更流程

### 步骤 1: 工程师提交变更

修改文件（仅以下位置）：
- `envs/test/ops/stacks/<stack>/terraform.tfvars` - 调整参数
- `envs/test/ops/stacks/<stack>/main.tf` - 调整 root module 调用（如新增资源）

**禁止修改**: `modules/` 目录（模块由平台团队维护）

### 步骤 2: 创建 PR

PR 模板必须填写：

```markdown
## 变更目的
<!-- 描述本次变更的原因 -->

## 影响 Stack
<!-- 列出受影响的 stack -->
- [ ] network
- [ ] security
- [ ] storage
- [ ] ingress
- [ ] eks
- [ ] compute

## 风险评估
- [ ] 低风险（仅参数调整）
- [ ] 中风险（新增资源）
- [ ] 高风险（删除/替换资源）

## 回滚方案
<!-- 描述如何回滚 -->

## 是否涉及 Import / Replace / Destroy
- [ ] Import
- [ ] Replace
- [ ] Destroy
```

### 步骤 3: 自动 Plan

GitHub Actions 自动执行：
- `terraform fmt -check`
- `terraform validate`
- `tflint`
- `checkov`
- `terraform plan`

Plan 结果自动评论到 PR。

### 步骤 4: 代码审核

根据 CODEOWNERS：
- `/envs/test/ops/stacks/**` → @ops-team
- `/envs/test/ops/stacks/eks/` → @ops-team + @platform-team
- `/modules/**` → @platform-team

### 步骤 5: 合并到 main

审核通过后，由 PR 作者合并。

### 步骤 6: 人工批准 Apply

合并后触发 `terraform-apply.yml`，暂停等待 GitHub Environment 审批。

审批人：
- `test-ops-apply` 环境 → platform-admin / ops-lead

### 步骤 7: 执行结果归档

Apply 完成后自动记录：
- Plan 输出
- Apply 日志
- PR 链接
- 触发人 / 审批人 / 执行时间

## 紧急变更流程

紧急情况下可绕过部分流程，但必须：

1. 事后补 PR
2. 记录变更原因
3. 平台管理员审批

## 禁止事项

1. ❌ **本地 terraform apply** - 只允许 CI/CD apply
2. ❌ **手工改 AWS 资源** - 所有变更必须通过 Terraform
3. ❌ **直接改 state 文件** - 除非紧急情况且审批
4. ❌ **跨 stack 共管资源** - 资源归属必须固定
5. ❌ **绕过审查直接 merge** - 必须 CODEOWNERS 审批
