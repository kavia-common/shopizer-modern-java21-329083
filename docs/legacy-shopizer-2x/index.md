# Legacy Shopizer 2.x (Java 6) Documentation Set

## Purpose and scope

This folder contains “ported” documentation for the legacy Shopizer 2.x codebase located in this workspace under `shopizer-329083/`. It exists to preserve the legacy architecture and integration knowledge in the Java 21 modernization repository, so engineers can reference the legacy structure while migrating functionality.

These documents describe the legacy implementation. They are not an architecture description of the Java 21 target runtime.

## Documents

- [Architecture overview](architecture-overview.md)
- [Module and package map](module-and-package-map.md)
- [Entity and data model](entity-data-model.md)
- [Service and controller reference](service-and-controller-reference.md)
- [External integrations](external-integrations.md)

## Conventions note

This repository’s documentation conventions require architecture and design documents to live under `/docs` and infrastructure templates under `/infra`. This legacy set is intentionally stored under `/docs` to comply with those conventions.

## Sources

- `shopizer-modern-java21-329083/docs/documentation-conventions.md`: defines required documentation location and scope for the Java 21 target repo.
- `kavia-docs/CodeWiki/Architecture/shopizer-2x-legacy-architecture.md`: source material for legacy architecture overview.
- `kavia-docs/CodeWiki/Architecture/shopizer-2x-legacy-modules.md`: source material for legacy module/package map.
- `kavia-docs/CodeWiki/Architecture/shopizer-2x-legacy-data-model.md`: source material for legacy data model overview.
- `kavia-docs/CodeWiki/Architecture/shopizer-2x-legacy-service-layer.md`: source material for legacy service layer patterns.
- `kavia-docs/CodeWiki/Architecture/shopizer-2x-legacy-external-integrations.md`: source material for legacy integration inventory.
