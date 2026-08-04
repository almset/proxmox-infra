# Использование
# Один хост:
# make security LIMIT=router-prod-01
#
# Несколько:
# make security LIMIT="router-prod-01,dns-prod-01"
#
# Группа:
# make security LIMIT=linux
#
# По шаблону:
# make security LIMIT="worker-k8s-*"

LIMIT ?= all

.PHONY: base security gateway dns cluster site inventory ping

base:
	ansible-playbook ../playbooks/base.yml --limit "$(LIMIT)"

security:
	ansible-playbook ../playbooks/security/security.yml --limit "$(LIMIT)"

gateway:
	ansible-playbook ../playbooks/infrastructure/gateway.yml --limit "$(LIMIT)"

dns:
	ansible-playbook ../playbooks/infrastructure/dns.yml --limit "$(LIMIT)"

cluster:
	ansible-playbook ../playbooks/platform/cluster.yml --limit "$(LIMIT)"

site:
	ansible-playbook ../playbooks/site.yml --limit "$(LIMIT)"

inventory:
	ansible-inventory --graph

ping:
	ansible linux -m ping --limit "$(LIMIT)"
	ansible windows -m win_ping --limit "$(LIMIT)"
