SHELL := /bin/bash

FLUTTER ?= flutter
DOCKER ?= docker
HELM ?= helm
KUBECTL ?= kubectl
PYTHON ?= python3

NAMESPACE ?= fclipboard
DEFAULT_TAG := $(shell date +%Y%m%d%H%M%S)
DOCKER_PLATFORM ?= linux/amd64

REGISTRY ?= harbor.lingmind.cn/teabrew

WEB_IMAGE ?= $(REGISTRY)/fclipboard-web
WEB_TAG ?= $(DEFAULT_TAG)
WEB_IMAGE_REF := $(WEB_IMAGE):$(WEB_TAG)

BACKEND_IMAGE ?= $(REGISTRY)/fclipboard-backend
BACKEND_TAG ?= $(DEFAULT_TAG)
BACKEND_IMAGE_REF := $(BACKEND_IMAGE):$(BACKEND_TAG)

BASE_HREF ?= /
WEB_BUILD_DIR := build/web
WEB_OUTPUT_LINK := output

WEB_DOCKERFILE := web/Dockerfile
WEB_DOCKER_CONTEXT := .

BACKEND_DOCKERFILE := backend/Dockerfile
BACKEND_DOCKER_CONTEXT := backend
HELM_RELEASE ?= fclipboard-backend
HELM_CHART := backend/deploy/helm

DATABASE_URL ?= postgresql+psycopg2://fclipboard:fclipboard@$(HELM_RELEASE)-postgres:5432/fclipboard
JWT_SECRET ?= change-me
ACCESS_TOKEN_EXPIRE_MINUTES ?= 30
REFRESH_TOKEN_EXPIRE_DAYS ?= 7
CORS_ORIGINS ?= '["*"]'

.PHONY: help frontend-setup frontend-web-build frontend-web-output frontend-web-image frontend-web-push frontend-web-deploy backend-setup backend-run backend-image backend-push backend-deploy images push deploy release clean-output

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-24s\033[0m %s\n", $$1, $$2}'

frontend-setup: ## Install Flutter dependencies
	$(FLUTTER) pub get

frontend-web-build: ## Build the Flutter web bundle (respects BASE_HREF)
	$(FLUTTER) build web --release --base-href $(BASE_HREF)

frontend-web-output: frontend-web-build ## Symlink build/web to output for the web Docker build context
	@ln -sfn $(WEB_BUILD_DIR) $(WEB_OUTPUT_LINK)

frontend-web-image: frontend-web-output ## Build the web Docker image
	$(DOCKER) build --platform $(DOCKER_PLATFORM) -f $(WEB_DOCKERFILE) -t $(WEB_IMAGE_REF) $(WEB_DOCKER_CONTEXT)

frontend-web-push: frontend-web-image ## Push the web Docker image
	$(DOCKER) push $(WEB_IMAGE_REF)

frontend-web-deploy: ## Apply web manifests and roll the deployment to the new image
	$(KUBECTL) apply -n $(NAMESPACE) -f web/deploy

backend-setup: ## Create venv and install backend dependencies
	cd backend && $(PYTHON) -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt

backend-run: ## Run FastAPI locally with reload (requires backend-setup)
	cd backend && source .venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

backend-image: ## Build the backend Docker image
	$(DOCKER) build --platform $(DOCKER_PLATFORM) -f $(BACKEND_DOCKERFILE) -t $(BACKEND_IMAGE_REF) $(BACKEND_DOCKER_CONTEXT)

backend-push: backend-image ## Push the backend Docker image
	$(DOCKER) push $(BACKEND_IMAGE_REF)

backend-deploy: ## Deploy backend via Helm
	$(HELM) upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(NAMESPACE) --create-namespace \
		--values $(HELM_CHART)/values.yaml

images: frontend-web-image backend-image ## Build both web and backend images

push: frontend-web-push backend-push ## Push web and backend images

deploy: frontend-web-deploy backend-deploy ## Deploy web static files and backend

release: push deploy ## Build, push, and deploy both stacks end-to-end

clean-output: ## Remove the generated output link
	rm -rf $(WEB_OUTPUT_LINK)
