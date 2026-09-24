# Developer SKU: free, but it only reaches VMs in its own virtual network.
module "bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.9.0"

  count = local.deploy_bastion ? 1 : 0

  name               = local.names.bastion
  location           = local.location
  parent_id          = module.resource_group_connectivity.resource_id
  sku                = "Developer"
  virtual_network_id = module.hub.virtual_network_resource_ids["primary"]
  zones              = []
  enable_telemetry   = local.enable_telemetry
  tags               = local.tags
}

module "jumpbox" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"

  count = local.deploy_bastion ? 1 : 0

  name                = local.names.jumpbox
  location            = local.location
  resource_group_name = module.resource_group_connectivity.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  os_type  = "Linux"
  sku_size = local.jumpbox_size
  zone     = 1

  source_image_reference = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  network_interfaces = {
    primary = {
      name = local.names.jumpbox_nic
      ip_configurations = {
        primary = {
          name                          = "ipconfig-primary"
          private_ip_subnet_resource_id = "${module.hub.virtual_network_resource_ids["primary"]}/subnets/${local.names.management_subnet}"
        }
      }
    }
  }

  managed_identities = {
    system_assigned = true
  }

  # The module generates the SSH key pair and exposes it through its outputs.
  account_credentials = {
    admin_credentials = {
      username = "azureuser"
    }
  }

  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    runcmd:
      - curl -sL https://aka.ms/InstallAzureCLIDeb | bash
      - az aks install-cli
  CLOUDINIT
  )

  depends_on = [module.hub]
}
