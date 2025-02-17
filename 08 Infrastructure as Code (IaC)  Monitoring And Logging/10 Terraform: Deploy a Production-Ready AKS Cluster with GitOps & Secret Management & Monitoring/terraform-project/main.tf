provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-rg-dev2025"
    storage_account_name = "tfstatestorage12345dev"
    container_name       = "tfstate-container"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  azure_policy_enabled = true
  
  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

# Ensure the cluster is available before using it
data "azurerm_kubernetes_cluster" "cluster" {
  name                = azurerm_kubernetes_cluster.aks.name
  resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name

  depends_on = [azurerm_kubernetes_cluster.aks] # Ensures AKS is created first
}

provider "kubernetes" {
  host                   = coalesce(try(data.azurerm_kubernetes_cluster.cluster.kube_admin_config[0].host, null), try(data.azurerm_kubernetes_cluster.cluster.kube_config[0].host, null))
  client_certificate     = base64decode(coalesce(try(data.azurerm_kubernetes_cluster.cluster.kube_admin_config[0].client_certificate, null), try(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate, null)))
  client_key             = base64decode(coalesce(try(data.azurerm_kubernetes_cluster.cluster.kube_admin_config[0].client_key, null), try(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_key, null)))
  cluster_ca_certificate = base64decode(coalesce(try(data.azurerm_kubernetes_cluster.cluster.kube_admin_config[0].cluster_ca_certificate, null), try(data.azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate, null)))
}

provider "helm" {
  kubernetes {
    host                   = coalesce(try(data.azurerm_kubernetes_cluster.cluster.kube_admin_config[0].host, null), try(data.azurerm_kubernetes_cluster.cluster.kube_config[0].host, null))
    client_certificate     = base64decode(coalesce(try(data.azurerm_kubernetes_cluster.cluster.kube_admin_config[0].client_certificate, null), try(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate, null)))
    client_key             = base64decode(coalesce(try(data.azurerm_kubernetes_cluster.cluster.kube_admin_config[0].client_key, null), try(data.azurerm_kubernetes_cluster.cluster.kube_config[0].client_key, null)))
    cluster_ca_certificate = base64decode(coalesce(try(data.azurerm_kubernetes_cluster.cluster.kube_admin_config[0].cluster_ca_certificate, null), try(data.azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate, null)))
  }
}



resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"
}

# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "kube-system"

}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "prometheus" {
  depends_on = [kubernetes_namespace.monitoring]
  name       = "prometheus"
  chart      = "prometheus"
  namespace  = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
}

resource "helm_release" "grafana" {
  depends_on = [kubernetes_namespace.monitoring]
  name       = "grafana"
  chart      = "grafana"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
}



# Azure Monitor for AKS
# resource "azurerm_monitor_diagnostic_setting" "aks_monitor" {
#   name                       = "aks-monitor"
#   target_resource_id         = azurerm_kubernetes_cluster.aks.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.log_workspace.id

#   enabled_log {
#     category = "kube-audit"
#   }

#   metric {
#     category = "AllMetrics"
#     enabled  = true
#   }
# }


resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = var.log_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

