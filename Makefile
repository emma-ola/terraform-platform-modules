.PHONY: fmt fmt-check validate ci lint security help

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -check -recursive

validate:
	terraform validate

ci: fmt-check validate lint security

lint:
	tflint --init
	tflint --recursive

security:
	tfsec --format sarif --out tfsec.sarif .

# List available commands
help:
	@echo "Available commands:"
	@echo "  make fmt        - Format Terraform files"
	@echo "  make fmt-check  - Check Terraform formatting"
	@echo "  make validate   - Run terraform validate"
	@echo "  make ci         - Run all CI checks locally"
