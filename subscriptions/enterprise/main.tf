module "runner-vm" {
    source   = "../../modules/runner-vm"
    
    admin_username = var.admin_username
    admin_password = var.admin_password

    github_org            = var.github_org
    github_access_token   = var.github_access_token

    create_bastion = false

    vms = {
        "E1" = {
            size = "Standard_B2s"
            disk_type = "StandardSSD_LRS"
        }
    }
}