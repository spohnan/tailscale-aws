#
# Run `make` in the current directory to see targets of interest
#

SSH_ALLOWED_IPS := '0.0.0.0/0'
SSH_KEY := 'ts'
STACK_NAME := 'tailscale-demo'
TEMPLATE := 'templates/tailscale-demo.yaml'

about:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: about

cfn-lint-exists: ; @type cfn-lint > /dev/null
.PHONY: cfn-lint-exists

delete: ## Delete the demo stack
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@aws cloudformation delete-stack \
		--stack-name $(STACK_NAME)
.PHONY: delete

deploy: ## Deploy the demo stack
	@aws cloudformation deploy \
		--stack-name $(STACK_NAME) \
		--template-file $(TEMPLATE) \
		--parameter-overrides \
			SshAllowedIPs=$(SSH_ALLOWED_IPS) \
			SshKey=$(SSH_KEY)
.PHONY: deploy

lint: cfn-lint-exists ## Lint templates
	@echo 'CloudFormation Lint Checks'
	@cfn-lint templates/*.yaml
	@echo 'YAML Lint Checks'
	@yamllint templates
.PHONY: lint
