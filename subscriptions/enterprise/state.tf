terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "techcentr"

    workspaces {
      name = "org-github-runners-enterprise"
    }
  }
}