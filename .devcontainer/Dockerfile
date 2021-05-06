FROM hashicorp/terraform:0.14.9

# Install Azure CLI
RUN apk add --no-cache python3-dev musl-dev libffi-dev py3-pip gcc make openssl-dev jq curl bash && \
    pip install azure-cli