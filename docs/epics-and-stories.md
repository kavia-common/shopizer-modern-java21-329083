# Shopizer 2.x → Java 21 Migration Epics and User Stories

## Purpose and scope

This document defines an execution backlog of epics and user stories for a Strangler Fig migration of legacy Shopizer 2.x (the monolithic WAR under `shopizer-329083/`) to a Java 21 / Spring Boot 3.x target architecture with a gateway routing layer, as described in `docs/target-architecture.md`.

The epics and stories are aligned to the phases and sequencing rationale in `docs/migration-analysis.md` and reflect the legacy integration and module seams documented under `docs/legacy-shopizer-2x/`.

This backlog is intentionally “architecture-aware”. Many stories are not user-facing features; they are enabling work required to safely move business functionality without regressions.

## Backlog structure

The backlog is grouped by phase. Each phase contains multiple epics. Each epic contains user stories phrased in a “As a … I want … so that …” form, with brief acceptance criteria.

Where relevant, stories reference stable seams evidenced in the legacy system, such as module codes for payment/shipping integrations and the separation between web controllers/facades/populators and core services.

## Phase 0: Discovery, safety rails, and baseline

### Epic 0.1: Introduce gateway as the stable entry point (pass-through)

As a platform engineer, I want an API gateway deployed in front of the legacy Shopizer WAR so that I can introduce route-by-route strangling without changing clients.

Acceptance criteria: The gateway can route all inbound traffic to the legacy system by default, and can override routing for at least one path to a stub service without breaking other routes.

As a platform engineer, I want gateway routing rules to support path-based routing for legacy areas (`/services/**`, `/shop/**`, `/admin/**`) so that I can migrate capabilities independently.

Acceptance criteria: Routing configuration supports per-path overrides, and the routing rules are version-controlled.

### Epic 0.2: Contract and dependency inventory for migration planning

As a migration engineer, I want an evidence-based inventory of the externally used legacy endpoints so that strangling decisions are traceable and testable.

Acceptance criteria: Endpoint list is grouped by capability area (catalog, cart, orders, customer, reference, admin, integrations), and each group includes the legacy URL paths and the owning legacy package area (controller/facade/service) when available.

As a migration engineer, I want a dependency map of legacy domain capabilities by “fan-in” so that I can prioritize migration order.

Acceptance criteria: The prioritized list matches the criticality framing in `docs/migration-analysis.md`, with catalog, cart, and orders called out as high priority.

### Epic 0.3: Observability and operational safety at the edge

As an operator, I want correlation IDs and structured access logs at the gateway so that I can debug mixed legacy/new request routing during the migration.

Acceptance criteria: Every request has a correlation identifier, it is logged at the gateway, and it is forwarded to downstream services (including legacy) via headers.

As an operator, I want basic rate limiting and request size limits at the gateway so that I can prevent accidental overload and reduce risk while routing behavior changes.

Acceptance criteria: Limits are configurable and can be enabled for specific routes.

## Phase 1: Modern platform foundation (Java 21 / Spring Boot 3.x)

### Epic 1.1: Standard service template and runtime conventions

As a developer, I want a standard Spring Boot 3.x service template targeting Java 21 so that new services can be created consistently.

Acceptance criteria: Template includes health endpoints, configuration conventions, and a consistent logging format.

As a developer, I want a standard approach for externalized configuration so that payment/shipping credentials and environment settings are not embedded in code.

Acceptance criteria: Secrets are loaded from environment or a secrets manager integration approach suitable for the deployment environment.

### Epic 1.2: Database and migrations baseline (PostgreSQL 16 + Flyway)

As a developer, I want Flyway migrations integrated into the service template so that schema changes are versioned and repeatable.

Acceptance criteria: A sample migration runs automatically in local/dev deployment, and the migration history table is created.

As a migration engineer, I want guidance and conventions for schema ownership per service so that we avoid cross-service joins and reduce coupling.

Acceptance criteria: Written conventions exist and match the data flow guidance in `docs/target-architecture.md`.

### Epic 1.3: Security baseline for modern services

As a security engineer, I want a modern authentication and authorization baseline for new services so that admin and shopper capabilities can be protected without relying on legacy servlet-era configuration.

Acceptance criteria: Authentication mechanism is implemented for at least one new service behind the gateway, and admin-only routes are enforced distinctly from public routes.

## Phase 2: Catalog read paths migration

### Epic 2.1: Catalog Service (read-only) behind the gateway

As a shopper, I want to browse categories and view product details served by the new Catalog Service so that the system can migrate high-fan-in reads away from the legacy monolith.

Acceptance criteria: A defined set of catalog read routes are served by the new service through the gateway and return correct data compared to legacy responses for the same store context.

As a developer, I want catalog read DTOs that do not expose JPA entities so that the API remains stable as internal persistence evolves.

Acceptance criteria: DTOs are versioned or otherwise contract-stable, and no JPA entities are serialized directly.

As a developer, I want a clear mapping between legacy catalog concepts (product, category, manufacturer, availability, price) and new service APIs so that functional parity can be verified.

Acceptance criteria: Mapping notes exist and are validated by tests or manual comparison against legacy behavior.

### Epic 2.2: Content/Assets abstraction for product media (if required by catalog reads)

As a shopper, I want product images to resolve consistently while catalog reads move to the new stack so that storefront pages do not break.

Acceptance criteria: Product image URLs returned by the new Catalog Service point to valid media resources, and the strategy for serving them (legacy pass-through, temporary proxying, or new storage) is explicitly documented.

As an operator, I want media storage to be independent of a servlet container working directory so that deployments are reproducible and do not rely on legacy filesystem paths.

Acceptance criteria: The solution does not depend on the legacy Infinispan filesystem cache store paths described in the legacy docs.

## Phase 3: Search decoupling and asynchronous indexing

### Epic 3.1: Event contract for catalog lifecycle (ProductCreated/Updated/Deleted)

As a developer, I want Catalog Service to publish product lifecycle events so that side effects such as indexing can be decoupled from the write transaction.

Acceptance criteria: Events exist for create/update/delete and include stable identifiers and the minimum required projection fields.

As a developer, I want an outbox-style reliability mechanism so that events are not lost when the database transaction commits.

Acceptance criteria: Events are persisted and delivered reliably, and failures can be retried.

### Epic 3.2: Search Service for asynchronous indexing and querying

As a shopper, I want search results to be available even if indexing is eventually consistent so that catalog browsing and product views are not blocked by search outages.

Acceptance criteria: Search can be temporarily stale without breaking core commerce flows, and indexing failures do not prevent catalog writes.

As an operator, I want search indexing to be observable so that I can detect backlogs and failures.

Acceptance criteria: Metrics include indexing lag and error counts, and logs include correlation to product identifiers.

## Phase 4: Cart Service migration

### Epic 4.1: Cart Service core capabilities

As a shopper, I want to add items to a cart and update quantities using the new Cart Service so that cart state is managed in the modern stack.

Acceptance criteria: Add/update/remove/view cart endpoints function correctly for typical scenarios and handle product variants/attributes in a consistent manner.

As a shopper, I want cart totals to be calculated consistently with legacy behavior so that checkout totals remain correct during migration.

Acceptance criteria: Totals calculation matches legacy within agreed tolerances and includes taxes/shipping placeholders as appropriate to the current checkout design.

As a developer, I want Cart Service to be bounded and independently deployable so that cart changes do not require redeploying catalog or order services.

Acceptance criteria: Cart Service has its own persistence boundary and API and can be deployed independently behind the gateway.

### Epic 4.2: Bridge strategy between cart and legacy checkout (transition period)

As a migration engineer, I want a defined bridging approach between new cart state and legacy checkout so that cart can be migrated before full checkout is moved.

Acceptance criteria: The approach is documented and implemented in a way that does not duplicate cart logic in multiple places for an extended period.

## Phase 5: Order and checkout migration (including payments and shipping)

### Epic 5.1: Order Service foundation and order domain model

As a shopper, I want to place an order using the new Order Service so that checkout can be migrated away from the legacy monolith.

Acceptance criteria: Order creation, retrieval, and status tracking are implemented, and core order entities align with the legacy concepts in `docs/legacy-shopizer-2x/entity-data-model.md` (order, order totals, status history, order products).

As a developer, I want checkout operations to be idempotent so that retries do not create duplicate orders.

Acceptance criteria: An idempotency key strategy is implemented and validated by tests.

### Epic 5.2: Shipping Rating Service (adapter-based)

As a shopper, I want to see shipping options during checkout generated by the new Shipping Rating Service so that external carrier calls are isolated and observable.

Acceptance criteria: Shipping options are returned for configured modules, and failures degrade gracefully.

As a merchant admin, I want to configure shipping modules by stable module codes so that migration preserves the legacy “module code” seam.

Acceptance criteria: Module codes such as `ups`, `usps`, `canadapost`, and `weightBased` are represented as stable identifiers, consistent with the legacy integration inventory.

### Epic 5.3: Payment Adapter Service (adapter-based)

As a shopper, I want to authorize and complete payment during checkout using the new Payment Adapter Service so that payment provider behavior is isolated from order orchestration.

Acceptance criteria: Payment intent creation and completion are implemented, including success/failure state transitions recorded in the system.

As a merchant admin, I want to configure payment modules by stable module codes so that existing merchant configurations can be migrated with minimal translation.

Acceptance criteria: Module codes such as `paypal-express-checkout`, `beanstream`, and `moneyorder` are represented as stable identifiers and are supported by the adapter registry.

As an operator, I want payment calls to be resilient and observable so that transient provider errors do not silently fail or double-charge.

Acceptance criteria: Outbound calls use timeouts, retries only where safe, and record provider correlation identifiers where available.

### Epic 5.4: Checkout orchestration (Order + Cart + Catalog + Shipping + Payment)

As a shopper, I want checkout to orchestrate cart snapshotting, shipping selection, and payment authorization so that the end-to-end purchase flow is supported in the new architecture.

Acceptance criteria: Checkout sequence is implemented consistent with the target architecture’s flow (gateway → cart → order → shipping/payment), and key failure modes are handled (payment failure, shipping quote failure, retry).

As an operator, I want the checkout workflow to be traceable end-to-end so that I can diagnose failures across multiple services.

Acceptance criteria: Distributed trace propagation works across gateway and services, and logs include consistent identifiers.

## Phase 6: Admin capabilities and configuration

### Epic 6.1: Catalog administration APIs

As an admin user, I want to create and update products and categories using modern APIs so that legacy admin paths can be decommissioned.

Acceptance criteria: Create/update/delete operations exist, include validation, and preserve any necessary i18n behaviors.

As a developer, I want catalog writes to publish lifecycle events so that indexing and downstream projections remain consistent.

Acceptance criteria: Writes publish events via the same mechanism used in Phase 3.

### Epic 6.2: Order management and operational tooling

As an admin user, I want to view and manage orders in the new system so that order operations do not require legacy admin UI.

Acceptance criteria: Admin APIs support listing orders, viewing detail, and updating statuses consistent with legacy status history behavior.

### Epic 6.3: Merchant configuration and integration management

As an admin user, I want to enable and configure shipping and payment modules using stable module codes so that configuration remains consistent with the legacy “pluggable modules by code” approach.

Acceptance criteria: Admin endpoints exist to manage module enablement and credentials per merchant store context.

## Phase 7: Legacy decommission and final cutover

### Epic 7.1: Complete strangling and remove legacy routes

As an operator, I want all production routes to be served by the gateway and modern services so that the legacy WAR can be safely removed.

Acceptance criteria: Gateway has no routes pointing to legacy in production, and monitoring indicates no traffic depends on legacy endpoints.

### Epic 7.2: Data ownership finalization and migration completion

As a migration engineer, I want service-owned schemas and data migrations finalized so that no modern service depends on legacy database tables.

Acceptance criteria: Each service owns its data, Flyway migrations represent the source of truth, and legacy schema dependencies are removed.

### Epic 7.3: Operational readiness and runbooks

As an operator, I want runbooks and alerts updated for the new services so that production can be supported without legacy operational knowledge.

Acceptance criteria: Runbooks cover gateway routing, core services, and key integrations; alerts exist for payment/shipping failures and indexing backlog.

## Notes on alignment to the existing docs

The phase ordering prioritizes the same high-criticality, high-fan-in domains called out in `docs/migration-analysis.md`, specifically catalog, cart, and orders.

The stories involving payment and shipping preserve the legacy module code seam described in `docs/legacy-shopizer-2x/external-integrations.md`, because it is a concrete, evidenced integration selection pattern.

The search stories reflect the documented coupling between product lifecycle and indexing, but intentionally implement it asynchronously as recommended in `docs/target-architecture.md` to avoid reintroducing tight coupling.
