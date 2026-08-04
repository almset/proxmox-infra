def test_logging_rule_present(host):
    """Правило LOG должно существовать при gateway_enable_logging=true"""
    cmd = host.run(
        "iptables -C FORWARD -j LOG "
        "--log-prefix 'IPTables-Dropped: ' --log-level 4"
    )
    assert cmd.rc == 0


def test_all_other_rules_present(host):
    """Все остальные правила также должны быть на месте"""
    cmd = host.run(
        "iptables -C FORWARD "
        "-m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
    )
    assert cmd.rc == 0

    cmd = host.run(
        "iptables -C FORWARD "
        "-i eth1 -o eth0 -s 192.168.100.0/24 "
        "-m conntrack --ctstate NEW -j ACCEPT"
    )
    assert cmd.rc == 0


def test_masquerade_present(host):
    """В сценарии logging NAT должен быть включен по умолчанию"""
    cmd = host.run(
        "iptables -t nat -C POSTROUTING "
        "-s 192.168.100.0/24 -o eth0 -j MASQUERADE"
    )
    assert cmd.rc == 0
