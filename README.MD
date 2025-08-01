# optiplex-ops-lab

DevOps homelab project built on Dell OptiPlex hardware to develop enterprise-grade infrastructure and automation skills.

## Project Vision

Transform two upgraded Dell OptiPlex 7070 systems into a comprehensive DevOps learning environment that demonstrates real-world enterprise practices including virtualization, container orchestration, infrastructure automation, and security hardening.

This project serves as both a practical learning experience and a portfolio demonstration for transitioning from system administration to DevOps engineering roles.

## Hardware Specifications

**2x Dell OptiPlex 7070:**
- Intel i7-9700 processor
- 32GB DDR4 RAM (upgraded)
- 1TB NVMe SSD (system)
- 2TB NVMe SSD (data/VMs)
- Gigabit Ethernet

**Network Configuration:**
- Isolated VLAN (172.16.10.0/24)
- Bastion host access only
- Internal certificate management

## Technology Roadmap

### Phase 1: Foundation Infrastructure (Current)
**Status: In Progress**

- [x] Hardware preparation and BIOS configuration
- [x] Proxmox VE installation on both nodes
- [ ] Proxmox cluster configuration
- [ ] Storage setup and management
- [ ] Network configuration and VLAN isolation
- [ ] Basic firewall rules and security

### Phase 2: Container Orchestration
**Status: Planned**

- [ ] Kubernetes (K3s) cluster deployment
- [ ] Multi-master high availability setup
- [ ] Ingress controller configuration (Traefik)
- [ ] Persistent volume management
- [ ] Basic service deployments

### Phase 3: Infrastructure as Code
**Status: Planned**

- [ ] Terraform modules for Proxmox resources
- [ ] Ansible playbooks for system configuration
- [ ] GitLab CE installation and setup
- [ ] CI/CD pipeline foundations
- [ ] Version control workflow establishment

### Phase 4: Monitoring and Observability
**Status: Planned**

- [ ] Prometheus metrics collection
- [ ] Grafana dashboard configuration
- [ ] Log aggregation with Loki
- [ ] Alerting rules and notifications
- [ ] Performance monitoring and optimization

### Phase 5: Security and Compliance
**Status: Planned**

- [ ] Internal PKI certificate authority
- [ ] Secrets management with Vault
- [ ] Security scanning and vulnerability assessment
- [ ] Backup and disaster recovery procedures
- [ ] Documentation and runbooks

### Phase 6: Advanced Services
**Status: Future**

- [ ] Service mesh implementation
- [ ] Advanced GitOps workflows
- [ ] Container registry and artifact management
- [ ] Testing automation and quality gates
- [ ] Performance testing and optimization

## Current Status

**Week 1-2:** Proxmox cluster setup and basic virtualization platform
**Next:** Kubernetes cluster deployment and container orchestration

See individual documentation files in `docs/` for detailed progress on each component.

## Learning Objectives

**Technical Skills:**
- Enterprise virtualization with Proxmox
- Kubernetes cluster administration
- Infrastructure automation (Terraform/Ansible)
- CI/CD pipeline design and implementation
- Monitoring and observability practices
- Security hardening and compliance

**Operational Skills:**
- Documentation and knowledge management
- Troubleshooting and problem resolution
- Change management procedures
- Disaster recovery planning

## Project Structure

```
optiplex-ops-lab/
├── docs/                    # Detailed documentation
├── terraform/               # Infrastructure as Code
├── ansible/                 # Configuration management
├── k8s-manifests/          # Kubernetes deployments
├── monitoring/             # Grafana dashboards and alerts
├── scripts/                # Automation and utility scripts
└── ci-cd/                  # Pipeline configurations
```

## Getting Started

This project is currently in active development. Setup instructions and deployment guides will be available as each phase completes.

For the latest progress updates, see the project documentation in the `docs/` directory.

## Technology Stack

**Current:**
- Proxmox VE for virtualization
- Linux system administration

**Planned:**
- Kubernetes (K3s) for container orchestration
- Terraform for infrastructure provisioning
- Ansible for configuration management
- GitLab CE for source control and CI/CD
- Prometheus/Grafana for monitoring
- Various security and networking tools

## Contributing

This is a personal learning project documenting the journey from system administration to DevOps engineering. Progress updates and lessons learned will be shared through detailed documentation.

## License

MIT License - See LICENSE file for details.
