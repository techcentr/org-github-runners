variable location {
    default = "East US"
}

variable vms {
    type=map
}

variable create_bastion {
    default=false
}

variable admin_username {}
variable admin_password {}

variable github_org {}
variable github_access_token {}