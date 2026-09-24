# CoreDNS in place of a DNS Private Resolver inbound endpoint: VPN clients cannot
# reach Azure DNS, so they query this, and it forwards to Azure DNS from the hub.
module "dns_forwarder" {
  source  = "Azure/avm-res-containerinstance-containergroup/azurerm"
  version = "0.2.0"

  count = local.deploy_dns_forwarder ? 1 : 0

  name                = local.names.dns_forwarder
  location            = local.location
  resource_group_name = module.resource_group_connectivity.name
  enable_telemetry    = local.enable_telemetry
  tags                = local.tags

  os_type          = "Linux"
  restart_policy   = "Always"
  subnet_ids       = ["${module.hub.virtual_network_resource_ids["primary"]}/subnets/${local.names.dns_forwarder_subnet}"]
  dns_name_servers = ["168.63.129.16"]

  containers = {
    coredns = {
      image    = "mcr.microsoft.com/oss/v2/kubernetes/coredns:v1.14.7"
      cpu      = 0.5
      memory   = 0.5
      commands = ["/usr/bin/coredns", "-conf", "/etc/coredns/Corefile"]
      ports = [
        { port = 53, protocol = "UDP" },
        { port = 53, protocol = "TCP" },
      ]
      volumes = {
        config = {
          name       = "config"
          mount_path = "/etc/coredns"
          read_only  = true
          secret = {
            Corefile = base64encode(<<-COREFILE
              .:53 {
                  errors
                  cache 30
                  forward . 168.63.129.16
              }
            COREFILE
            )
          }
        }
      }
    }
  }

  depends_on = [module.hub]
}
