resource "tls_private_key" "ssh_keys" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "pem_files" {
  content         = tls_private_key.ssh_keys.private_key_pem
  filename        = "${path.module}/${"jumpbox"}.pem"
  file_permission = "0600"
}

# creates random password for admin account
resource "random_password" "admin" {
  length  = 24
  special = true
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.names.product_name}-pubip"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  allocation_method = try(var.allocation_method, null)
  sku               = try(var.sku, null)
  zones             = [var.availability_zone]
}


resource "azurerm_network_interface" "nic" {
  for_each = var.network_interface_settings

  name                = "${var.names.product_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.names.product_name}-ip-config"
    subnet_id                     = lookup(each.value, "subnet_id", null)
    private_ip_address_allocation = lookup(each.value, "private_ip_address_allocation", null)
  }
}

resource "azurerm_linux_virtual_machine" "oracle_db" {
  name                            = "${var.names.product_name}-db"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = try(var.virtual_machine_settings.size, "")
  admin_username                  = try(var.virtual_machine_settings.admin_username, "")
  admin_password                  = random_password.admin.result
  disable_password_authentication = try(var.virtual_machine_settings.disable_password_authentication, null)
  priority                        = try(var.virtual_machine_settings.priority, null)
  eviction_policy                 = try(var.virtual_machine_settings.eviction_policy, null)
  zone                            = try(var.availability_zone, null)
  network_interface_ids           = [azurerm_network_interface.nic.id, ]

  admin_ssh_key {
    username   = try(var.virtual_machine_settings.admin_ssh_key.username, null)
    public_key = try(tls_private_key.ssh_keys.public_key_openssh, var.virtual_machine_settings.admin_ssh_key.public_key)
  }

  identity {
    type = try(var.virtual_machine_settings.identity.type, null)
  }

  os_disk {
    caching              = try(var.virtual_machine_settings.os_disk.caching, null)
    storage_account_type = try(var.virtual_machine_settings.os_disk.storage_account_type, null)
  }

  source_image_reference {
    publisher = try(var.virtual_machine_settings.source_image_reference.publisher, null)
    offer     = try(var.virtual_machine_settings.source_image_reference.offer, null)
    sku       = try(var.virtual_machine_settings.source_image_reference.sku, null)
    version   = try(var.virtual_machine_settings.source_image_reference.version, null)
  }

  boot_diagnostics {
    storage_account_uri = try(var.virtual_machine_settings.boot_diagnostics.storage_account_uri, null)
  }
}

resource "azurerm_managed_disk" "disk" {
  for_each = var.storage_data_disk_config

  name                = lookup(each.value, "name", "${var.names.product_name}-${each.key}")
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  zones                = [var.availability_zone]
  storage_account_type = lookup(each.value, "storage_account_type", "Standard_LRS")

  create_option = lookup(each.value, "create_option", "Empty")
  disk_size_gb  = lookup(each.value, "disk_size_gb", null)
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  for_each = var.storage_data_disk_config

  managed_disk_id    = azurerm_managed_disk.disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.oracle_db.id

  lun     = lookup(each.value, "lun", each.key)
  caching = lookup(each.value, "caching", "ReadWrite")
}
