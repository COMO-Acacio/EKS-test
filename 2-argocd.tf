provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    host                   = data.aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority.0.data)
    token = data.aws_eks_cluster_auth.main.token
  }
}

resource "helm_release" "argocd" {
    name                = "argocd"
    repository          = "https://argoproj.github.io/argo-helm"
    chart               = "argo-cd"
    version             = "4.5.2"
    namespace           = "argocd"
    create_namespace    = true
    depends_on          = [ module.eks.cluster ]
}