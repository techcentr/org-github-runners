locals {
  token_filename = uuid()
}

resource "null_resource" "token_request" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "curl -f -s -X POST -H \"Authorization: token ${var.github_access_token}\" -H \"Accept: application/vnd.github.v3+json\" https://api.github.com/orgs/${var.github_org}/actions/runners/registration-token | jq -rc '.token' | tr -d '\n' > /tmp/${local.token_filename}"
  }
}

data "local_file" "token_file" {
    filename = "/tmp/${local.token_filename}"

    depends_on = [
        null_resource.token_request
    ]
}