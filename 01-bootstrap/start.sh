sudo ansible-playbook -i /home/ubuntu/k8s-2026/01-bootstrap/inventory/production/hosts.ini playbooks/01-controller.yml -vv
sudo ansible-playbook -i /home/ubuntu/k8s-2026/01-bootstrap/inventory/production/hosts.ini playbooks/02-bootstrap.yml  -vv

