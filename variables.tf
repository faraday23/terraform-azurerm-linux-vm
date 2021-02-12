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

variable "vm_settings" {
  description = "Map of vm's to create (keys are vm names). Allowed values are the same as for vm_defaults."
  type        = map(any)
  default     = {}
}

variable "vm_defaults" {
  type = object({
    computer_name                   = string
    size                            = string
    admin_username                  = string
    admin_password                  = string
    disable_password_authentication = bool
    priority                        = string
    eviction_policy                 = string
    type                            = string
    username                        = string
    public_key                      = string
    name                            = string
    caching                         = string
    storage_account_type            = string
    publisher                       = string
    offer                           = string
    sku                             = string
    version                         = string
    storage_account_uri             = string
  })
  default = {
    computer_name                   = "default-computer-name"
    size                            = "Standard_F2"
    admin_username                  = "azadmin"
    admin_password                  = ""
    disable_password_authentication = true
    # Spot VM to save money
    priority        = ""
    eviction_policy = null
    # type of Managed Identity which should be assigned to the Linux Virtual Machine
    type = "SystemAssigned"
    # admin ssh key
    username   = "azadmin"
    public_key = ("~/.ssh/id_rsa.pub")
    # Internal OS disk
    name                 = "db_host_os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    # Image used to create the virtual machines.
    publisher = "Oracle"
    offer     = "Oracle-Database-Ee"
    sku       = "12.1.0.2"
    version   = "latest"
    # boot diagnostics
    storage_account_uri = ""
  }
  description = <<EOT
virtual machine default settings (only applied to virtual machine settings managed within this module)
    vm_settings = {
    size                            = (Required) The SKU which should be used for this Virtual Machine, such as Standard_F2.
    admin_username                  = (Required) The username of the local administrator used for the Virtual Machine. Changing this forces a new resource to be created.ring
    admin_password                  = (Optional) The Password which should be used for the local-administrator on this Virtual Machine. Changing this forces a new resource to be created.
    disable_password_authentication = (Optional) Should Password Authentication be disabled on this Virtual Machine? Defaults to true. Changing this forces a new resource to be created.
    # Spot VM to save money
    priority        = (Optional) Specifies the priority of this Virtual Machine. Possible values are Regular and Spot. Defaults to Regular. Changing this forces a new resource to be created.
    eviction_policy = (Optional) Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance. At this time the only supported value is Deallocate. Changing this forces a new resource to be created. This can only be configured when priority is set to Spot.
    # type of Managed Identity which should be assigned to the Linux Virtual Machine
    identity = {
      type = (Required) The type of Managed Identity which should be assigned to the Linux Virtual Machine. Possible values are SystemAssigned, UserAssigned and SystemAssigned, UserAssigned.
    }
    # SSH key
    admin_ssh_key = {
      username   = (Required) The Public Key which should be used for authentication, which needs to be at least 2048-bit and in ssh-rsa format. Changing this forces a new resource to be created.
      public_key = (Required) The Username for which this Public SSH Key should be configured. Changing this forces a new resource to be created.
    }
    # Internal OS disk
    os_disk = {
      name                 = (Required) The Type of Caching which should be used for the Internal OS Disk. Possible values are None, ReadOnly and ReadWrite.
      caching              = (Required) The Type of Caching which should be used for the Internal OS Disk. Possible values are None, ReadOnly and ReadWrite.
      storage_account_type = (Required) The Type of Storage Account which should back this the Internal OS Disk. Possible values are Standard_LRS, StandardSSD_LRS and Premium_LRS. Changing this forces a new resource to be created.
    }
    # Image used to create the virtual machines.
    source_image_reference = {
      publisher = (Optional) Specifies the publisher of the image used to create the virtual machines.
      offer     = (Optional) Specifies the offer of the image used to create the virtual machines.
      sku       = (Optional) Specifies the SKU of the image used to create the virtual machines.
      version   = (Optional) Specifies the version of the image used to create the virtual machines.
    }
    boot_diagnostics = {
      storage_account_uri = (Optional) The Primary/Secondary Endpoint for the Azure Storage Account which should be used to store Boot Diagnostics, including Console Output and Screenshots from the Hypervisor. Passing a null value will utilize a Managed Storage Account to store Boot Diagnostics.
    }
  }
EOT
}

variable "public_ip_settings" {
  description = <<EOT
Map of objects to configure public ip settings.
    public_ip_settings = {
      allocation_method    = string, 
      sku                  = string,
      availability_zone    = list(string),
    }
EOT
  type        = map(string)
}

variable "network_interface_settings" {
  description = <<EOT
Map of objects to configure network interface settings.
    network_interface_settings = {
      subnet_id                     = string, 
      private_ip_address_allocation = string,
    }
EOT
  type        = map(string)
}

variable "availability_zone" {
  description = "Index of the Availability Zone which the Virtual Machine should be allocated in."
  type        = number
  default     = null
}







