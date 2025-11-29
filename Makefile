SHELL := /bin/bash

FLUTTER ?= flutter
DOCKER ?= docker
KUBECTL ?= kubectl

NAMESPACE ?= fclipboard
DEFAULT_TAG := $(shell date +%Y%m%d%H%M%S)
DOCKER_PLATFORM ?= linux/amd64

REGISTRY ?= harbor.lingmind.cn/teabrew
WEB_IMAGE ?= $(REGISTRY)/fclipboard-web
WEB_TAG ?= $(DEFAULT_TAG)
WEB_IMAGE_REF := $(WEB_IMAGE):$(WEB_TAG)

PROVIDER_IMAGE ?= shoppon/fclipboard-provider
PROVIDER_TAG ?= $(DEFAULT_TAG)
PROVIDER_IMAGE_REF := $(PROVIDER_IMAGE):$(PROVIDER_TAG)

BASE_HREF ?= /
WEB_BUILD_DIR := build/web
WEB_OUTPUT_LINK := output

WEB_DOCKERFILE := web/Dockerfile
WEB_DOCKER_CONTEXT := .
PROVIDER_DOCKERFILE := provider/Dockerfile
PROVIDER_DOCKER_CONTEXT := provider

.PHONY: help web-build web-output web-image web-push web-deploy provider-image provider-push provider-deploy images push deploy release clean-output

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

web-build: ## Build the Flutter web bundle (respects BASE_HREF)
	$(FLUTTER) build web --release --base-href $(BASE_HREF)

web-output: web-build ## Symlink build/web to output for the web Docker build context
	@ln -sfn $(WEB_BUILD_DIR) $(WEB_OUTPUT_LINK)

web-image: web-output ## Build the web Docker image
	$(DOCKER) build --platform $(DOCKER_PLATFORM) -f $(WEB_DOCKERFILE) -t $(WEB_IMAGE_REF) $(WEB_DOCKER_CONTEXT)

web-push: web-image ## Push the web Docker image
	$(DOCKER) push $(WEB_IMAGE_REF)

web-deploy: ## Apply web manifests and roll the deployment to the new image
	$(KUBECTL) apply -n $(NAMESPACE) -f web/deploy

provider-image: ## Build the provider Docker image
	$(DOCKER) build --platform $(DOCKER_PLATFORM) -f $(PROVIDER_DOCKERFILE) -t $(PROVIDER_IMAGE_REF) $(PROVIDER_DOCKER_CONTEXT)

provider-push: provider-image ## Push the provider Docker image
	$(DOCKER) push $(PROVIDER_IMAGE_REF)

provider-deploy: ## Apply provider manifests and roll the deployment to the new image
	$(KUBECTL) apply -n $(NAMESPACE) -f provider/deploy

images: web-image provider-image ## Build both Docker images

push: web-push provider-push ## Push both Docker images

deploy: web-deploy provider-deploy ## Apply both stacks and roll deployments

release: push deploy ## Build, push, and deploy everything end-to-end

clean-output: ## Remove the generated output link
	rm -rf $(WEB_OUTPUT_LINK)
