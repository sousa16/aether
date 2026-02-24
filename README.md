# Aether: The Global Edge Control Plane

**Aether** is a high-performance, distributed control plane designed to orchestrate self-healing BGP network meshes across hybrid-cloud environments. 

Developed to bridge the gap between network operations and systems programming, Aether combines **Consistent Hashing** for distributed orchestration and **XDP/eBPF** for a high-speed data plane. It demonstrates a production-grade approach to building modern, resilient internet infrastructure.

> **The Elevator Pitch:** A Go-based distributed control plane that uses consistent hashing to manage a self-healing BGP network mesh, utilizing XDP/eBPF for a high-performance data plane and kernel-level observability.

---

## 📖 Engineering Journal & Insights

I am documenting Aether's development in my [blog](www.joaosousadev.pt/blog)

---

## 🚀 Key Features

* **High-Speed Data Plane:** XDP-based packet filtering and DDoS mitigation at the NIC driver level, bypassing the standard Linux networking stack for minimal latency.
* **Distributed Orchestration:** Multi-node control plane featuring peer discovery via the SWIM protocol and global state synchronization via `etcd`.
* **Resilient Routing:** Anycast BGP implementation integrated with BFD (Bidirectional Forwarding Detection) for sub-second link failure detection and failover.
* **State Reconciliation:** A Kubernetes-style "Control Loop" that monitors and automatically repairs Linux network namespaces and link configurations (reclaiming "State Drift").
* **Deep Observability:** Custom eBPF exporters for Prometheus to track P99 tail latency and packet processing time directly from the Linux kernel.

---

## 🏗 System Architecture

Aether follows a decoupled architecture designed for massive scale:

1.  **The Brain (Controller):** A distributed cluster managing the global network map. It utilizes a **Consistent Hash Ring** to assign specific edge nodes to controllers, ensuring high availability and seamless rebalancing during cluster changes.
2.  **The Agent (Edge Node):** A lightweight Go daemon running on Linux nodes. It manages local Netlink configurations (Namespaces, Veth pairs) and dynamically loads/updates eBPF programs.



---

## 🗺 Roadmap & Progress

### Phase 1: High-Performance Data Plane 🟡 (In Progress)
- [ ] **Netlink Controller:** Lifecycle management of Namespaces and Veth pairs using `vishvananda/netlink`.
- [ ] **XDP DDoS Mitigator:** Kernel-level packet dropping via eBPF maps and XDP hooks.
- [ ] **State Drift Detection:** Auto-recovery loop for deleted network interfaces.

### Phase 2: Resilient Routing ⚪
- [ ] **GoBGP Integration** for Anycast service advertising.
- [ ] **BFD implementation** for sub-second failure detection between cloud regions.
- [ ] **Chaos Engineering Suite:** Automated simulation of jitter, packet loss, and MTU mismatches.

### Phase 3: Distributed Brain ⚪
- [ ] **Consistent Hashing** ring implementation for node assignment.
- [ ] **SWIM Protocol** (`memberlist`) for controller cluster membership.
- [ ] **etcd integration** for distributed source of truth and leader election.

### Phase 4: Observability, Automation & Performance ⚪
- [ ] **eBPF Latency Tracker:** Using `cilium/ebpf` to capture kernel-level timestamps for P99 Tail Latency.
- [ ] **Performance Audit:** Comparative load testing of XDP vs. standard `iptables` throughput.
- [ ] **Custom Terraform Provider:** Automating infrastructure via HCL-defined `aether_node` resources.
- [ ] **SLO-Based Alerting:** Grafana dashboard implementation for real-time monitoring of Service Level Objectives.
---

## 🛠 Tech Stack

* **Language:** Go (Golang), C (Restricted C for eBPF)
* **Networking:** BGP, Anycast, Netlink, BFD, SR-MPLS
* **Kernel Tech:** XDP, eBPF Maps, Linux Namespaces, Syscalls (`strace`)
* **Distributed Systems:** etcd, gRPC, Hashicorp Memberlist
* **Infrastructure:** Terraform (Custom Provider), Prometheus, Grafana

---
