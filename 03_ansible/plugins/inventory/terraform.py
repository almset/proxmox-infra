#!/usr/bin/env python3
"""
tf-inventory v0.8 - Dynamic Inventory для Ansible из Terraform output
С автоопределением режима (inside/outside)
"""
import json
import sys
import os
import argparse
import re
import socket
import ipaddress
from pathlib import Path


class InventoryError(Exception):
    pass


class TerraformInventory:
    # Поля, которые не создают группы
    RESERVED_FIELDS = {
        'ansible_host',
        'management_ip',
        'vm_id',
        'ansible_user',
        'ansible_password',
        'ansible_ssh_private_key_file',
        'ansible_connection',
        'ansible_python_interpreter',
        'ansible_ssh_common_args'
    }
    
    # Роли, которые доступны напрямую извне (имеют management_ip)
    DIRECT_ACCESS_ROLES = {'bastion', 'router'}
    
    # Режимы работы
    MODE_OUTSIDE = 'outside'
    MODE_INSIDE = 'inside'
    MODE_AUTO = 'auto'
    
    def __init__(self, file_path="output.json", debug=False, 
                 bastion_host=None, mode=MODE_AUTO):
        self.file_path = file_path
        self.debug = debug
        self.bastion_host = bastion_host
        self.mode = mode
        self._raw_data = None
        self._inventory = None
        self._warnings = []
        self._resolved_mode = None
    
    def _log(self, message):
        if self.debug:
            print(message, file=sys.stderr)
    
    @staticmethod
    def _sanitize_group_name(name):
        sanitized = re.sub(r'[^a-zA-Z0-9_]', '_', str(name))
        if sanitized and sanitized[0].isdigit():
            sanitized = '_' + sanitized
        return sanitized
    
    def load(self):
        if not os.path.exists(self.file_path):
            raise FileNotFoundError(f"File not found: {self.file_path}")
        
        try:
            with open(self.file_path, 'r') as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in {self.file_path}: {e}")
        
        if "inventory" not in data or "value" not in data["inventory"]:
            raise ValueError("Invalid structure: missing 'inventory.value'")
        
        self._raw_data = data["inventory"]["value"]
        return self
    
    def validate(self):
        if self._raw_data is None:
            raise InventoryError("Data not loaded. Call load() first.")
        
        self._warnings = []
        
        for hostname, host_vars in self._raw_data.items():
            if "ansible_host" not in host_vars:
                self._warnings.append(f"Host '{hostname}' missing 'ansible_host'")
            if not isinstance(host_vars, dict):
                raise ValueError(f"Host '{hostname}' must be a dictionary")
        
        return self
    
    def _is_ip_address(self, value):
        ip_pattern = r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
        return bool(re.match(ip_pattern, str(value)))
    
    @staticmethod
    def _get_local_networks():
        """Получить список локальных сетей контроллера"""
        networks = []
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            if local_ip != '127.0.0.1':
                networks.append(ipaddress.ip_network(f"{local_ip}/24", strict=False))
        except Exception:
            pass
        return networks
    
    def _detect_mode(self, combined_data):
        """Автоопределение режима: внутри сети или снаружи"""
        local_nets = self._get_local_networks()
        self._log(f"Local networks detected: {[str(n) for n in local_nets]}")
        
        if not local_nets:
            self._log("Could not detect local networks, defaulting to 'outside'")
            return self.MODE_OUTSIDE
        
        for hostname, host_vars in combined_data.items():
            if host_vars.get('role') in self.DIRECT_ACCESS_ROLES:
                continue
            
            ansible_host = host_vars.get('ansible_host')
            if not ansible_host or not self._is_ip_address(ansible_host):
                continue
            
            try:
                host_ip = ipaddress.ip_address(ansible_host)
                for net in local_nets:
                    if host_ip in net:
                        self._log(f"Host '{hostname}' ({ansible_host}) is in local network {net}")
                        return self.MODE_INSIDE
            except ValueError:
                continue
        
        return self.MODE_OUTSIDE
    
    def _enrich_host_vars(self, hostname, host_vars):
        """
        Обогащение переменных хоста:
        - Для bastion/router в режиме outside: ansible_host = management_ip
        - Остальные SSH-настройки (ProxyCommand, ключи) — в group_vars!
        """
        enriched = dict(host_vars)
        role = host_vars.get('role', '')
        resolved_mode = self._resolved_mode
        
        if resolved_mode == self.MODE_INSIDE:
            # Внутри сети: все хосты используют ansible_host (внутренний IP)
            self._log(f"Host '{hostname}': inside mode, direct connection")
            
        elif resolved_mode == self.MODE_OUTSIDE:
            # Снаружи: bastion/router используют management_ip
            if role in self.DIRECT_ACCESS_ROLES and 'management_ip' in host_vars:
                enriched['ansible_host'] = host_vars['management_ip']
                self._log(f"Host '{hostname}' ({role}): ansible_host = {enriched['ansible_host']}")
            
            # ВАЖНО: ProxyCommand/ProxyJump НЕ устанавливаем здесь!
            # Это делает group_vars/linux.yml
        
        return enriched
    
    def build(self):
        if self._raw_data is None:
            raise InventoryError("Data not loaded. Call load() first.")
        
        if self._inventory is not None:
            return self._inventory
        
        self._inventory = {
            "_meta": {"hostvars": {}},
            "all": {"hosts": [], "children": []}
        }
        
        for hostname, host_vars in self._raw_data.items():
            self._inventory["all"]["hosts"].append(hostname)
            enriched_vars = self._enrich_host_vars(hostname, host_vars)
            self._inventory["_meta"]["hostvars"][hostname] = enriched_vars
            
            for field, value in host_vars.items():
                if field not in self.RESERVED_FIELDS and isinstance(value, str):
                    if not self._is_ip_address(value):
                        self._add_host_to_group(value, hostname)
        
        return self._inventory
    
    def _add_host_to_group(self, group_name, hostname):
        safe_group_name = self._sanitize_group_name(group_name)
        
        if safe_group_name != group_name:
            self._log(f"Group name normalized: '{group_name}' -> '{safe_group_name}'")
        
        if safe_group_name not in self._inventory:
            self._inventory[safe_group_name] = {"hosts": [], "vars": {}}
            if safe_group_name not in self._inventory["all"]["children"]:
                self._inventory["all"]["children"].append(safe_group_name)
        
        if hostname not in self._inventory[safe_group_name]["hosts"]:
            self._inventory[safe_group_name]["hosts"].append(hostname)
    
    def get_warnings(self):
        return self._warnings
    
    def list_inventory(self):
        return self.build()
    
    def get_host_vars(self, hostname):
        inventory = self.build()
        return inventory["_meta"]["hostvars"].get(hostname, {})


def find_terraform_outputs(root_dir=None):
    if root_dir is None:
        root_dir = os.environ.get('TF_INVENTORY_ROOT', '../../04_terragrunt/live/')
    
    root_path = Path(root_dir)
    
    if not root_path.exists():
        raise FileNotFoundError(f"Root directory not found: {root_dir}")
    if not root_path.is_dir():
        raise ValueError(f"Path is not a directory: {root_dir}")
    
    output_files = []
    for path in root_path.rglob("output.json"):
        if any(part in ('.terragrunt-cache', '.terraform') for part in path.parts):
            continue
        output_files.append(path)
    
    return sorted(output_files)


def find_bastion_host(combined_data):
    """Автоматический поиск bastion-хоста в данных"""
    for hostname, host_vars in combined_data.items():
        if host_vars.get('role') == 'bastion':
            return hostname
    return None


def main():
    parser = argparse.ArgumentParser(
        description="Dynamic Inventory для Ansible из Terraform output"
    )
    parser.add_argument("--list", action="store_true", help="Вывести полный инвентарь")
    parser.add_argument("--host", type=str, help="Вывести переменные для конкретного хоста")
    parser.add_argument("--root", type=str, help="Корневая директория для поиска output.json")
    parser.add_argument("--debug", action="store_true", help="Включить отладочный вывод")
    parser.add_argument(
        "--bastion",
        type=str,
        help="Имя bastion-хоста для ProxyJump (автоопределение, если не указано)"
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=['auto', 'inside', 'outside'],
        default=None,
        help="Режим работы: auto (по умолчанию), inside (внутри сети), outside (снаружи)"
    )
    
    args = parser.parse_args()
    
    try:
        output_files = find_terraform_outputs(args.root)
        
        if args.debug:
            print(f"Found {len(output_files)} output.json file(s):", file=sys.stderr)
            for f in output_files:
                print(f"  - {f}", file=sys.stderr)
        
        if not output_files:
            empty_inv = {"_meta": {"hostvars": {}}, "all": {"hosts": [], "children": []}}
            if args.list:
                print(json.dumps(empty_inv, indent=2))
            elif args.host:
                print(json.dumps({}, indent=2))
            sys.exit(0)
        
        combined_data = {}
        all_warnings = []
        
        for file_path in output_files:
            try:
                inv = TerraformInventory(file_path=str(file_path), debug=args.debug)
                inv.load().validate()
                combined_data.update(inv._raw_data)
                all_warnings.extend(inv.get_warnings())
            except (ValueError, InventoryError) as e:
                if args.debug:
                    print(f"Warning: Skipping {file_path}: {e}", file=sys.stderr)
        
        if not combined_data:
            print("Error: No valid inventory data found", file=sys.stderr)
            sys.exit(1)
        
        # Определяем bastion-хост
        bastion_host = args.bastion or find_bastion_host(combined_data)
        if args.debug and bastion_host:
            print(f"Using bastion host: {bastion_host}", file=sys.stderr)
        
        # Определяем режим работы
        mode = args.mode or os.environ.get('TF_INVENTORY_MODE', 'auto')
        
        final_inv = TerraformInventory(
            debug=args.debug,
            bastion_host=bastion_host,
            mode=mode
        )
        final_inv._raw_data = combined_data
        
        # Если auto — определяем режим
        if mode == 'auto':
            resolved_mode = final_inv._detect_mode(combined_data)
            final_inv._resolved_mode = resolved_mode
            if args.debug:
                print(f"Auto-detected mode: {resolved_mode}", file=sys.stderr)
        else:
            final_inv._resolved_mode = mode
            if args.debug:
                print(f"Using explicit mode: {mode}", file=sys.stderr)
        
        final_inv.validate().build()
        
        for warning in final_inv.get_warnings():
            print(f"Warning: {warning}", file=sys.stderr)
        
        if args.list:
            result = final_inv.list_inventory()
            print(json.dumps(result, indent=2))
        elif args.host:
            result = final_inv.get_host_vars(args.host)
            print(json.dumps(result, indent=2))
        else:
            parser.print_help()
            sys.exit(1)
    
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except InventoryError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
