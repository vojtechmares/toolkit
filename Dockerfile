FROM ubuntu:20.04 as base

# curl wget jq make git
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  openssh-client sshpass \
  zip unzip \
  curl \
  wget \
  host \
  jq \
  make \
  sudo \
  moreutils \
  git \
  gnupg2 \
  # required by aws cli
  less groff && \
  rm -rf /var/lib/apt/lists/* && \
  update-ca-certificates

# kubectl
FROM base as kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin

# helm
FROM base as helm
ENV HELM_VERSION=v3.9.3
RUN curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz \
  && tar xzvf helm.tar.gz \
  && mv linux-amd64/helm /usr/local/bin \
  && rm -r linux-amd64 helm.tar.gz

# terraform
FROM base as terraform
ENV TERRAFORM_VERSION=1.2.7
RUN curl -fsSL https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
  && unzip terraform.zip \
  && mv terraform /usr/local/bin \
  && rm -r terraform.zip

# doctl
FROM base as doctl
ENV DOCTL_VERSION=1.78.0
RUN curl -L https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz | tar xz \
  && mv doctl /usr/local/bin

# argocd
FROM base as argocd
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 \
  && chmod +x /usr/local/bin/argocd

# docker
FROM base as docker
ENV DOCKER_VERSION=20.10.13
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz -o docker.tgz \
  && tar xzvf docker.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -r docker docker.tgz

# docker compose
FROM base as docker_compose
ENV DOCKER_COMPOSE_VERSION=1.26.2
RUN curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose

# vault
FROM base as vault
ENV VAULT_VERSION=1.9.4
RUN curl -fsSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault.zip \
  && unzip vault.zip \
  && mv vault /usr/local/bin \
  && rm -r vault.zip

# go
FROM base as go
ENV GO_VERSION=1.19
RUN curl -fsSLO https://golang.org/dl/go${VERSION}.linux-amd64.tar.gz -o go.tar.gz \
  && tar xzvf go.tar.gz \
  && mv go/go /usr/local/bin/go \
  && chmod +x /usr/local/bin/go \
  && rm -r go.tar.gz

# hugo
FROM base as hugo
ENV HUGO_VERSION=0.101.0
RUN curl -fsSLO https://github.com/gohugoio/hugo/releases/download/v0.101.0/hugo_0.101.0_Linux-64bit.tar.gz -o /usr/local/bin/hugo \
  && chmod +x /usr/local/bin/hugo

# Final Image
FROM base

# Install aws cli v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip" && \
  unzip -q awscliv2.zip && \
  ./aws/install && \
  rm -rf awscliv2.zip aws

# TODO: Install from tar.gz
RUN curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

COPY --from=docker /usr/local/bin/docker /usr/local/bin
COPY --from=docker_compose /usr/local/bin/docker-compose /usr/local/bin
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin
COPY --from=helm /usr/local/bin/helm /usr/local/bin
COPY --from=terraform /usr/local/bin/terraform /usr/local/bin
COPY --from=vault /usr/local/bin/vault /usr/local/bin
COPY --from=doctl /usr/local/bin/doctl /usr/local/bin
COPY --from=argocd /usr/local/bin/argocd /usr/local/bin
COPY --from=go /usr/local/bin/go /usr/local/bin
COPY --from=hugo /usr/local/bin/hugo /usr/local/bin
COPY --from=vojtechmares/statica:stable /statica /usr/local/bin
