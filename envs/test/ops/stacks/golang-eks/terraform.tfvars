aws_region  = "ap-northeast-1"
environment = "test"

cluster_name    = "golang-eks-cluster-1"
cluster_version = "1.35"

# 节点组: 2 × t3.large (≈ 1.93 vCPU/7.6 GiB allocatable each = 3.86 vCPU/15.2 GiB total)
# 满足 3 × (1C/1G) requests + 系统/kube 开销 + 余量供 daemonset/sidecar
node_instance_types = ["t3.large"]
node_desired_size   = 2
node_min_size       = 2
node_max_size       = 4

# Cluster admin: Jenkins 角色 + SSO role
cluster_admin_role_arns = {
  jenkins = "arn:aws:iam::151062088992:role/jenkins-terraform-role"
  sso     = "arn:aws:iam::151062088992:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_aws-GENApo-bk-openclaw-rw_c6ed0030010b6653"
}
