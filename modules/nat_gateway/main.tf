# NAT Gateway 用のパブリック IP（固定 egress IP）
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

# NAT Gateway。ACA のアウトバウンドに安定した単一パブリック IP を与える。
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

# NAT Gateway を 1 つ以上のサブネット（例: ACA サブネット）に関連付ける。
# 呼び出し側が定義する静的ラベルをキーにするため、subnet ID が apply 時に定まる
# 値であっても for_each は plan 時に確定する。
resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each       = var.subnets
  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.main.id
}
