FROM ubuntu:22.04 as base

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

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
  # podman, buildah and qemu-user-static for buildah multi-architecture builds
  podman buildah qemu-user-static \
  # required by aws cli
  less groff && \
  rm -rf /var/lib/apt/lists/* && \
  update-ca-certificates

# kubectl
FROM base as kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin

# helm
FROM base as helm
ENV HELM_VERSION=v3.12.3
RUN curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz \
  && tar xzvf helm.tar.gz \
  && mv linux-amd64/helm /usr/local/bin \
  && rm -r linux-amd64 helm.tar.gz

# terraform
FROM base as terraform
ENV TERRAFORM_VERSION=1.5.7
RUN curl -fsSL https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
  && unzip terraform.zip \
  && mv terraform /usr/local/bin \
  && rm -r terraform.zip

# doctl
FROM base as doctl
ENV DOCTL_VERSION=1.99.0
RUN curl -L https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz | tar xz \
  && mv doctl /usr/local/bin

# argocd
FROM base as argocd
RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 \
  && chmod +x /usr/local/bin/argocd

# docker
FROM base as docker
ENV DOCKER_VERSION=23.0.3
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  && mv docker-${DOCKER_VERSION}.tgz docker.tgz \
  && tar xzvf docker.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -r docker docker.tgz

# docker compose
FROM base as docker_compose
ENV DOCKER_COMPOSE_VERSION=2.19.1
RUN curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose

# vault
FROM base as vault
ENV VAULT_VERSION=1.14.0
RUN curl -fsSL https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -o vault.zip \
  && unzip vault.zip \
  && mv vault /usr/local/bin \
  && rm -r vault.zip

# go
FROM base as go
ENV GO_VERSION=1.20
RUN curl -fsSLO https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz \
  && mv go${GO_VERSION}.linux-amd64.tar.gz go.tar.gz \
  && tar xzvf go.tar.gz \
  && mv go/bin/go /usr/local/bin \
  && mv go/bin/gofmt /usr/local/bin \
  && chmod +x /usr/local/bin/go \
  && chmod +x /usr/local/bin/gofmt \
  && rm -r go \
  && rm -r go.tar.gz

# hugo
FROM base as hugo
ENV HUGO_VERSION=0.115.0
RUN curl -fsSLO https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz \
  && mv hugo_${HUGO_VERSION}_Linux-64bit.tar.gz hugo.tar.gz \
  && tar xzvf hugo.tar.gz \
  && mv hugo /usr/local/bin \
  && chmod +x /usr/local/bin/hugo \
  && rm -r hugo.tar.gz

# Final Image
FROM base

# Install aws cli v2
ENV AWS_CLI_VERSION=2.12.6
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
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
COPY --from=go /usr/local/bin/gofmt /usr/local/bin
COPY --from=hugo /usr/local/bin/hugo /usr/local/bin
