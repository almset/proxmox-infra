def test_ip_forwarding(host):
    """IP forwarding должен быть включен"""
    assert host.sysctl("net.ipv4.ip_forward") == 1


def test_masquerade_present(host):
    """Правило MASQUERADE должно существовать"""
    cmd = host.run(
        "iptables -t nat -C POSTROUTING "
        "-s 192.168.100.0/24 -o eth0 -j MASQUERADE"
    )
    assert cmd.rc == 0


def test_forward_rule_present(host):
    """Правило FORWARD для внутренней сети должно существовать"""
    cmd = host.run(
        "iptables -C FORWARD "
        "-i eth1 -o eth0 -s 192.168.100.0/24 "
        "-m conntrack --ctstate NEW -j ACCEPT"
    )
    assert cmd.rc == 0


def test_established_related_rule(host):
    """Правило для ESTABLISHED,RELATED должно существовать"""
    cmd = host.run(
        "iptables -C FORWARD "
        "-m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
    )
    assert cmd.rc == 0


def test_forward_policy_drop(host):
    """Политика FORWARD должна быть DROP"""
    cmd = host.run("iptables -S FORWARD")
    assert "-P FORWARD DROP" in cmd.stdout


def test_persistent_service(host):
    """Сервис netfilter-persistent должен быть включен и активен"""
    svc = host.service("netfilter-persistent")
    assert svc.is_enabled
    assert svc.is_running


def test_rules_file_permissions(host):
    """Файл правил должен иметь правильные права"""
    f = host.file("/etc/iptables/rules.v4")
    assert f.exists
    assert f.mode == 0o600
    assert f.user == "root"
    assert f.group == "root"


def test_no_temp_file_left(host):
    """Временный файл должен быть удалён"""
    f = host.file("/tmp/.rules.v4.gateway.tmp")
    assert not f.exists
