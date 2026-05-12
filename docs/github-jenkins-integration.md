# GitHub Actions -> Jenkins apply trigger

## Behavior

This repository uses `.github/workflows/jenkins-trigger.yml` to trigger the
Jenkins job `terraform-base-apply` once per changed stack when:

- a pull request is merged
- the PR target branch is `main`
- the merged PR changed files under `envs/` or `modules/`

The workflow detects which Terraform stacks are affected (one HTTP call per
stack), and each call passes `STACK_PATH=envs/test/ops/stacks/<name>` plus
`TF_ACTION=apply`.

If `modules/` changed, every stack under `envs/test/ops/stacks/` is
triggered.

Apply order is enforced inside the workflow: any stack whose name ends with
`-workload` is fired *after* its sibling cluster stack, so a Helm release
never gets attempted before the EKS cluster is ACTIVE.

## Jenkins job — inline pipeline (current)

The Jenkins job `terraform-base-apply` is a Pipeline job whose script is
defined inline on the job (not Pipeline-from-SCM). It runs in a Kubernetes
pod with `serviceAccountName: jenkins-terraform-sa` (IRSA → AWS creds) and
multi-container layout (`terraform`, `git`, `aws-cli`, `helm`).

Job parameters:

| Name        | Type   | Default | Description                                   |
|-------------|--------|---------|-----------------------------------------------|
| GIT_BRANCH  | string | `main`  | Branch to check out                           |
| STACK_PATH  | string | empty   | Repo-relative stack path. Empty = legacy `envs/test/ops/stacks/eks` |
| TF_ACTION   | choice | `plan`  | `plan` or `apply`                             |

Pipeline stages:
1. **Initialize** — resolve `TF_CONFIG_PATH` from `STACK_PATH` (fallback `envs/test/ops/stacks/eks`)
2. **Checkout Code** — git clone with `github_pat` credential
3. **Verify AWS Identity** — `aws sts get-caller-identity` (proves IRSA)
4. **Terraform Init** — `terraform init -reconfigure -backend-config=backend.hcl` (when present)
5. **Terraform Validate**
6. **Terraform Plan** — writes `tfplan`
7. **Approval** — manual gate, only when `TF_ACTION=apply`
8. **Terraform Apply** — `terraform apply tfplan` (only when approved)

## Required tfvars in git

Because Jenkins clones the repo and runs `terraform plan` in the cloned
working copy, every stack referenced by `STACK_PATH` **must have its
`terraform.tfvars` committed to git** (this repo's `.gitignore` whitelists
specific stacks via `!path/to/terraform.tfvars`). These files must NOT
contain secrets — only environment configuration. Pull secrets from
Jenkins credentials, AWS Secrets Manager, or env vars.

## Jenkins endpoint

- Jenkins URL: `http://k8s-jenkins-jenkins-84e6dd34b5-1827557328.ap-northeast-1.elb.amazonaws.com`
- Job: `terraform-base-apply`
- Trigger API: `/job/terraform-base-apply/buildWithParameters`

## Required GitHub secrets

- `JENKINS_USER`: Jenkins username
- `JENKINS_API_TOKEN`: Jenkins API token for that user

## Validation

Manual validation:

1. merge a PR into `main` that touches a stack
2. check GitHub Actions run for `Trigger Jenkins Apply After PR Merge` —
   the summary lists `Triggered stacks`
3. check Jenkins build queue / build history for `terraform-base-apply` —
   one build per stack, each with its `STACK_PATH` parameter visible.
   `apply` builds pause at the **Approval** stage until a human clicks
   Apply in the Jenkins UI.
