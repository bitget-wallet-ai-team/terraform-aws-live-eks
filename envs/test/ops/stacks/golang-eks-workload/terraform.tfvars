aws_region  = "ap-northeast-1"
environment = "test"

cluster_name = "golang-eks-cluster-1"

# Helm release: golang-app
release_name  = "golang-app"
namespace     = "default"
replica_count = 3

# Container image — placeholder (nginx) to validate the chain;
# switch to real ECR repo/tag/port in a follow-up PR.
image_repository = "nginx"
image_tag        = "alpine"
container_port   = 80
service_port     = 80

# Per-pod resources: 1C / 1Gi (requests = limits)
cpu    = "1000m"
memory = "1Gi"
