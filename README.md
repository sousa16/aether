# Aether: Global Edge Control Plane

**Aether** is a production-grade, distributed control plane for orchestrating self-healing BGP network meshes across hybrid-cloud environments.

Built entirely in Go, it combines a **Consistent Hash Ring** for distributed orchestration, **Netlink** for kernel-level network configuration, and **XDP/eBPF** for a high-speed data plane that bypasses the standard Linux networking stack.

> **The Elevator Pitch:** A Go-based distributed control plane that uses consistent hashing to manage a self-healing BGP mesh, utilizing XDP/eBPF for kernel-level packet processing and deep observability — engineered with the same operational patterns used in production infrastructure at scale.

---

## 📖 Engineering Journal

Development is documented in real time:

- **[Blog](https://joaosousadev.pt/#/blog)** — In-depth posts on architecture decisions and implementation.
- **[`/docs/notes`](./docs/notes)** — Raw study notes and Go/systems patterns encountered during development.
- **[`/docs/war-room`](./docs/war-room)** — Debugging logs: real bugs, root cause analysis, and how they were resolved. Not curated. Worth reading if you want to understand how problems actually get solved at the kernel level.

---

## 🚀 Key Features

**High-Speed Data Plane**
XDP-based packet filtering and DDoS mitigation runs at the NIC driver level, before the kernel networking stack is even involved. Latency overhead is measured in nanoseconds.

**Distributed Orchestration**
Multi-node control plane with peer discovery via the SWIM protocol (`memberlist`) and global state synchronization via `etcd`. Node assignment uses a consistent hash ring for deterministic, rebalance-aware distribution.

**Resilient Routing**
Anycast BGP via GoBGP, integrated with BFD (Bidirectional Forwarding Detection) for sub-second link failure detection and automatic failover between regions.

**State Reconciliation**
A Kubernetes-style control loop continuously monitors Linux network namespaces, veth configurations, and attached XDP programs. If state drifts — interfaces deleted, namespaces missing, eBPF programs manually detached — it detects and re-applies the desired configuration automatically.

**Deep Observability**
Custom eBPF exporters push P99 tail latency and packet processing timestamps directly from the kernel to Prometheus. No userspace sampling overhead.

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Controller Cluster                 │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐         │
│  │CtrlNode 1│   │CtrlNode 2│   │CtrlNode 3│         │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘         │
│       └──────────────┼──────────────┘                │
│              Consistent Hash Ring                    │
│              etcd (distributed state)                │
│              SWIM (membership/discovery)             │
└─────────────────────┬───────────────────────────────┘
                      │ gRPC
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌─────────┐   ┌─────────┐   ┌─────────┐
   │  Edge   │   │  Edge   │   │  Edge   │
   │  Node   │   │  Node   │   │  Node   │
   │         │   │         │   │         │
   │ Netlink │   │ Netlink │   │ Netlink │
   │ XDP/BPF │   │ XDP/BPF │   │ XDP/BPF │
   │ GoBGP   │   │ GoBGP   │   │ GoBGP   │
   └─────────┘   └─────────┘   └─────────┘
```

**Controller** — Distributed cluster managing the global network map. Assigns edge nodes to controllers via a consistent hash ring; rebalances automatically on membership changes.

**Edge Agent** — Lightweight Go daemon on each Linux node. Manages local Netlink state (namespaces, veth pairs), dynamically loads eBPF programs, and maintains BGP sessions.

---

## 🗺 Roadmap

### Phase 1: High-Performance Data Plane 🟡 In Progress

- [x] **Netlink Controller** — Full lifecycle management of network namespaces and veth pairs using `vishvananda/netlink`. Implemented with namespace-scoped `netlink.Handle` instances to avoid thread-namespace coupling bugs. Includes idempotent reconciliation and partial-state detection.
- [ ] **XDP DDoS Mitigator** — C-based eBPF program attached to the XDP hook for NIC-level packet processing. Go control plane populates eBPF Maps with blacklisted IPs to drop malicious traffic before it touches the kernel networking stack.
- [ ] **State Drift Detection** — Auto-recovery loop that detects and repairs state drift: deleted interfaces, missing namespaces, and detached XDP programs.

### Phase 2: Resilient Routing ⚪

- [ ] **GoBGP Integration** — Anycast service advertising across multi-cloud nodes via a single Service IP.
- [ ] **BFD Implementation** — Sub-second link failure detection between cloud regions, catching failures that standard BGP timers miss.
- [ ] **Chaos Sidecar** — `tc`-based utility to inject packet loss, 250ms latency, and PMTU discovery failures for resilience testing.
- [ ] **Route Dampening** — Flapping node detection: quarantine nodes that join/leave too rapidly to prevent BGP convergence storms and CPU spikes.

### Phase 3: Distributed Brain ⚪

- [ ] **Consistent Hash Ring** — Node assignment with automatic rebalancing on controller membership changes.
- [ ] **SWIM Protocol** (`memberlist`) — Controller cluster membership and peer failure detection.
- [ ] **etcd Integration** — Distributed source of truth and leader election via etcd Watches and Leases.
- [ ] **Leader-Kill Experiment** — Trigger a BGP update storm and kill the etcd leader simultaneously; measure Time to Recovery (TTR) and BGP convergence time.

### Phase 4: Observability, Automation & Performance ⚪

- [ ] **eBPF Latency Tracker** — Kernel-level timestamps for P99 tail latency via `cilium/ebpf`.
- [ ] **Performance Audit** — Load test XDP filter against standard `iptables`; document CPU usage and throughput differences.
- [ ] **Custom Terraform Provider** — HCL-defined `aether_node` resources.
- [ ] **SLO-Based Alerting** — Grafana dashboard for real-time SLO monitoring.

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Language | Go, C (restricted eBPF) |
| Networking | BGP (GoBGP), Anycast, BFD, SR-MPLS |
| Kernel | XDP, eBPF Maps, Linux Namespaces, Netlink, `strace` |
| Distributed Systems | etcd, gRPC, Hashicorp Memberlist |
| Observability | Prometheus, Grafana, custom eBPF exporters |
| Infrastructure | Terraform (Custom Provider) |

---

## ⚡ Quick Start

**Requirements:** Linux (Ubuntu 24.04 recommended), Go 1.21+, root access.

```bash
# Clone the repository
git clone https://github.com/sousa16/aether.git
cd aether

# Install system dependencies and Go modules
# Installs: build-essential, libelf-dev, llvm, clang, iproute2, strace
sudo ./setup.sh

# Build
make build

# Run (requires root for Netlink/namespace operations)
sudo ./aether-ctl

# Test (also requires root)
make test

# Remove built binaries
make clean
```

> **Note:** Netlink and XDP operations require `CAP_NET_ADMIN`. All network state created by `aether-ctl` can be torn down with `sudo ip netns del aether-ns && sudo ip link del veth-host`.

---

## 📁 Repository Structure

```
aether/
├── src/
│   └── cmd/
│       └── netlink-controller/         # Phase 1: namespace & veth lifecycle
│           ├── main.go
│           └── main_test.go
├── docs/
│   ├── notes/
│   │   ├── getting-started-with-ebpf/
│   │   │   ├── ebpf-basics.md          # eBPF fundamentals, maps, programs
│   │   │   └── ebpf-for-networking.md  # XDP, TC hooks, container networking
│   │   └── go-patterns.md             # Go patterns encountered during development
│   ├── images/                         # Diagrams and screenshots for notes
│   └── war-room/
│       └── phase-1/
│           └── netlink-controller.md   # Debugging log: thread-namespace coupling bug
├── Makefile                            # build, test, clean targets
├── setup.sh                            # Installs system deps + Go modules
├── go.mod
└── LICENSE
```

---

## 📄 License

MIT