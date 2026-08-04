import pytest


def test_invalid_cidr_rejected(host):
    """Роль должна отказать при невалидном CIDR"""
    result = host.run(
        "ansible-playbook -i localhost, -c local "
        "-e 'gateway_internal_network=not-a-cidr "
        "gateway_external_interface=eth0 "
        "gateway_internal_interface=eth1' "
        "/tmp/test_broken_cidr.yml"
    )
    # Плейбук должен завершиться ошибкой
    assert result.rc != 0


def test_invalid_interface_rejected(host):
    """Роль должна отказать при несуществующем интерфейсе"""
    result = host.run(
        "ansible-playbook -i localhost, -c local "
        "-e 'gateway_internal_network=192.168.100.0/24 "
        "gateway_external_interface=eth999 "
        "gateway_internal_interface=eth1' "
        "/tmp/test_broken_iface.yml"
    )
    assert result.rc != 0


@pytest.fixture(autouse=True)
def setup_test_playbooks(host):
    """Создаём минимальные плейбуки для негативных тестов"""
    host.run(
        "cat > /tmp/test_broken_cidr.yml << 'EOF'\n"
        "---\n"
        "- hosts: localhost\n"
        "  become: true\n"
        "  gather_facts: true\n"
        "  roles:\n"
        "    - role: gateway\n"
        "EOF"
    )
    host.run(
        "cat > /tmp/test_broken_iface.yml << 'EOF'\n"
        "---\n"
        "- hosts: localhost\n"
        "  become: true\n"
        "  gather_facts: true\n"
        "  roles:\n"
        "    - role: gateway\n"
        "EOF"
    )
    yield
    host.run("rm -f /tmp/test_broken_cidr.yml /tmp/test_broken_iface.yml")
