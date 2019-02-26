# Core Development VM's

module "dmz-staging" {
  source          = "modules/dmz-staging"
  rg_location     = "${var.region}"
  rg_name         = "${var.resource_group_name}"
  network_prefix  = "${var.resource_group_subnet}"
  ssh_keys        = "${var.ssh_keys}"
  vm_type         = "Standard_B2ms"
  vm_node_size    = "2"
  tag             = "dmz-staging-test"
  node_env        = "staging"
  internal_domain = "dmz-staging.ramson.io"
  internal_record = "dmz-staging-test"
  vnet_name       = "${rg_name}-virtual-network"

  # vnet_name       = "staging-weNetwork"
}
