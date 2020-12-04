resource "azurerm_resource_group" "vm" {
  name     = "GitHubRunners"
  location = var.location
}

resource "azurerm_virtual_network" "vm" {
  name                = "GitHubRunners"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
}

resource "azurerm_subnet" "vm" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.vm.name
  virtual_network_name = azurerm_virtual_network.vm.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "vm" {
  for_each            = var.vms
  name                = "GitHubRunner-${each.key}"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

data "template_file" "init_script" {
  template = file("${path.module}/init-runner.sh")

  vars = {
    github_runner_token = data.local_file.token_file.content
    github_org_url = "https://github.com/${var.github_org}"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each            = var.vms
  name                = "GitHubRunner-${each.key}"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = each.value.size
  
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  custom_data = base64encode(data.template_file.init_script.rendered)
  
  network_interface_ids = [
    azurerm_network_interface.vm[each.key].id,
  ]

  lifecycle {
    ignore_changes = [
      custom_data
    ]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = each.value.disk_type
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_2"
    version   = "latest"
  }
}