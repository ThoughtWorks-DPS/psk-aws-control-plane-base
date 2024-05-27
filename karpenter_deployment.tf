resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_chart_version
  wait       = false

  values = [
    templatefile("tpl/karpenter_values.tpl", {
      iam_role_arn               = module.karpenter.iam_role_arn
      management_node_group_name = var.management_node_group_name
      management_node_group_role = var.management_node_group_role
      cluster_name               = var.cluster_name
      cluster_endpoint           = module.eks.cluster_endpoint
      queue_name                 = module.karpenter.queue_name
    }),
  ]

}
