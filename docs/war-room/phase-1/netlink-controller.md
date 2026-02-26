**Technical Hurdle: The Go Scheduler vs. Linux Namespaces** One of the first challenges was Go’s concurrency model. Because Linux Namespaces are scoped to a **Thread**, and Go’s scheduler moves Goroutines across threads dynamically, I had to use `runtime.LockOSThread()`. Without pinning the thread, the controller would "forget" which namespace it was in mid-execution.

**Key Architecture: State Reconciliation** Instead of a "fire and forget" script, I implemented a **Reconciliation Loop**.

- **Observe:** Check if `aether-ns` and `veth-host` exist.
- **Diff:** Is the reality different from the desired state?
- **Act:** Only create resources if they are missing. This makes the controller **Idempotent**—I can run it a thousand times, and it will only act if something is broken.