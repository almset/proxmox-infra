def test_masquerade_absent(host):
    """При gateway_nat_enabled=false MASQUERADE не должно быть"""
    cmd = host.run(
        "iptables -t nat -C POSTROUTING "
        "-s 192.168.100.0/24 -o eth0 -j MASQUERADE"
    )
    assert cmd.rc != 0


def test_forwarding_still_enabled(host):
    """IP forwarding должен быть включен даже без NAT"""
    assert host.sysctl("net.ipv4.ip_forward") == 1


def test_forward_rule_present(host):
    """Правило FORWARD должно работать даже без NAT"""
    cmd = host.run(
        "iptables -C FORWARD "
        "-i eth1 -o eth0 -s 192.168.100.0/24 "
        "-m conntrack --ctstate NEW -j ACCEPT"
    )
    assert cmd.rc == 0


def test_forward_policy_drop(host):
    """Политика FORWARD должна быть DROP даже без NAT"""
    cmd = host.run("iptables -S FORWARD")
    assert "-P FORWARD DROP" in cmd.stdout
