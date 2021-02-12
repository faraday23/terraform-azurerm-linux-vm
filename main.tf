locals {
  vm_settings = zipmap(keys(var.vm_settings), [for vm_setting in values(var.vm_settings) : merge(var.vm_defaults, vm_setting)])
}

resource "tls_private_key" "ssh_keys" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "random_string" "public_key" {
  length  = 4
  special = false
  upper   = false
  number  = false
}

resource "local_file" "pem_files" {
  content         = tls_private_key.ssh_keys.private_key_pem
  filename        = "${path.module}/oracle_public_key-${random_string.public_key.result}.pem"
  file_permission = "0600"
}

# creates random password for admin account if not specified
resource "random_password" "admin" {
  for_each         = var.vm_settings
  length           = 24
  special          = true
  override_special = "!@#$%^&*"
}

resource "azurerm_public_ip" "public_ip" {
  count               = var.public_ip_settings != null ? 1 : 0
  name                = "${var.names.product_name}-pubip"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  allocation_method = try(var.public_ip_settings.allocation_method, null)
  sku               = try(var.public_ip_settings.sku, null)
  zones             = try([var.availability_zone], null)
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.names.product_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = format("%s-%s", var.names.product_name, var.names.environment)
    subnet_id                     = try(var.network_interface_settings.subnet_id, null)
    private_ip_address_allocation = try(var.network_interface_settings.private_ip_address_allocation, null)
  }
}

resource "azurerm_linux_virtual_machine" "oracle_vm" {
  for_each = local.vm_settings

  name                            = each.key
  resource_group_name             = var.resource_group_name
  location                        = var.location
  computer_name                   = "${var.names.product_name}-${var.names.environment}-${each.value.computer_name}"
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.disable_password_authentication != true && each.value.admin_password == "" ? random_password.admin[each.key].result : each.value.admin_password
  disable_password_authentication = each.value.disable_password_authentication
  priority                        = each.value.priority
  eviction_policy                 = each.value.eviction_policy
  zone                            = var.availability_zone
  network_interface_ids           = [azurerm_network_interface.nic.id, ]

  admin_ssh_key {
    username   = each.value.username
    public_key = file("~/home/${each.value.username}/.ssh/authorized_keys")
  }

  identity {
    type = each.value.type
  }

  os_disk {
    caching              = each.value.caching
    storage_account_type = each.value.storage_account_type
  }

  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = each.value.version
  }

  boot_diagnostics {
    storage_account_uri = each.value.storage_account_uri
  }
}
