# GitHub Actions -> Jenkins apply trigger

## Behavior

This repository uses `.github/workflows/jenkins-trigger.yml` to trigger the Jenkins job `terraform-base-apply` when:

- a pull request is merged
- the PR target branch is `main`
- the merged PR changed files under `envs/` or `modules/`

## Jenkins endpoint

- Jenkins URL: `http://k8s-jenkins-jenkins-84e6dd34b5-1827557328.ap-northeast-1.elb.amazonaws.com`
- Job: `terraform-base-apply`
- Trigger API: `/job/terraform-base-apply/buildWithParameters`

## Required GitHub secret

Add this repository secret:

- `JENKINS_PASSWORD`: Jenkins password for user `admin`

## Parameters sent to Jenkins

The workflow sends:

- `GIT_BRANCH=main`
- `TF_ACTION=apply`
- `STACK_PATH=<changed stack path>`
- `GITHUB_PR_URL=<merged PR url>`
- `GITHUB_CHANGES=<json string with PR title/body>`

## Important

The Jenkins job must define matching parameters if it expects to consume:

- `STACK_PATH`
- `GITHUB_PR_URL`
- `GITHUB_CHANGES`

If the Jenkins job does not yet expose those parameters, GitHub Actions still triggers the job, but Jenkins will ignore unknown values.

## Validation

Manual validation can be done by:

1. merging a PR into `main`
2. checking GitHub Actions run for `Trigger Jenkins Apply After PR Merge`
3. checking Jenkins build queue / build history for `terraform-base-apply`
