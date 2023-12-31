SHELL := /usr/bin/env bash
__FILENAME := $(lastword $(MAKEFILE_LIST))
__DIRNAME := $(abspath $(realpath $(lastword $(MAKEFILE_LIST)))/../)

help: ## Show this help.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

.PHONY: lint_chart
lint_chart: ## Checks the configured helm chart template definitions against the remote schema
lint_chart:
	@set -euo pipefail; \
	helm dep up ./cas-obps-postgres; \
	helm template -f ./cas-obps-postgres/values-dev.yaml cas-obps-postgres ./cas-obps-postgres --validate;


check_environment: ## Making sure the environment is properly configured for helm
check_environment:
	@set -euo pipefail; \
	if [ -z '$(OBPS_NAMESPACE_PREFIX)' ]; then \
		echo "OBPS_NAMESPACE_PREFIX is not set"; \
		exit 1; \
	fi; \
	if [ -z '$(ENVIRONMENT)' ]; then \
		echo "ENVIRONMENT is not set"; \
		exit 1; \
	fi; \


.PHONY: install
install: ## Installs the helm chart on the OpenShift cluster
install: check_environment
install:
install: GIT_SHA1=$(shell git rev-parse HEAD)
install: IMAGE_TAG=$(GIT_SHA1)
install: NAMESPACE=$(OBPS_NAMESPACE_PREFIX)-$(ENVIRONMENT)
install: CHART_DIR=./cas-obps-postgres
install: CHART_INSTANCE=cas-obps-postgres
install: HELM_OPTS=--atomic --wait-for-jobs --timeout 2400s --namespace $(NAMESPACE) \
										--set defaultImageTag=$(IMAGE_TAG) \
										--values $(CHART_DIR)/values-$(ENVIRONMENT).yaml
install:
	@set -euo pipefail; \
	helm dep up $(CHART_DIR); \
	if ! helm status --namespace $(NAMESPACE) $(CHART_INSTANCE); then \
		echo 'Installing the application'; \
		helm install $(HELM_OPTS) $(CHART_INSTANCE) $(CHART_DIR); \
	else \
		helm upgrade $(HELM_OPTS) $(CHART_INSTANCE) $(CHART_DIR); \
	fi;
