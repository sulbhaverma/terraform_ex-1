output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "nat_gateway_id" {
  value = azurerm_nat_gateway.nat.id
}

output "public_subnets" {
  value = [for s in azurerm_subnet.public : s.id]
}

output "private_subnets" {
  value = [for s in azurerm_subnet.private : s.id]
}
