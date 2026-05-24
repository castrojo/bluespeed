# Bluespeed Homelab Design

> **Status:** Active design — implementation tracked in issues [#11–#16](https://github.com/castrojo/bluespeed/issues)
> **Last updated:** 2026-05-24

---

## Goal

Bluespeed is a **homelab factory**. Clone this repo, run `just setup`, and get a fully
reproducible homelab stack on your own bare-metal hardware — the same one the Project Bluefin
team runs.

The **control plane** (the physical machine running the lab) is the live discovery environment.
Things are built and tested there by hand. Bluespeed is the clean reprovisioning target —
what any contributor needs to replicate the same setup from scratch on bare metal Flatcar Linux.

### The loop

```
discover on control plane (by hand)
       ↓
codify in bluespeed/control-plane/control-plane.bu (butane → Ignition)
       ↓
validate against Flatcar VM (clean slate)
       ↓
any contributor: knuckle install → just setup → same lab
```

---

## Design Tenets

1. **CNCF first** — every tool is a CNCF project. No custom services where a CNCF tool exists.

2. **No custom intermediary APIs** ⛔ — direct k8s/Argo API only. BST build jobs are Argo
   Workflows. VM lifecycle is `kubectl`/`virtctl`. Any custom API service is a violation.

3. **Reproducible** — `just setup` on any compatible hardware produces the same result.

4. **Justfile-driven** — every operation has a `just` recipe. No bespoke runbooks.

5. **Contributor-ready** — any Bluefin contributor can deploy this on their own hardware.

6. **Agent-driven but human-operable** — AI goes faster. A human with `just` gets the same
   result. The Justfile is the interface.

7. **Both umbrella and individual recipes** — `just setup` calls all steps in order. Every
   step is also a standalone recipe for day-2 maintenance. Never one without the other.

---

## Naming Convention

Lore names (ghost, Titans, knuckle) are **display and UI only**. All technical work —
paths, manifests, Justfile recipes, docs, code — uses real descriptive terms.

| Display name | Technical name |
|---|---|
| ghost | control plane |
| Titans | test VMs (KubeVirt VirtualMachines) |
| titan-dakota | test-vm-dakota |
| knuckle-1 | k3s cluster node / Flatcar validation VM |
| exo-* | NUC test node |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  knuckle ISO  (OS / hardware boundary)               │
│                                                      │
│  Flatcar Container Linux                             │
│  k3s:  Flatcar sysext (pinned version, no curl)      │
│  BST:  Flatcar sysext (same pattern as k3s)          │
│  zot:  Quadlet (OCI registry — only boot dep)        │
│  SSH:  parameterised placeholder (install-time)      │
│                                                      │
│  Source: control-plane/control-plane.bu (this repo)  │
│  Built by: projectbluefin/knuckle                    │
└────────────────────┬────────────────────────────────┘
                     │ first boot — Ignition runs once
                     ▼
┌─────────────────────────────────────────────────────┐
│  bluespeed day-2  (everything after first boot)      │
│                                                      │
│  just setup          ← umbrella, calls all below     │
│  just install-kubevirt                               │
│  just install-kubestellar                            │
│  just install-cdi                                    │
│  just install-argo   ← BST jobs run as workflows     │
│  just install-test-vms                               │
│  just setup-otel HOST=...                            │
└─────────────────────────────────────────────────────┘
```

---

## Boundary: knuckle vs bluespeed

| Concern | Owner |
|---|---|
| Flatcar install ISO | knuckle |
| k3s sysext build + pinning | knuckle |
| BST sysext build + pinning | knuckle |
| Ignition config source (`control-plane.bu`) | **bluespeed** |
| Disk layout / fstab | user (install-time decision) |
| SSH key content | user (install-time decision) |
| All k8s workloads (KubeVirt, Argo, CDI, etc.) | **bluespeed** |
| BST build job orchestration | **bluespeed** (Argo WorkflowTemplates) |
| Test VM manifests | **bluespeed** |

knuckle stays neutral. It installs Flatcar and applies the Ignition config.
It has no opinions about what runs on the machine after first boot.

---

## Ignition Config

**Path:** `control-plane/control-plane.bu`
**Format:** [Butane](https://coreos.github.io/butane/) — human-friendly YAML, transpiles to
Ignition JSON for embedding in the knuckle ISO.

### What it contains

| Component | How | Why here |
|---|---|---|
| k3s | Flatcar sysext — pinned version | Must be running before `just` recipes can target the cluster |
| BST | Flatcar sysext — same pattern as k3s | Core build dependency, must be available at first boot |
| zot Quadlet | systemd Quadlet — OCI registry | Only hard boot dependency; everything else is day-2 |
| SSH key | Parameterised placeholder | Contributor substitutes their own key at install time |

### What it does NOT contain

- ❌ Disk layout or fstab — user manages their own storage
- ❌ SSH key content — install-time decision, never hardcoded in the repo
- ❌ Any service beyond zot — everything else is a `just` recipe

---

## Justfile Shape

All day-2 operations. Idempotent. Human-driveable. Every recipe runnable standalone.

```
just setup                  # umbrella — runs everything below in order
just install-kubevirt        # KubeVirt operator + CR
just install-kubestellar     # KubeStellar
just install-cdi             # Containerized Data Importer
just install-argo            # Argo Workflows — BST job engine
just install-test-vms        # test VM manifests from kubevirt/
just setup-otel HOST=...     # observability stack (OTel, Loki, Prometheus, Grafana)
```

### Tenet enforced

Every recipe in `just setup` is also independently runnable. A contributor who only
wants to install KubeVirt runs `just install-kubevirt`. A contributor who wants the full
lab from scratch runs `just setup`. Both paths work. Always.

---

## Observability Stack

```
node-1 ──► OTel Collector (agent)
node-2 ──► OTel Collector (agent) ──► OTel Collector (aggregator, control plane)
node-N ──►                                       │
                                     ┌───────────┼───────────┐
                                  Loki:3100  Prometheus:9090  │
                                  (logs)     (metrics)        │
                                     └───────────┬───────────┘
                                           Grafana:3000
                                           (dashboards)
```

| Component | Project | CNCF status | Port |
|---|---|---|---|
| OTel Collector | OpenTelemetry | CNCF graduated | 4317 / 4318 |
| Prometheus | Prometheus | CNCF graduated | 9090 |
| Loki | Grafana Labs | explicit exception¹ | 3100 |
| Grafana | Grafana Labs | explicit exception¹ | 3000 |

¹ No CNCF-graduated equivalent for log storage + dashboarding. Loki and Grafana are
kept as an explicit pair — same vendor, canonical integration, well-documented.

All deployed as Podman Quadlets on the control plane. No Helm.

---

## Eliminated Components

### ghost-lab API (FastAPI :9000) — REMOVED ✂️

A custom Python FastAPI service was used to orchestrate BST build jobs. This is a CNCF
violation: a custom service where a CNCF tool (Argo Workflows) already does the job.

**Replacement:** BST build pipeline as Argo `WorkflowTemplate` CRDs in `argo/`.

- Build jobs are visible in the Argo UI at `:2746`
- Per-step logs, retry policies, and audit trail — built in
- No custom code to maintain
- `just trigger-build VARIANT=... IMAGE=...` invokes via Argo API

### Perses — REMOVED ✂️

Replaced by Grafana. Perses is immature, poorly documented, and has no advantage over
Grafana for a Loki + Prometheus stack. Grafana is the canonical pairing for both.

---

## Repository Layout (target state)

```
bluespeed/
├── Justfile                     ← all operations; just setup + individual recipes
├── control-plane/
│   └── control-plane.bu         ← butane Ignition config for the control plane role
├── argo/
│   └── bst-build.yaml           ← Argo WorkflowTemplate for BST build jobs
├── kubevirt/
│   ├── test-vm-dakota.yaml      ← KubeVirt VirtualMachine + DataVolume
│   ├── test-vm-stable.yaml
│   └── test-vm-lts.yaml
├── otel/
│   ├── ghost/
│   │   ├── quadlets/            ← loki, prometheus, otelcol, grafana Quadlets
│   │   └── config/              ← loki, prometheus, otelcol, grafana configs
│   ├── agent/                   ← OTel agent config + systemd unit
│   ├── dashboards/              ← Grafana dashboard JSON
│   ├── deploy.sh                ← OTel stack deploy (control plane)
│   └── deploy-agent.sh          ← OTel agent deploy (per node)
├── docs/
│   └── design.md                ← this file
└── exos/
    └── registry.yaml            ← fleet node registry (rename pending #13)
```

---

## Hardware Reference

| Host | IP | OS | Role |
|---|---|---|---|
| ghost | 192.168.1.102 | Flatcar Linux (target) | Control plane — k3s + BST build host |
| knuckle-1 | 192.168.122.227 | Flatcar VM | k3s cluster node / validation target |
| exo-dakota | 192.168.1.247 | Dakota (Bluefin variant) | NUC test node — hardware gate for dakota PRs |

---

## Implementation Issues

Work is tracked in `castrojo/bluespeed`. All issues are labelled `copilot-ready`.

| Issue | Title | Type |
|---|---|---|
| [#11](https://github.com/castrojo/bluespeed/issues/11) | Add `control-plane/control-plane.bu` — Flatcar Ignition config | improvement |
| [#12](https://github.com/castrojo/bluespeed/issues/12) | Eliminate ghost-lab API — replace with Argo Workflows | tech-debt |
| [#13](https://github.com/castrojo/bluespeed/issues/13) | Fix lore-contaminated paths — rename `exos/`, correct `registry.yaml` | tech-debt |
| [#14](https://github.com/castrojo/bluespeed/issues/14) | Add `just setup` umbrella + full day-2 recipe set | improvement |
| [#15](https://github.com/castrojo/bluespeed/issues/15) | Add Argo WorkflowTemplate for BST builds | improvement |
| [#16](https://github.com/castrojo/bluespeed/issues/16) | Rename test VM manifests to `test-vm-*.yaml` | tech-debt |

### Suggested implementation order

1. **#13** — rename paths first so new files land in the right place
2. **#16** — rename test VM manifests
3. **#11** — write `control-plane.bu` into the clean path
4. **#14** — add `just setup` + day-2 recipes
5. **#12** — eliminate ghost-lab API
6. **#15** — Argo WorkflowTemplate for BST (depends on #12, #14)

---

## See Also

- [projectbluefin/bluespeed](https://github.com/projectbluefin/bluespeed) — upstream product
- [projectbluefin/knuckle](https://github.com/projectbluefin/knuckle) — Flatcar installer (OS boundary)
- [projectbluefin/dakota](https://github.com/projectbluefin/dakota) — BuildStream image (BST source)
- [castrojo/utah](https://github.com/castrojo/utah) — autonomous implementation repo
