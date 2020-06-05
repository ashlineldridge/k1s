cluster_name := k1s
region       := us-west-1
workspace    := k1s-$(region)
build_dir    := target
plan_file    := $(build_dir)/$(workspace).tfplan
sh_src       := $(shell find . -type f -name '*.sh')

# Variables consumed by Terraform
export TF_IN_AUTOMATION    := 1
export TF_VAR_cluster_name := $(cluster_name)
export TF_VAR_region       := $(region)

no_color := \033[0m
ok_color := \033[38;5;74m
em_color := \033[34;01m
ul_on    := \033[4m
ul_off   := \033[24m

# Function for printing a pretty banner
banner = \
	@echo "\n$(ok_color)$(em_color)=====> $1$(no_color)"

# Function for checking that a variable is defined
check_defined = \
	$(if $(value $1),,$(error Error: Variable $1 ($2) is undefined))

.PHONY: clean
clean:
	$(call banner,Cleaning)
	rm -rf ./$(build_dir) ./.terraform

.PHONY: lint
lint:
	$(call banner,Linting Terraform)
	@terraform fmt -diff -check
	$(call banner,Running Shfmt)
	@shfmt -i 2 -ci -sr -bn -d $(sh_src)
	$(call banner,Running Shellcheck)
	@shellcheck $(sh_src)

$(build_dir):
	@mkdir -p $(build_dir)

.PHONY: init
init:
	$(call banner,Initialising Terraform)
	$(eval account_id := $(shell aws sts get-caller-identity --query Account --output text || kill $$PPID))
	@terraform init \
		-backend-config=region=ap-southeast-2 \
		-backend-config=bucket=terraform-$(account_id) \
		-backend-config=key=terraform.tfstate \
		-backend-config=dynamodb_table=terraform \

.PHONY: validate
validate: init
	$(call banner,Validating Terraform)
	terraform validate

.PHONY: $(workspace)
$(workspace): $(build_dir) init
	@terraform workspace new $(workspace) 2> /dev/null || true
	@terraform workspace select $(workspace) > /dev/null

.PHONY: plan
plan: $(workspace)
	$(call banner,Creating Terraform plan)
	terraform plan -out=$(plan_file)

.PHONY: apply
apply: $(workspace)
	$(call banner,Applying Terraform plan)
	terraform apply $(plan_file)

.PHONY: refresh
refresh: $(workspace)
	$(call banner,Refreshing Terraform)
	terraform refresh

.PHONY: destroy
destroy: $(workspace)
	$(call banner,Destroying Terraform resources)
	TF_IN_AUTOMATION=0 terraform destroy

.PHONY: import
import: $(workspace)
	$(call banner,Importing Terraform resource)
	$(call check_defined,TERRAFORM_ID,Terraform identifier (e.g., "aws_iam_role.my_role"))
	$(call check_defined,AWS_ID,AWS identifier (e.g., "my-role"))
	terraform import $(TERRAFORM_ID) $(AWS_ID)

.PHONY: list
list:
	$(call banner,Listing cluster instances)
	./scripts/list.sh $(cluster_name) $(region)

.PHONY: session
session:
	$(call banner,Listing cluster instances)
	$(call check_defined,INSTANCE_ID,ID of instance to connect to)
	./scripts/session.sh $(INSTANCE_ID) $(region)
