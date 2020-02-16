#
# Run `make` in the current directory to see targets of interest
#

about:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.PHONY: about

cfn-lint-exists: ; @type cfn-lint > /dev/null
.PHONY: cfn-lint-exists

lint: cfn-lint-exists ## Check templates and code using linters if installed
	@echo 'CloudFormation Lint Checks'
	@find . -path "templates" -name "*.yaml" -exec cfn-lint {} \;
	@echo 'YAML Lint Checks'
	@find . -path "templates" -name "*.yaml" -exec yamllint {} \;
.PHONY: check
