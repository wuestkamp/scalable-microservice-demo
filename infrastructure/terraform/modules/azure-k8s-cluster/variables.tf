variable "client_id" {}
variable "client_secret" {}

variable "kubernetes_version" {
    // az aks get-versions --location "West Europe" --output table
    default = "1.17.0"
}

variable "agent_count" {
    default = 3
}

variable "ssh_public_key" {
    default = "~/.ssh/id_rsa.pub"
}

variable "dns_prefix" {
    default = "k8s"
}

variable cluster_name {
    default = "scalable_ms_prod"
}

variable resource_group_name {
    default = "scalable_microservice"
}

variable resource_group_location {
    default = "West Europe"
}

variable log_analytics_workspace_name {
    default = "testLogAnalyticsWorkspaceName"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "eastus"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}
