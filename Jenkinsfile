// Jenkinsfile — Terraform per-stack runner.
//
// Job parameters (set on the Jenkins job UI; defaults below match what
// `.github/workflows/jenkins-trigger.yml` sends):
//   GIT_BRANCH  : git branch to check out (default: main)
//   STACK_PATH  : repo-relative path to the Terraform stack (e.g.
//                envs/test/ops/stacks/golang-eks). REQUIRED.
//   TF_ACTION   : plan | apply (default: plan)
//
// Backward-compat: if STACK_PATH is empty, falls back to legacy hard-coded
// envs/test/ops/stacks/eks (matches old terraform-base-apply behavior).
//
// Auth: assumes the Jenkins agent already has AWS credentials wired in
// (IRSA on the k8s pod, or a Jenkins credential exposing AWS_*). This file
// does NOT inject credentials.

pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
    disableConcurrentBuilds()
    timeout(time: 60, unit: 'MINUTES')
  }

  parameters {
    string(name: 'GIT_BRANCH', defaultValue: 'main',
           description: 'Git branch to check out')
    string(name: 'STACK_PATH', defaultValue: '',
           description: 'Repo-relative path to the Terraform stack ' +
                        '(e.g. envs/test/ops/stacks/golang-eks). ' +
                        'Empty = legacy envs/test/ops/stacks/eks.')
    choice(name: 'TF_ACTION', choices: ['plan', 'apply'],
           description: 'Terraform action to perform')
  }

  environment {
    AWS_REGION   = 'ap-northeast-1'
    TF_IN_AUTOMATION = 'true'
    TF_INPUT     = '0'
  }

  stages {
    stage('Resolve stack') {
      steps {
        script {
          env.RESOLVED_STACK = params.STACK_PATH?.trim() ?: 'envs/test/ops/stacks/eks'
          echo "Resolved stack: ${env.RESOLVED_STACK}"
          echo "TF_ACTION:     ${params.TF_ACTION}"
          echo "GIT_BRANCH:    ${params.GIT_BRANCH}"
        }
      }
    }

    stage('Checkout') {
      steps {
        checkout([
          $class: 'GitSCM',
          branches: [[name: "*/${params.GIT_BRANCH}"]],
          userRemoteConfigs: scm.userRemoteConfigs,
          extensions: [[$class: 'CleanBeforeCheckout']]
        ])
      }
    }

    stage('Validate stack exists') {
      steps {
        sh '''
          set -euo pipefail
          if [ ! -d "$RESOLVED_STACK" ]; then
            echo "ERROR: stack directory not found: $RESOLVED_STACK"
            exit 2
          fi
          ls -la "$RESOLVED_STACK"
        '''
      }
    }

    stage('Terraform init') {
      steps {
        dir("${env.RESOLVED_STACK}") {
          sh '''
            set -euo pipefail
            if [ -f backend.hcl ]; then
              terraform init -reconfigure -backend-config=backend.hcl
            else
              terraform init -reconfigure
            fi
          '''
        }
      }
    }

    stage('Terraform validate') {
      steps {
        dir("${env.RESOLVED_STACK}") {
          sh 'terraform validate'
        }
      }
    }

    stage('Terraform plan') {
      steps {
        dir("${env.RESOLVED_STACK}") {
          sh 'terraform plan -out=tfplan -lock-timeout=300s'
        }
      }
    }

    stage('Terraform apply') {
      when { expression { params.TF_ACTION == 'apply' } }
      steps {
        dir("${env.RESOLVED_STACK}") {
          sh 'terraform apply -auto-approve -lock-timeout=600s tfplan'
        }
      }
    }
  }

  post {
    always {
      script {
        echo "Done. stack=${env.RESOLVED_STACK} action=${params.TF_ACTION} result=${currentBuild.currentResult}"
      }
    }
  }
}
