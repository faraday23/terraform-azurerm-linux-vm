output "administrator_login" {
  description = "The vm login for the admin."
  sensitive   = true
  value       = try(var.vm_settings.admin_username, var.vm_defaults.admin_username)
}

output "administrator_password" {
  description = "The vm password for the admin account."
  sensitive   = true
  value       = try(var.vm_settings.admin_password, var.vm_defaults.admin_password)
}

output "id" {
  description = "The ID of the Oracle VM."
  value = { for key, oracle_vm in azurerm_linux_virtual_machine.oracle_vm : key => { id = oracle_vm.id } }
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.0.ip_address
}

output "private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}

output "nic_id" {
  value = azurerm_network_interface.nic.id
}

output "public_key" {
  value     = try(var.vm_settings.public_key, var.vm_defaults.public_key)
  sensitive = true
}
