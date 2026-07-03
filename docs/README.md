# Documentation

This directory contains the project documentation for the IaC repository.

## Available documents

- [`01-solution-design-iac-exploration.md`](C:/Development/catena-x/tractus-x-umbrella-iac/docs/01-solution-design-iac-exploration.md)
  Exploration document covering the business case, current state analysis, required IaC components, and tool evaluation.
- [`02-solution-design-iac-implementation.md`](C:/Development/catena-x/tractus-x-umbrella-iac/docs/02-solution-design-iac-implementation.md)
  Implementation-focused document covering the architecture, implemented modules, provisioning runbook, and validation flow.
- [`03-deployment-architecture-and-diagrams.md`](C:/Development/catena-x/tractus-x-umbrella-iac/docs/03-deployment-architecture-and-diagrams.md)
  Detailed architecture document with deployment flow, cluster internals, stage separation options, and diagrams.
- [`04-node-sizing-and-vm-configuration.md`](C:/Development/catena-x/tractus-x-umbrella-iac/docs/04-node-sizing-and-vm-configuration.md)
  Reference for AKS node pool VM sizes and node counts per stage, why system/workload pools are
  separated, and where to change sizing (currently 1+1 for demo purposes; 2+ recommended per pool).

## Suggested reading order

1. Start with `01-solution-design-iac-exploration.md` for the context and design rationale.
2. Continue with `02-solution-design-iac-implementation.md` for the implemented approach and operational flow.
3. Use `03-deployment-architecture-and-diagrams.md` as the detailed technical and diagram reference.
4. Check `04-node-sizing-and-vm-configuration.md` when you need to size or resize node pools for an environment.
