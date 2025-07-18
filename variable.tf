variable "location" {
  default = "eastus"
}

variable "resource_group_name" {
  default = "rg-networking"
}

variable "vnet_name" {
  default = "vnet-main"
}

variable "vnet_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  default = [
    { name = "public-subnet-1", cidr = "10.0.1.0/24" },
    { name = "public-subnet-2", cidr = "10.0.2.0/24" }
  ]
}

variable "private_subnets" {
  default = [
    { name = "private-subnet-1", cidr = "10.0.10.0/24" },
    { name = "private-subnet-2", cidr = "10.0.11.0/24" }
  ]
}

variable "nsg_rules" {
  description = "List of dynamic NSG rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = [
    {
      name                       = "AllowHTTP"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}
