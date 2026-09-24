# Application landing zones

One workload per directory, each in its own subscription. `platform/subscriptions`
vends that subscription first: management group, budget, and a spoke network peered
to the hub. The root here deploys only the workload, into that spoke.

Adding one: an entry in `platform/subscriptions`, then a directory here, then the root
in `bootstrap` and the CI lists (see [bootstrap/README.md](../../bootstrap/README.md)).

What a workload in `alz-corp` inherits rather than builds:

- The policy baseline: no public data plane, no public IP on a network interface,
  subnets must carry an NSG, resources only in the approved region.
- Private DNS: `Deploy-Private-DNS-Zones` registers each private endpoint in the hub's
  zone, so the root leaves the DNS zone group to policy
  (`private_endpoints_manage_dns_zone_group = false` in AVM modules).
- Reachability from the hub and VPN clients through the peering.

| Landing zone | Owns |
|---|---|
| `dev` | A private Key Vault, to test the VPN and DNS path |
