ENV ?= linux

TG_PATH := ../live/production/$(ENV)

init:
	cd $(TG_PATH) && terragrunt init

plan:
	cd $(TG_PATH) && terragrunt plan

apply:
	cd $(TG_PATH) && terragrunt apply -- -auto-approve -parallelism=3

test:
	cd $(TG_PATH) && terragrunt apply -- -target='module.vm_regular["worker-k8s-prod-01"]' -auto-approve -parallelism=3

destroy:
	cd $(TG_PATH) && terragrunt destroy -auto-approve

fmt:
	terraform fmt -recursive

validate:
	cd $(TG_PATH) && terragrunt validate

output:
	cd $(TG_PATH) && terragrunt output 

json:
	cd $(TG_PATH) && terragrunt output -json > output.json

inventory:
	./terraform.py --list --file ../live/production/linux/output.json ../live/production/windows/output.json

state:
	cd $(TG_PATH) && terragrunt state list

unlock:
	@LOCK=$$(grep unlock_address $$(find . -name backend.tf | head -1) | cut -d'"' -f2); \
	echo $$LOCK; \
	curl --request DELETE \
	     -u root:$(GITLAB_TOKEN) \
	     $$LOCK
