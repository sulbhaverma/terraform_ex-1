provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

# NAT Gateway
resource "azurerm_public_ip" "nat_ip" {
  name                = "nat-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nat-gateway"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"

  public_ip_ids = [azurerm_public_ip.nat_ip.id]
}

# Public Subnets
resource "azurerm_subnet" "public" {
  for_each = { for subnet in var.public_subnets : subnet.name => subnet }

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr]
}

# Private Subnets
resource "azurerm_subnet" "private" {
  for_each = { for subnet in var.private_subnets : subnet.name => subnet }

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value.cidr]

  delegation {
    name = "natDelegation"
    service_delegation {
      name = "Microsoft.Network/natGateways"
    }
  }
}

# Associate NAT Gateway to private subnets
resource "azurerm_subnet_nat_gateway_association" "nat_assoc" {
  for_each = azurerm_subnet.private

  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# NSGs and Route Tables for all subnets
resource "azurerm_network_security_group" "nsg" {
  for_each = merge(
    { for subnet in var.public_subnets : subnet.name => subnet },
    { for subnet in var.private_subnets : subnet.name => subnet }
  )

  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = azurerm_network_security_group.nsg

  subnet_id                 = try(azurerm_subnet.public[each.key].id, azurerm_subnet.private[each.key].id)
  network_security_group_id = each.value.id
}

resource "azurerm_route_table" "rt" {
  for_each = merge(
    { for subnet in var.public_subnets : subnet.name => subnet },
    { for subnet in var.private_subnets : subnet.name => subnet }
  )

  name                = "${each.key}-rt"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each = azurerm_route_table.rt

  subnet_id      = try(azurerm_subnet.public[each.key].id, azurerm_subnet.private[each.key].id)
  route_table_id = each.value.id
}
