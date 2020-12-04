terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "templatr"

    workspaces {
      name = "github-runners-premium-subscription"
    }
  }
}