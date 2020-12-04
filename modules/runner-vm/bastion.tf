resource "azurerm_subnet" "bastion" {
  count                = var.create_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.vm.name
  virtual_network_name = azurerm_virtual_network.vm.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "bastion" {
  count                = var.create_bastion ? 1 : 0
  name                = "GitHubRunners-Bastion"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "vm" {
  count                = var.create_bastion ? 1 : 0
  name                = "GitHubRunners"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}