.PHONY: fmt fmt-check validate ci help

# Format all Terraform files
fmt:
	terraform fmt -recursive

# Check formatting
fmt-check:
	terraform fmt -check -recursive

# Validate Terraform configuration
validate:
	terraform validate

# Run the same checks CI runs
ci: fmt-check validate

# List available commands
help:
	@echo "Available commands:"
	@echo "  make fmt        - Format Terraform files"
	@echo "  make fmt-check  - Check Terraform formatting"
	@echo "  make validate   - Run terraform validate"
	@echo "  make ci         - Run all CI checks locally"
