# TODO — fail2ban role

## Future improvements

### Core features
- [ ] Auto-detect `banaction` (iptables vs nftables based on running backend)
- [ ] Support for email notifications via `action_mwl`
- [ ] Custom filter templates support
- [ ] Integration with `iptables-persistent` / `nftables-persistent`

### Testing & CI
- [ ] GitHub Actions pipeline:
  - [ ] `yamllint`
  - [ ] `ansible-lint`
  - [ ] `molecule test` (including idempotence stage)
  - [ ] `galaxy-importer` check
- [ ] Multi-distro matrix (Ubuntu 22.04, 24.04, Debian 11, 12)
- [ ] Replace `geerlingguy/docker-ubuntu2404-ansible` with official Ubuntu 24.04 image

### Documentation
- [ ] Add architecture diagram
- [ ] Add examples for common jails (postfix, dovecot, nginx-botsearch)
- [ ] Troubleshooting guide
- [ ] Migration guide from iptables to nftables
- [ ] Performance tuning guide

### Advanced
- [ ] Metrics export to Prometheus via `fail2ban-exporter`
- [ ] Centralized log aggregation integration (Graylog, Loki)
- [ ] GeoIP-based banning
- [ ] Custom action templates
