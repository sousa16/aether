**XDP**: eXpress Data Path
Type of event that we can attach eBPF to - for incoming network packets
The first possible opportunity for looking into a network packet as it arrives into a machine across a network interface

![[Pasted image 20260224162925.png]]

Example: using XDP to drop *ping* packets

-  Loading our *xdp* function into *BPF.XDP*

![[Pasted image 20260224165535.png]]

- XDP's context is the network packet, and it's defined by a structure called *xdp_md*
- If we change the first *XDP_PASS* to *XDP_DROP*, pings get dropped

![[Pasted image 20260224165703.png]]

Some NICs support XDP Offload: eBPF program runs on the NIC itself
Packets can be modified, dropped, or forwarded without using CPU cycles

![[Pasted image 20260224173055.png]]

We can attach eBPF events in several stages of the Network Stack:

![[Pasted image 20260224174131.png]]

**Traffic Control (TC):** subsystem in the kernel that regulates how traffic is scheduled using classifiers
eBPF programs can be attached in TC as custom classifiers, and can also manipulate, drop, or redirect packets here too

**Cilium:** in containerized environments, IPs are reused for different applications as demand varies. Cilium is aware of Kubernetes identities.

**Container Networking w/out eBPF:**

![[Pasted image 20260224175753.png]]

**Container Networking w/ eBPF:** using eBPF (as we do in Cilium), we can bypass a lot of the networking stack on the host and send packets directly to the pod, which is much more efficient.

![[Pasted image 20260224175822.png]]

**Cilium Network Policy:** eBPF programs drop packets