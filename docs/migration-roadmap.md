# Shopizer 2.x → Java 21 Strangler Fig Migration Roadmap

## Purpose and scope

This document defines a phased Strangler Fig migration roadmap for moving the legacy Shopizer 2.x monolith (the servlet WAR under `shopizer-329083/`, composed of `sm-shop` + `sm-core`) to a Java 21 / Spring Boot 3.x target architecture with a gateway routing layer, as proposed in `docs/target-architecture.md`.

The roadmap is derived from the legacy-to-modern criticality analysis in `docs/migration-analysis.md` and the legacy architecture evidence summarized under `docs/legacy-shopizer-2x/`. It focuses on sequencing, migration seams, and how to route traffic safely between “legacy” and “new” during the transition.

## Guiding constraints from the current repository evidence

The plan explicitly reflects the following constraints evidenced in the repo:

The legacy system is deployed as a WAR with classic `web.xml` bootstrapping and in-process wiring between `sm-shop` and `sm-core`. This implies the primary migration risk is not just “upgrading Java”, but also replacing servlet-container era wiring and XML-heavy Spring 3.x patterns with Spring Boot 3.x idioms.

The legacy system has several “high fan-in” domains that are used broadly across storefront, admin, and “REST-like” `/services/**` endpoints. Based on `docs/migration-analysis.md`, the highest-impact domains are catalog, cart, and orders, and the most important integration seams are payment, shipping, email, CMS/assets, and search indexing.

The legacy integration pattern is “pluggable modules by code”, with module codes and metadata evidenced in `docs/legacy-shopizer-2x/external-integrations.md`. Preserving those codes as stable identifiers is a pragmatic compatibility strategy.

The legacy product lifecycle is coupled to search indexing behavior via a search service layer, and in the target architecture it is recommended to make indexing asynchronous and event-driven to avoid tight coupling between write paths and search availability.

## Target end-state summary (for roadmap alignment)

The target architecture is described in `docs/target-architecture.md` and assumes:

A gateway routing layer (for example Spring Cloud Gateway or equivalent ingress routing) becomes the primary entry point for client traffic.

Core business capabilities are separated into deployable Spring Boot services (or, during early phases, a modular monolith that still enforces boundaries), with services such as Catalog, Cart, Order, Payment Adapter, Shipping Rating, Content/Assets, Search, and (optionally) Identity.

PostgreSQL 16 is the system of record in the target architecture, with Flyway-managed migrations.

## Migration approach overview (Strangler Fig)

A Strangler Fig migration introduces a new “edge” that can route traffic to either legacy or new implementations based on path, host, headers, or other routing rules. Over time, more capability is “strangled” away from the legacy system and implemented behind the gateway in the new architecture.

Key practical principles applied in this roadmap are:

The gateway is introduced early, but initially it routes nearly everything to legacy. This provides a safe place to add authentication enforcement, observability, rate-limiting, and targeted routing rules.

New services are introduced behind the gateway, one bounded context at a time, starting with high-fan-in read paths (catalog browsing and product details) and moving toward stateful and workflow-heavy paths (cart and checkout).

Where the legacy domain implies cross-cutting concerns (for example product indexing, media storage, merchant configuration for integrations), the migration uses explicit contracts, events, and adapters so new services do not re-entangle with legacy internals.

## Phases and service migration order

### Phase 0: Discovery, safety rails, and executable architecture baseline

This phase establishes a baseline that makes later phases measurable and safer, without requiring any end-user visible changes.

In this phase, the team should verify and capture the legacy contract surface that clients depend on. The legacy system is known to have multiple “areas” (`/admin/**`, `/shop/**`, and `/services/**`), but an automated endpoint inventory is not present in the repo evidence and must be produced as part of this phase.

Recommended deliverables:

A gateway deployed in front of the legacy application, initially in “pass-through mode” (route all traffic to legacy). The routing rules should be designed so specific paths can later be re-routed to new services.

Standard cross-cutting telemetry at the edge, including correlation IDs and structured logs. This is essential because later phases introduce network boundaries and eventual consistency.

A concrete “domain cut list” of endpoints grouped by bounded context (catalog, cart, orders, customer, reference data, integrations). The legacy docs indicate package areas and patterns, but the roadmap requires a deployable, testable contract list.

Exit criteria:

The gateway is the stable entry point in at least one non-production environment and can be used to route a single path to a mock/new service without breaking other traffic.

### Phase 1: Platform foundation for the new stack (Java 21 / Spring Boot 3.x)

This phase creates the “modern platform skeleton” that later domain services will use. It is primarily internal and focuses on engineering enablement.

Recommended deliverables:

A standard Spring Boot 3.x service template aligned to Java 21, including configuration conventions and health endpoints.

PostgreSQL 16 connectivity conventions and Flyway migration conventions, even if only for an initial schema.

A standardized authentication/authorization approach for service-to-service and client-to-service calls. The legacy security model is not fully evidenced in the analyzed sources, so this should be implemented as a modern, explicit decision rather than a direct port.

Exit criteria:

At least one Spring Boot service is deployable behind the gateway and can respond to a health check routed through the gateway.

### Phase 2: Catalog read paths first (high fan-in, low workflow complexity)

Catalog is both critical and highly reused. Migrating catalog reads early produces business value and reduces coupling because many other domains depend on the ability to read product and category information.

Service order and rationale:

Catalog Service should be created first, focusing on read APIs: category tree, product details, product listings, manufacturer lists, and basic availability/price visibility. This is aligned with the “critical” catalog classification in `docs/migration-analysis.md`.

Content/Assets Service (or a thin “media” module) may be introduced here if product images and static content links must be served from the new stack. The legacy system uses filesystem-backed Infinispan cache stores for CMS-like content; the target recommends an abstraction over object storage or other modern storage.

Gateway routing:

Route a limited set of catalog read endpoints to the new Catalog Service. Keep all writes (admin product creation/editing) on legacy in this phase.

Data strategy:

This phase is compatible with multiple approaches, but the roadmap assumes the safest early approach is to keep the legacy database as the system of record while catalog read models are built, or to migrate a subset of catalog tables with careful validation. The exact approach should be chosen based on operational constraints and data ownership decisions in the target architecture.

Exit criteria:

A defined set of catalog read paths (for example product detail and category listing) are served by the new stack in at least one environment, with functional parity validated against legacy behavior.

### Phase 3: Search decoupling and asynchronous indexing (prevent tight coupling)

The legacy system couples product lifecycle to search indexing behavior. Before migrating catalog writes, the new architecture should introduce explicit indexing workflows so write paths are not tightly bound to search availability.

Service order and rationale:

Introduce a Search Service (or equivalent indexing subsystem) behind an event-driven contract. Catalog writes in the new world should publish domain events such as product updated/deleted, and search indexing should consume those events asynchronously, as recommended in `docs/target-architecture.md`.

Gateway routing:

Search query endpoints can be routed to the new Search Service when ready, but the primary goal is to stabilize write-side behavior rather than to move search UI first.

Exit criteria:

The new Catalog Service can publish product lifecycle events and the Search Service can process them without requiring synchronous coupling in the Catalog write path.

### Phase 4: Cart migration (stateful domain, but bounded and well-scoped)

Cart is critical to commerce flows and is a natural bounded context. Migrating cart before orders reduces checkout complexity because it establishes a modern representation of cart state and totals calculation.

Service order and rationale:

Introduce Cart Service, owning shopping cart persistence and cart-total calculations, aligned with the cart entities described in `docs/legacy-shopizer-2x/entity-data-model.md`.

Gateway routing:

Route cart endpoints (add item, update quantity, remove item, view cart) to the new Cart Service. Keep checkout/order placement on legacy initially, or introduce a bridging flow where legacy checkout can read cart state via an adapter.

Exit criteria:

Cart operations are served by the new stack with stable behavior and performance, and the cart state can be used reliably as an input to checkout.

### Phase 5: Order and checkout migration (workflow-heavy, high integration surface area)

Orders and checkout are critical and have the highest integration surface area (shipping quotes, payment authorization/capture, email notifications, and optional digital downloads). This phase should occur after catalog reads, search decoupling, and cart are stable.

Service order and rationale:

Introduce Order Service with explicit checkout orchestration. The target architecture recommends idempotent checkout and integration with payment and shipping via internal APIs.

Introduce Payment Adapter Service and Shipping Rating Service to encapsulate the legacy “module code” seam for integrations, as evidenced in `docs/legacy-shopizer-2x/external-integrations.md`.

Gateway routing:

Route checkout and order endpoints to the new Order Service. Payment redirects and flows that depend on browser interactions (for example PayPal express checkout) should be handled carefully; the roadmap assumes the team may need a compatibility endpoint at the gateway or in the Order Service to manage redirect-style flows.

Exit criteria:

An end-to-end checkout can be completed using the new Order Service + Cart Service + Catalog Service with payment and shipping integrations working via the new adapter services.

### Phase 6: Admin capabilities and configuration (merchant config, integration management)

The legacy system includes an admin UI and admin endpoints for managing integrations and configurations. Migrating admin should happen after core commerce flows are stable so admin actions map to the new service boundaries.

Service order and rationale:

Add administrative APIs per service: catalog admin, order admin, shipping configuration, payment configuration, and merchant settings. Preserve integration module codes as stable identifiers, because the legacy system uses them as configuration keys.

Gateway routing:

Route admin API paths to the new services. The legacy JSP/Tiles admin UI is explicitly not recommended to be ported; the roadmap assumes a new admin UI or API-only administration.

Exit criteria:

Core administrative operations (product management, order management, integration configuration) are supported through the new service APIs with the gateway enforcing access controls.

### Phase 7: Decommission legacy and finalize data ownership

This phase removes remaining legacy routing and decommissions the legacy WAR.

Key activities:

Remove gateway routes to legacy, either by eliminating those paths or by ensuring the new services cover them fully.

Finalize database ownership per service and remove legacy schema dependencies, aligning with the target recommendation of avoiding cross-service joins and using explicit identifiers and projections.

Exit criteria:

No production traffic requires the legacy application. Legacy deployment is removed and operational runbooks are updated for the new services.

## Cross-cutting roadmap items (apply across phases)

### Compatibility boundaries and contracts

The legacy system exposes REST-like endpoints under `/services/**` and UI endpoints under `/shop/**` and `/admin/**`. This roadmap assumes a gateway-driven approach in which compatibility can be retained at the edge (path mapping and versioning) while the internal implementation is modernized.

A practical implementation detail is to define explicit “public API contracts” early and enforce them with consumer-driven contract tests so gateway routing changes do not break clients.

### Observability, reliability, and idempotency

The target architecture introduces network boundaries and asynchronous side effects. Payment and shipping calls must be observable and must use idempotency keys where possible. Checkout must be resilient and resumable.

These concerns are explicitly called out in `docs/target-architecture.md` under cross-cutting concerns and are included here as required engineering work, not optional “hardening”.

### Search and indexing as a side effect, not part of the write transaction

The legacy coupling between product lifecycle and indexing implies that a naive port could reintroduce synchronous coupling. The roadmap requires event-driven indexing and a clear “write succeeds without search being up” posture.

### Integration module codes as a stable seam

The legacy system uses module codes such as `ups`, `usps`, `paypal-express-checkout`, `beanstream`, and `moneyorder`. The roadmap recommends preserving these codes across the migration to minimize merchant configuration migration complexity and to provide a stable “selection key” for adapters.

## Risks and open questions (evidence-based)

The legacy authentication and authorization rules were not fully evidenced in the sources used for the migration analysis and target architecture. In practice, this means Phase 1 must explicitly design a modern security model rather than attempting a direct, mechanical port.

The exact legacy search runtime topology is not fully evidenced. Because search affects write-side behavior, the roadmap intentionally requires decoupling before migrating catalog writes.

The modern repo’s current build layout was not part of the evidence set used for the target architecture document. This roadmap assumes the modern repo can host multiple services over time, but the team may choose to start with a modular monolith and split services later while still using the gateway for controlled routing.
