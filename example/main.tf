# Configure terraform and azure provider
terraform {
  required_version = ">= 0.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = "[redacted]"
}

module "rules" {
  source = "github.com/[redacted]/python-azure-naming.git?ref=working"
}

module "metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.1.0"

  naming_rules = module.rules.yaml

  market              = "us"
  project             = "https://gitlab.ins.risk.regn.net/example/"
  location            = "eastus2"
  sre_team            = "iog-core-services"
  environment         = "sandbox"
  product_name        = "oracle2"
  business_unit       = "iog"
  product_group       = "core"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "nonprod"
  resource_group_type = "app"
}

module "resource_group" {
  source = "github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v1.0.0"

  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

module "virtual_network" {
  source = "../ORACLE_MODULE/virtual_network"

  naming_rules = module.rules.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  address_space = ["10.1.1.0/24"]

  subnets = {
    "AzureBastionSubnet" = { cidrs = ["10.1.1.0/27"]
      service_endpoints       = ["Microsoft.Storage", "Microsoft.SQL"]
      allow_lb_inbound        = true
      allow_internet_outbound = true
      allow_vnet_inbound      = true
      allow_vnet_outbound     = true
    }
  }
}

module "storage_account" {
  source = "github.com/[redacted]/terraform-azurerm-storage-account.git"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  account_kind     = "StorageV2"
  replication_type = "LRS"

  service_endpoints = {
    "AzureBastionSubnet" = module.virtual_network.subnet["AzureBastionSubnet"].id
  }
}

# azure bastion as a service
module "bastion" {
  source = "../ORACLE_MODULE/bastion_service"

  depends_on = [module.virtual_network]

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  subnet_id           = module.virtual_network.subnet["AzureBastionSubnet"].id
  security_group_name = module.virtual_network.subnet_nsg_names["AzureBastionSubnet"]
}

# Virtual machines
module "oracle_vm" {
  source = "../ORACLE_MODULE/single"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags
  availability_zone   = 1

  # IP configuration
  #subnet_id                     = module.virtual_network.subnet["AzureBastionSubnet"].id
  public_ip_address_id          = module.bastion.pub_ip_id
  #private_ip_address_allocation = "Dynamic"
  #nic_nsg_id                    = module.virtual_network.subnet_nsg_names["iaas-public"].id  #waiting on output to be created by vnet module
  #allocation_method             = "Static"
  #sku                           = "Standard"
  #nsg                           = module.virtual_network.subnet_nsg_names["iaas-public"]
  #network_interface_ids          = module.bastion.nic_id

  network_interface_settings = {
    subnet_id                     = module.virtual_network.subnet["AzureBastionSubnet"].id
    private_ip_address_allocation = "Dynamic"
  }

  # Configuration to deploy a oracle db on linux virtual machine
  virtual_machine_settings = {
    name           = "oracle-db-host"
    size           = "Standard_F2"
    admin_username = "azadmin"

    # When an admin_password is specified disable_password_authentication must be set to false. ~> NOTE: One of either admin_password or admin_ssh_key must be specified.
    disable_password_authentication = true

    # Spot VM to save money
    #priority        = "Spot"
    #eviction_policy = "Deallocate"

    # type of Managed Identity which should be assigned to the Linux Virtual Machine
    identity = {
      type = "SystemAssigned"
    }

    # SSH key
    admin_ssh_key = {
      username   = "azadmin"
      public_key = file("~/.ssh/id_rsa.pub")
    }

    # Internal OS disk
    os_disk = {
      name                 = "db_host_os"
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }

    # Image used to create the virtual machines.
    source_image_reference = {
      publisher = "Oracle"
      offer     = "Oracle-Database-Ee"
      sku       = "12.1.0.2"
      version   = "latest"
    }

    boot_diagnostics = {
      storage_account_uri = module.storage_account.primary_blob_endpoint
    }
  }

  storage_data_disk_config = {
    oracle-db = {
      name                 = "oracle-db"
      disk_size_gb         = 128
      lun                  = 0
      storage_account_type = "Standard_LRS"
    }
  }
}






