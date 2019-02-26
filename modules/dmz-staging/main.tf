
resource "azurerm_resource_group" "rg" {
  name     = "${var.rg_name}"
  location = "${var.rg_location}"
}

resource "azurerm_public_ip" "lb_public_ip" {
  name                         = "${var.rg_name}-public-ip-lb-${count.index+1}"
  location                     = "${var.rg_location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "static"
  domain_name_label = "${var.rg_name}"

}

resource "azurerm_lb" "lb" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  name                = "${var.rg_name}-loadbalancer-${count.index+1}"
  location            = "${var.rg_location}"

  frontend_ip_configuration {
    name                 = "${var.rg_name}-ipconfig"
    public_ip_address_id = "${azurerm_public_ip.lb_public_ip.id}"
  }
}


resource "azurerm_lb_backend_address_pool" "dmz-staging-backend-pool" {
  location            = "${var.rg_location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "${var.rg_name}-backend-address-pool"
}

resource "azurerm_lb_rule" "lb_rule_80" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "${var.rg_name}-lb-rules-80"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${var.rg_name}-front-ip-config"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.dmz-staging-backend-pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.lb_probe.id}"
  depends_on                     = ["azurerm_lb_probe.lb_probe"]
}

resource "azurerm_lb_rule" "lb_rule_443" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "${var.rg_name}-lb-rules-443"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.rg_name}-front-ip-config"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.dmz-staging-backend-pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.lb_probe.id}"
  depends_on                     = ["azurerm_lb_probe.lb_probe"]
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "${var.rg_name}-tcp-probe"
  protocol            = "tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_nat_rule" "tcp" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "${var.rg_name}-${count.index}"
  protocol                       = "tcp"
  frontend_port                  = "5000${count.index + 1}"
  backend_port                   = 3389
  frontend_ip_configuration_name = "${var.rg_name}-front-ip-config"
  count                          = 2
}

resource "azurerm_network_interface" "dmz-staging-network-interface" {
  name                = "${var.rg_name}-net-interface-${count.index+1}"
  location            = "${var.rg_location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  count               = 2

  ip_configuration {
    name                                    = "${var.rg_name}-${count.index+1}-ip-config"
    subnet_id                               = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation           = "static"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.dmz-staging-backend-pool.id}"]
    load_balancer_inbound_nat_rules_ids     = ["${element(azurerm_lb_nat_rule.tcp.*.id, count.index)}"]          ### USE NAT RULES OR SECURITY GROUP
  }
}

resource "azurerm_network_security_group" "dmz-staging-sg" {
  name                = "${var.rg_name}-sg"
  location            = "${var.rg_location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-p443-dmz-staging"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-p80-dmz-staging"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  lifecycle {
    ignore_changes = "security_rule"
  }

  tags {
    environment = "${var.rg_name}"
  }
}





resource "azurerm_storage_account" "dmz-staging-storage-acc" {
  name                     = "dmzstagingfs"
  location                 = "${var.rg_location}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  account_tier             = "standard"
  account_replication_type = "lrs"
}

resource "azurerm_availability_set" "dmz-staging-availability-set" {
  name                = "${var.rg_name}-availability-set"
  location            = "${var.rg_location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  managed             = true
}

resource "azurerm_virtual_machine" "dmz_staging-vm" {
  name                  = "${var.rg_name}-vm-${format("%03d", count.index + 1)}"
  location              = "${var.rg_location}"
  availability_set_id   = "${azurerm_availability_set.dmz-staging-availability-set.id}"
  resource_group_name   = "${var.rg_name}"
  network_interface_ids = ["${element(azurerm_network_interface.dmz-staging-network-interface.*.id, count.index)}"]
  vm_size               = "${var.vm_type}"
  count                 = "${var.vm_node_size}"

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.1"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.rg_name}-vm-${format("%03d", count.index + 1)}-osdisk"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "32"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  storage_data_disk {
    name          = "${var.rg_name}-vm-${format("%03d", count.index + 1)}-dd0"
    disk_size_gb  = "${var.dev_disk_size}"
    caching       = "ReadWrite"
    create_option = "Empty"
    lun           = 0
  }

  storage_data_disk {
    name          = "${var.rg_name}-vm-${format("%03d", count.index + 1)}-dd1"
    disk_size_gb  = "${var.dev_disk_size}"
    caching       = "ReadWrite"
    create_option = "Empty"
    lun           = 1
  }

  os_profile {
    computer_name  = "${var.rg_name}-vm-${format("%03d", count.index + 1)}"
    admin_username = "${var.os_user_name}"
    admin_password = "${var.os_user_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys                        = "${var.ssh_keys}"
  }
}


resource "azurerm_virtual_network" "virtual-network" {
  name                = "${var.rg_name}-virtual-network"
  location            = "${var.rg_location}"
  address_space       = ["${var.network_prefix}.0.0/16"]
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.rg_name}-subnet"
  virtual_network_name = "${azurerm_virtual_network.virtual-network.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${var.network_prefix}.1.0/24"
  network_security_group_id = "${azurerm_network_security_group.dmz-staging-sg.id}"
}

