# GitHub Self-Hosted Runners

This repo contains a reusable Terraform module which creates an Azure Linux VM, virtual network and (optionally) a bastion host. This functionality is defined as a reusable module to allow creating separate groups of runners across multiple subscriptions.

## Execution
There is a module for each Azure subscription. Execute each of them separately using `terraform apply`. All variables are stored in Terraform Cloud which means you must sign in using the `terraform login` command before running the init and apply commands.

This repo is not connected to TF Cloud using VCS integration, given that the module needs to be only executed from time to time, it should be executed locally (e.g. from a Docker container).

## GitHub authentication
When adding a new runner, it has to join using a special token. The token itself is valid for only an hour so storing it in the Terraform variables is not really practical. To work around this limitition, the module can make an HTTP call to GitHub API to retrieve this token using a Personal Access Token. 

This causes a small inconvenience - the token is fetched each time and therefore the init script would differ during each execution. As a consequence, Terraform would always detect a difference and would try to re-create the VM which is not desirable. For this reason, differences in the init script are ignored and if you need to re-create the VM with a new script, use the `terraform taint` command.

## Bastion host - warning
Create the bastion host only when debugging and then destroy it. It costs more than the VMs themselves :)

## UID & GID

The GitHub runners runs as `github-runner` user (UID `8000`) who is a member of the `github-admin` group (GID `8000`) because running the runner as root is insecure (the action could effectively destroy the whole machine). This unfortunately creates challenges in the following situations when running jobs/steps in Docker containers which run with root UID by default. These actions may create files which are readable/writable only by root and subsequent builds fail because they can't delete these files.

To workaround this issue, all docker containers are by default created with `--user <UID>:<GID>` of the user who executed the docker command. For the containers created by the GitHub runner this means they are created with `--user 8000:8000`. In case this does not work with some specific action/docker image, you can override this behaviour by setting the `DOCKER_USER_OPTION` environment variable. You can:
- set the variable to `""` which will revert to default Docker engine behaviour (i.e. will start the container as root)
- set the variable to a custom `<UID>:<GID>` which will start the Docker container with the passed value. You can also use placeholders `$UID` and `$GID` for UID and GID of the user who executed the Docker command.