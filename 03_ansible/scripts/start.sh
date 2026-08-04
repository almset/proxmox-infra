#!/usr/bin/env bash
set -euo pipefail

INVENTORY="../plugins/inventory/terraform.py"
PLAYBOOKS="../playbooks"

ACTION=${1:-help}

case "$ACTION" in
    inventory)
        ansible-inventory -i "$INVENTORY" --graph
        ;;
    
    list)
        ansible-inventory -i "$INVENTORY" --list | jq
        ;;

    site)
        ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/site.yml" -vv
	#ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/site.yml" --limit bastion-prod-01
        ;;

    base)
        ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/base.yml" 
        ;;

    gateway)
        ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/infrastructure/gateway.yml"
        ;;

    dns)
        ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/infrastructure/dns.yml" 
        ;;
    
    firewall)
        ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/infrastructure/firewall.yml" 
        ;;
    
    resolver)
        ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/infrastructure/resolver.yml" 
        ;;

    security)
        ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/security/security.yml"
        ;;

    cluster)
        ansible-playbook -i "$INVENTORY" "$PLAYBOOKS/kubernetes/cluster.yml" -vv
        ;;

    ping)
        ansible linux -m ping
        ansible windows -m win_ping
        ;;

    hostcheck)
        ansible-inventory -i "$INVENTORY" --list \
        | jq -r '._meta.hostvars[].ansible_host' \
        | sort -u \
        | while read -r host; do
            ssh-keygen -R "$host" >/dev/null 2>&1 || true
        done
        ;;

    help)
        cat <<EOF
Usage:
  ./start.sh inventory   Show dynamic inventory
  ./start.sh ping        Test Linux and Windows connectivity
  ./start.sh hostcheck   Remove SSH host keys

  ./start.sh base        Configure base hosts
  ./start.sh security    Apply security baseline
  ./start.sh gateway     Configure gateway
  ./start.sh dns         Configure DNS
  ./start.sh cluster     Configure Kubernetes cluster
  ./start.sh site        Configure entire infrastructure
EOF
        ;;

    *)
        echo "Unknown action: $ACTION"
        exit 1
        ;;
esac
