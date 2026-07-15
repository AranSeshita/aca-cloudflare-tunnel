# Public IP for the NAT Gateway (fixed egress IP)
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

# NAT Gateway. Gives ACA outbound traffic a stable, single public IP.
resource "azurerm_nat_gateway" "main" {
  name                    = "nat-${var.project_name}-${var.environment}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associates the NAT Gateway with one or more subnets (e.g. the ACA subnet).
# Keys are static labels defined by the caller, so for_each is resolvable at
# plan time even when the subnet IDs are apply-time computed values.
resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each       = var.subnets
  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.main.id
}
