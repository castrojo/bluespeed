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
   Workflows. VM lifecycle is `virtctl`. Any custom API service is a violation.

3. **Argo is the deployment engine** ⛔ — all cluster operations go through Argo WorkflowTemplates.
   No `kubectl apply -f` except to bootstrap Argo itself (`just install-argo`). Every deployment
   is visible in the Argo UI with audit trail, retry policies, and per-step logs.

4. **No Helm** ⛔ — raw k8s manifests submitted via Argo. No Helm charts, releases, helmfile,
   or helm operator for any component.

5. **Reproducible** — `just setup` on any compatible hardware produces the same result.

6. **Justfile-driven** — every operation has a `just` recipe. No bespoke runbooks.

7. **Contributor-ready** — any Bluefin contributor can deploy this on their own hardware.

8. **Agent-driven but human-operable** — AI goes faster. A human with `just` gets the same
   result. The Justfile is the interface.

9. **Both umbrella and individual recipes** — `just setup` calls all steps in order. Every
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
│  bootstrap (kubectl apply — one time only)           │
│  just install-argo                                   │
└────────────────────┬────────────────────────────────┘
                     │ Argo is now running
                     ▼
┌─────────────────────────────────────────────────────┐
│  day-2 via Argo  (all deployments through Argo UI)   │
│                                                      │
│  just setup              ← umbrella, calls all below │
│  just install-kubevirt   → argo submit               │
│  just install-kubestellar→ argo submit               │
│  just install-cdi        → argo submit               │
│  just install-test-vms   → argo submit               │
│  just setup-otel         → argo submit               │
│  just trigger-build      → argo submit               │
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
| Argo bootstrap (`just install-argo`) | **bluespeed** (only direct kubectl) |
| All k8s workloads post-bootstrap | **bluespeed** (Argo WorkflowTemplates) |
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
| k3s | Flatcar sysext — pinned version | Must be running before any `just` recipes can target the cluster |
| BST | Flatcar sysext — same pattern as k3s | Core build dependency, must be available at first boot |
| zot Quadlet | systemd Quadlet — OCI registry | Only hard boot dependency; everything else is day-2 |
| SSH key | Parameterised placeholder | Contributor substitutes their own key at install time |

### What it does NOT contain

- ❌ Disk layout or fstab — user manages their own storage
- ❌ SSH key content — install-time decision, never hardcoded in the repo
- ❌ Any service beyond zot — everything else is a `just` recipe

---

## Justfile Shape

Two phases: bootstrap (Argo only), then everything else via Argo.

```
# Phase 1 — bootstrap (direct kubectl, one time only)
just install-argo            # installs Argo Workflows via kubectl apply

# Phase 2 — all subsequent operations submit Argo WorkflowTemplates
just setup                   # umbrella — runs all phase-2 recipes in order
just install-kubevirt        # → argo submit workflowtemplate/install-kubevirt
just install-kubestellar     # → argo submit workflowtemplate/install-kubestellar
just install-cdi             # → argo submit workflowtemplate/install-cdi
just install-test-vms        # → argo submit workflowtemplate/install-test-vms
just setup-otel HOST=...     # → argo submit workflowtemplate/setup-otel
just trigger-build VARIANT IMAGE  # → argo submit workflowtemplate/bst-build
```

### Tenet enforced

Every recipe in `just setup` is also independently runnable. Both paths always work.
All phase-2 deployments are visible in the Argo UI at `:2746`.

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

Custom Python FastAPI for BST job orchestration — CNCF violation.
**Replacement:** Argo `WorkflowTemplate` in `argo/`. Visible in Argo UI at `:2746`.

### Perses — REMOVED ✂️

Replaced by Grafana. Grafana is the canonical pairing for Loki + Prometheus.

---

## Argo WorkflowTemplate Index

All WorkflowTemplates live in `argo/`. Applied by `just install-argo`.

| File | Purpose |
|---|---|
| `argo/install-kubevirt.yaml` | Install KubeVirt operator + CR |
| `argo/install-cdi.yaml` | Install CDI |
| `argo/install-kubestellar.yaml` | Install KubeStellar |
| `argo/install-test-vms.yaml` | Apply test VM manifests |
| `argo/setup-otel.yaml` | Deploy observability stack |
| `argo/bst-build.yaml` | Run a BST build job |

---

## Repository Layout (target state)

```
bluespeed/
├── Justfile
├── control-plane/
│   └── control-plane.bu         ← Ignition config for control plane role
├── argo/
│   ├── install-kubevirt.yaml    ← WorkflowTemplate
│   ├── install-cdi.yaml
│   ├── install-kubestellar.yaml
│   ├── install-test-vms.yaml
│   ├── setup-otel.yaml
│   └── bst-build.yaml
├── kubevirt/
│   ├── test-vm-dakota.yaml
│   ├── test-vm-stable.yaml
│   └── test-vm-lts.yaml
├── otel/
│   ├── ghost/
│   │   ├── quadlets/            ← loki, prometheus, otelcol, grafana Quadlets
│   │   └── config/              ← loki, prometheus, otelcol, grafana configs
│   ├── agent/
│   ├── dashboards/              ← Grafana dashboard JSON
│   ├── deploy.sh
│   └── deploy-agent.sh
├── docs/
│   └── design.md
└── exos/
    └── registry.yaml
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
| [#11](https://github.com/castrojo/bluespeed/issues/11) | Add `control-plane/control-plane.bu` | improvement |
| [#12](https://github.com/castrojo/bluespeed/issues/12) | Eliminate ghost-lab API — replace with Argo Workflows | tech-debt |
| [#13](https://github.com/castrojo/bluespeed/issues/13) | Fix lore-contaminated paths — rename `exos/`, correct `registry.yaml` | tech-debt |
| [#14](https://github.com/castrojo/bluespeed/issues/14) | Add `just setup` umbrella + full day-2 recipe set | improvement |
| [#15](https://github.com/castrojo/bluespeed/issues/15) | Add Argo WorkflowTemplates for all cluster operations | improvement |
| [#16](https://github.com/castrojo/bluespeed/issues/16) | Rename test VM manifests to `test-vm-*.yaml` | tech-debt |

### Suggested implementation order

1. **#13** — rename paths first
2. **#16** — rename test VM manifests
3. **#11** — write `control-plane.bu`
4. **#14** — add `just setup` + day-2 recipes
5. **#15** — all Argo WorkflowTemplates (expanded scope: all cluster ops, not just BST)
6. **#12** — eliminate ghost-lab API

---

## See Also

- [projectbluefin/bluespeed](https://github.com/projectbluefin/bluespeed) — upstream product
- [projectbluefin/knuckle](https://github.com/projectbluefin/knuckle) — Flatcar installer (OS boundary)
- [projectbluefin/dakota](https://github.com/projectbluefin/dakota) — BuildStream image (BST source)
- [castrojo/utah](https://github.com/castrojo/utah) — autonomous implementation repo
