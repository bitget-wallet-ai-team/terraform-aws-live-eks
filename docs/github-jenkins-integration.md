# GitHub Actions -> Jenkins apply trigger

## Behavior

This repository uses `.github/workflows/jenkins-trigger.yml` to trigger the Jenkins job `terraform-base-apply` when:

- a pull request is merged
- the PR target branch is `main`
- the merged PR changed files under `envs/` or `modules/`

The current live Jenkins job is configured to run a fixed Terraform stack at `envs/test/ops/stacks/eks`, so the GitHub workflow now triggers a Jenkins `plan` run instead of an `apply` run.

## Jenkins endpoint

- Jenkins URL: `http://k8s-jenkins-jenkins-84e6dd34b5-1827557328.ap-northeast-1.elb.amazonaws.com`
- Job: `terraform-base-apply`
- Trigger API: `/job/terraform-base-apply/buildWithParameters`

## Required GitHub secret

Add this repository secret:

- `JENKINS_USER`: Jenkins username
- `JENKINS_API_TOKEN`: Jenkins API token for that user

## Parameters sent to Jenkins

The workflow sends only the parameters that the live Jenkins job currently defines:

- `GIT_BRANCH=main`
- `TF_ACTION=plan`

## Important

The current live Jenkins job `terraform-base-apply` uses a fixed stack path inside Jenkins itself:

- `TF_CONFIG_PATH=envs/test/ops/stacks/eks`

It does **not** currently define or consume:

- `STACK_PATH`
- `GITHUB_PR_URL`
- `GITHUB_CHANGES`

If you want PR metadata or per-stack routing later, those parameters must be added to the Jenkins job first.

## Validation

Manual validation can be done by:

1. merging a PR into `main`
2. checking GitHub Actions run for `Trigger Jenkins Apply After PR Merge`
3. checking Jenkins build queue / build history for `terraform-base-apply`
