resource "helm_release" "golang_app" {
  name      = var.release_name
  namespace = var.namespace
  chart     = "${path.module}/charts/golang-app"

  create_namespace = false
  atomic           = true
  wait             = true
  timeout          = 600

  values = [yamlencode({
    replicaCount = var.replica_count

    image = {
      repository = var.image_repository
      tag        = var.image_tag
      pullPolicy = "IfNotPresent"
    }

    containerPort = var.container_port

    resources = {
      requests = {
        cpu    = var.cpu
        memory = var.memory
      }
      limits = {
        cpu    = var.cpu
        memory = var.memory
      }
    }

    service = {
      type       = "ClusterIP"
      port       = var.service_port
      targetPort = var.container_port
    }
  })]
}
