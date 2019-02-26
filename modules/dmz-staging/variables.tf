variable ssh_keys {
  type = "list"
}

variable dev_disk_size {
  default = 32
}

variable os_user_name {
  default = "devops"
}

variable os_user_password {
  default = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

variable rg_location {}
variable rg_name {}
variable network_prefix {}
variable tag {}
variable internal_domain {}
variable internal_record {}
variable node_env {}
variable vm_type {}
variable vnet_name {}
variable vm_node_size {}
