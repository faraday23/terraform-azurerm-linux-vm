# Required parameters

variable "location" {
  description = "Specifies the supported Azure location to MySQL server resource"
  type        = string
}

variable "resource_group_name" {
  description = "name of the resource group to create the resource"
  type        = string
}

variable "names" {
  description = "names to be applied to resources"
  type        = map(string)
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
}
variable "databases" {
  description = "Map of databases to create (keys are database names). Allowed values are the same as for database_defaults."
  default     = {}
}

variable "subnet_id" {
  type = any
}
/*
variable "nic_nsg_id" {
  type = any
}
*/
variable "private_ip_address_allocation" {
  type = string
}

variable "public_ip_address_id" {}


#variable "allocation_method" {}

#variable "sku" {}

variable "virtual_machine_settings" {}

#variable "nsg" {}

variable "network_interface_ids" {}

variable "network_interface_settings" {}

variable "availability_zone" {
  description = "Index of the Availability Zone which the Virtual Machine should be allocated in."
  type        = number
  default     = null
}

variable "storage_data_disk_config" {
  description = <<EOT
Map of objects to configure storage data disk(s).
    appli_data_disk = {
      name                 = string, 
      create_option        = string,
      disk_size_gb         = string,
      lun                  = string,
      storage_account_type = string,
    }
EOT
  type        = map(any)
  default     = {}
}
