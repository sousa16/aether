# War Room: Netlink Controller

## Technical Hurdle: The Go Scheduler vs. Linux Namespaces

One of the first challenges was Go's concurrency model. Linux Namespaces are scoped to a **thread**, not a process. When you call `setns()`, you switch the current OS thread into a different namespace — everything that runs on that thread after the call operates inside it.

Go's scheduler moves goroutines across OS threads dynamically. This means if you switch into a namespace, do some work, and then yield — even briefly — the runtime may resume your goroutine on a different thread that was never switched. You're now operating in the wrong namespace with no error, no panic, nothing. Silent corruption.

The fix is `runtime.LockOSThread()`, which pins the current goroutine to its OS thread for the lifetime of the call:

```go
runtime.LockOSThread()
defer runtime.UnlockOSThread()
```

Without this, the controller would "forget" which namespace it was in mid-execution.

---

## Bug: The Thread-Namespace Coupling Bug

The deeper problem came from using `netns.Set(ns)` to switch into the namespace, then relying on the default `netlink` package functions, then calling `netns.Set(hostNS)` to restore.

The default `netlink` functions open a new netlink socket on each call. A socket opened inside a namespace belongs to that namespace. If the restore call failed — or ran on a different code path than expected — the thread stayed inside `aether-ns`. Every subsequent `netlink` call silently operated against the wrong namespace.

On the next run, `LinkAdd` created both veth ends inside `aether-ns` instead of the host. `LinkSetNsFd` then tried to move `veth-ns` into a namespace where it already lived:

```
Namespace 'aether-ns' already exists.
Veth-host not found, creating pair...
Failed to move veth-ns to namespace: file exists
```

Confirming with `ip link show` inside the namespace:

```
2: veth-ns@veth-host: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
3: veth-host@veth-ns: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
```

Both ends inside the namespace. The thread had never left.

### Fix: Namespace-Scoped Handles

Eliminated all `netns.Set` calls. Replaced with `netlink.Handle` instances opened directly against the target namespace fd:

```go
hostHandle, err := netlink.NewHandleAt(hostNS)
nsHandle, err := netlink.NewHandleAt(ns)
```

`NewHandleAt` opens the netlink socket at construction time, bound to the provided namespace. After that, the handle's namespace is fixed regardless of what the OS thread is doing. `hostHandle` always talks to the host. `nsHandle` always talks to `aether-ns`. There is nothing to restore.

---

## Bug: Stale Veth Pair From Orphaned State

During testing, `ip link show veth-host` showed `NO-CARRIER` and `LOWERLAYERDOWN` even after manually bringing it up. Interface indices didn't match between host and namespace — the two ends were not actually a pair. They had been created in separate runs after a partial cleanup left `veth-host` orphaned on the host while a new `veth-ns` was created in a fresh namespace.

```
veth-host: index 6, mac 7a:99:f8:cd:57:d3
veth-ns:   index 2, mac 12:3e:07:18:5a:87
```

No shared peer reference. Clean teardown and re-run resolved it:

```bash
sudo ip link del veth-host 2>/dev/null; sudo ip netns del aether-ns 2>/dev/null
sudo ./aether-ctl
```

---

## Key Architecture: State Reconciliation

Instead of a fire-and-forget script, the controller implements a **Reconciliation Loop** — the same pattern used by Kubernetes controllers.

**Observe** — query current kernel state: does `aether-ns` exist? does `veth-host` exist on the host? is `veth-ns` present inside the namespace?

**Diff** — compare observed state against desired state. If everything is correctly placed, there is nothing to do.

**Act** — only create or repair what is missing or broken. If `veth-host` exists on the host but `veth-ns` is missing from the namespace (partial state from a failed previous run), the controller detects it and exits cleanly rather than silently proceeding into a broken configuration.

This makes the controller **idempotent** — it can run a thousand times and will only act if something is actually wrong.

---

## Final Verified State

```
$ sudo ./aether-ctl
Namespace not found, creating it...
veth-host not found on host, creating pair...
veth pair created and veth-ns moved to aether-ns.
--- Network Infrastructure Synchronized ---

$ ip link show veth-host
10: veth-host@if9: <BROADCAST,MULTICAST,UP,LOWER_UP> ... link-netns aether-ns

$ sudo ip netns exec aether-ns ip link show veth-ns
9: veth-ns@if10: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
```

Both ends up, carrier detected, correctly placed.