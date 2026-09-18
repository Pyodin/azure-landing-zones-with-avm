# Modules

Local modules for the few things no [Azure Verified Module](https://azure.github.io/Azure-Verified-Modules/)
covers. Anything an AVM module already does is consumed from the registry instead, so
this directory stays small on purpose.

| Module | Purpose |
|---|---|
| `app-registration` | Entra ID application registration and its service principal: exposed scopes, app roles, pre-authorized clients, API permissions, federated credentials |

AVM does not publish Entra ID modules: the programme covers Azure resources, and a
directory object is not one.
