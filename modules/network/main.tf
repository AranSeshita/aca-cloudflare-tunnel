# 仮想ネットワーク（VNet）
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# サブネット。var.subnets で完全に駆動する。モジュール自身はサブネットを一切定義せず、
# 追加は tfvars を編集するだけ（拡張可能・モジュール改変不要）。
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                              = "snet-${var.project_name}-${var.environment}-${each.key}"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = each.value.address_prefixes
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]
    content {
      name = replace(delegation.value.name, "/", "-")
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}

# サブネットごとに 1 つの NSG
resource "azurerm_network_security_group" "this" {
  for_each = var.subnets

  name                = "nsg-${var.project_name}-${var.environment}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# サブネットごとの nsg_rules を "<subnet>.<rule>" をキーにした単一マップへ flatten する。
# キーは tfvars のデータから静的に決まるため for_each は plan 時に安全。
locals {
  nsg_rules = merge([
    for sname, s in var.subnets : {
      for rname, r in s.nsg_rules :
      "${sname}.${rname}" => merge(r, { subnet = sname, rule_name = rname })
    }
  ]...)
}

resource "azurerm_network_security_rule" "this" {
  for_each = local.nsg_rules

  name                        = each.value.rule_name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
