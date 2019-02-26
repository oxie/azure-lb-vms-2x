provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

provider "cloudflare" {
  email = "${var.cf_email}"
  token = "${var.cf_token}"
}

variable "cf_email" {}
variable "cf_token" {}

variable "subscription_id" {
  description = "Enter Subscription ID for provisioning resources in Azure"
}

variable "client_id" {
  description = "Enter Client ID for Application created in Azure AD"
}

variable "client_secret" {
  description = "Enter Client secret for Application in Azure AD"
}

variable "tenant_id" {
  description = "Enter Tenant ID / Directory ID of your Azure AD. Run Get-AzureSubscription to know your Tenant ID"
}

variable "region" {
  default = "North Europe"
}

variable "resource_group_name" {
  default = "dmz-staging-test"
}

variable "resource_group_subnet" {
  default = "172.20"
}

variable "ssh_keys" {
  default = [{
    path     = "/home/devops/.ssh/authorized_keys"
    key_data = "ssh-rsa XXXXXXXXXXXX = someone@devopsteam.cool"
  },
    {
      path     = "/home/devops/.ssh/authorized_keys"
      key_data = "ssh-rsa XXXXXXXXXXXX = someone@devopsteam.cool"
    },
    {
      path     = "/home/devops/.ssh/authorized_keys"
      key_data = "ssh-rsa XXXXXXXXXXXX = someone@devopsteam.cool"
    },
    {
      path     = "/home/devops/.ssh/authorized_keys"
      key_data = "ssh-rsa XXXXXXXXXXXX = someone@devopsteam.cool"
    },
    {
      path     = "/home/devops/.ssh/authorized_keys"
      key_data = "ssh-rsa XXXXXXXXXXXX = someone@devopsteam.cool"
    },
    {
      path     = "/home/devops/.ssh/authorized_keys"
      key_data = "ssh-rsa XXXXXXXXXXXX = someone@devopsteam.cool"
    },
    {
      path     = "/home/devops/.ssh/authorized_keys"
      key_data = "ssh-rsa XXXXXXXXXXXX = someone@devopsteam.cool"
    },
    {
      path     = "/home/devops/.ssh/authorized_keys"
      key_data = "ssh-rsa XXXXXXXXXXXX = someone@devopsteam.cool"
    },
  ]
}
