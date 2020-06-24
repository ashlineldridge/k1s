cluster_name := k1s
region       := us-west-2
workspace    := $(cluster_name)-$(region)
build_dir    := target
plan_file    := $(build_dir)/$(workspace).tfplan
sh_src       := $(shell find . -type f -name '*.sh')

# Variables consumed by scripts
export MAKE := 1

# Variables consumed by Terraform
export TF_IN_AUTOMATION    := 1
export TF_VAR_cluster_name := $(cluster_name)
export TF_VAR_region       := $(region)

no_color := \033[0m
ok_color := \033[38;5;74m

# Function for printing a pretty banner
banner = \
	echo "\n$(ok_color)=====> $1$(no_color)"

# Function for checking that a variable is defined
check_defined = \
	$(if $(value $1),,$(error Error: Variable $1 ($2) is undefined))

.PHONY: clean
clean:
	@$(call banner,Cleaning)
	rm -rf ./$(build_dir) ./.terraform

.PHONY: lint
lint:
	@$(call banner,Linting Terraform)
	@terraform fmt -diff -check
	@$(call banner,Running Shfmt)
	@shfmt -i 2 -ci -sr -bn -d $(sh_src)
	@$(call banner,Running Shellcheck)
	@shellcheck $(sh_src)

$(build_dir):
	@mkdir -p $(build_dir)

.terraform/lock: backend.tf providers.tf
	@$(call banner,Initialising Terraform)
	@$(eval account_id := $(shell aws sts get-caller-identity --query Account --output text || kill $$PPID))
	@terraform init \
		-backend-config=region=ap-southeast-2 \
		-backend-config=bucket=terraform-$(account_id) \
		-backend-config=key=terraform.tfstate \
		-backend-config=dynamodb_table=terraform
	@touch .terraform/lock

init: .terraform/lock

.PHONY: validate
validate: init
	@$(call banner,Validating Terraform)
	terraform validate

.PHONY: $(workspace)
$(workspace): init
ifneq ($(shell terraform workspace show),$(workspace))
	@$(call banner,Selecting Terraform workspace $(workspace))
	@terraform workspace new $(workspace) 2> /dev/null || true
	@terraform workspace select $(workspace) > /dev/null
endif

.PHONY: plan
plan: $(workspace) $(build_dir)
	@$(call banner,Creating Terraform plan)
	terraform plan -out=$(plan_file)

.PHONY: apply
apply: $(workspace)
	@$(call banner,Applying Terraform plan)
	terraform apply $(plan_file)

.PHONY: refresh
refresh: $(workspace)
	@$(call banner,Refreshing Terraform)
	terraform refresh

.PHONY: destroy
destroy: $(workspace)
	@$(call banner,Destroying Terraform resources)
	TF_IN_AUTOMATION=0 terraform destroy

.PHONY: import
import: $(workspace)
	@$(call banner,Importing Terraform resource)
	@$(call check_defined,TERRAFORM_ID,Terraform identifier (e.g., "aws_iam_role.my_role"))
	@$(call check_defined,AWS_ID,AWS identifier (e.g., "my-role"))
	terraform import $(TERRAFORM_ID) $(AWS_ID)

.PHONY: console
console: $(workspace)
	@$(call banner,Starting Terraform console)
	terraform console

.PHONY: list
list: $(workspace)
	@$(call banner,Listing cluster instance information)
	@./scripts/list.sh

.PHONY: session
session:
	@$(call check_defined,INSTANCE_ID,ID of instance to connect to)
	@$(call banner,Establishing session with $(INSTANCE_ID))
	@./scripts/session.sh $(INSTANCE_ID) $(region)
