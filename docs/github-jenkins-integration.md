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

## Jenkins job — pipeline-as-code

The Jenkins job `terraform-base-apply` is **Pipeline → Pipeline script from
SCM** pointing at this repo's root `Jenkinsfile`.

Required job parameters (defined in the Jenkinsfile, declared on the job):

| Name        | Type   | Default | Description                                   |
|-------------|--------|---------|-----------------------------------------------|
| GIT_BRANCH  | string | `main`  | Branch to check out                           |
| STACK_PATH  | string | empty   | Repo-relative stack path. Empty = legacy `envs/test/ops/stacks/eks` |
| TF_ACTION   | choice | `plan`  | `plan` or `apply`                             |

The Jenkinsfile runs:
1. checkout the requested branch
2. validate the stack directory exists
3. `terraform init -backend-config=backend.hcl` inside the stack
4. `terraform validate`
5. `terraform plan -out=tfplan`
6. `terraform apply tfplan` (only when `TF_ACTION=apply`)

AWS credentials are expected to be wired into the Jenkins agent already
(IRSA on the k8s pod, or a Jenkins credential exposing AWS_*); the
Jenkinsfile does not inject them.

## Jenkins endpoint

- Jenkins URL: `http://k8s-jenkins-jenkins-84e6dd34b5-1827557328.ap-northeast-1.elb.amazonaws.com`
- Job: `terraform-base-apply`
- Trigger API: `/job/terraform-base-apply/buildWithParameters`

## Required GitHub secrets

- `JENKINS_USER`: Jenkins username
- `JENKINS_API_TOKEN`: Jenkins API token for that user

## Migration notes (one-time Jenkins changes)

The previous job hard-coded `TF_CONFIG_PATH=envs/test/ops/stacks/eks` and
only supported `TF_ACTION=plan`. To pick up the new behaviour:

1. Edit job `terraform-base-apply`:
   - Definition: **Pipeline script from SCM**
   - SCM: this repo, Branches to build: `*/main`
   - Script Path: `Jenkinsfile`
2. Add string parameter `STACK_PATH` (default empty).
3. Ensure `TF_ACTION` parameter is a Choice of `plan, apply` (the
   Jenkinsfile's `parameters {}` block will reconcile this on first run).
4. Remove or ignore the old `TF_CONFIG_PATH` parameter — the Jenkinsfile
   uses `STACK_PATH`.

After the migration, the very next merged PR triggers one Jenkins build per
changed stack, each with the right `STACK_PATH` and `TF_ACTION=apply`.

## Validation

Manual validation:

1. merge a PR into `main` that touches a stack
2. check GitHub Actions run for `Trigger Jenkins Apply After PR Merge` —
   the summary lists `Triggered stacks`
3. check Jenkins build queue / build history for `terraform-base-apply` —
   one build per stack, each with its `STACK_PATH` parameter visible
