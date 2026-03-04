# Legacy Shopizer 2.x (Java 6) Module and Package Map

## Purpose and scope

This document explains how the legacy Shopizer 2.x fork under `shopizer-329083/` is divided into modules, how those modules are wired together, and which packages provide the primary responsibilities. It is intended to help readers navigate the legacy repository while working in the modernization codebase.

This document describes what is evidenced in configuration and representative source code referenced below. If something is described as “not evidenced,” it means it was not confirmed from the sources used for this document.

## High-level module list

The legacy system is primarily organized into two Maven modules.

The `sm-core` module is a JAR that contains the domain model, DAO layer, service layer, persistence and caching configuration, and pluggable integrations for shipping, payment, CMS storage, email, and supporting utilities.

The `sm-shop` module is a WAR that contains the web application. It contains storefront and admin MVC controllers, REST-like endpoints under `/services/**`, view technologies (JSP and Tiles), Spring Security configuration, and additional web DTO classes and “populator” components that transform core entities into web-facing models and vice versa.

## Dependency and build relationship

The `sm-shop` WAR depends on `sm-core` as a normal Maven dependency. This is a conventional monolithic legacy architecture: the web app packages the business layer directly and runs it in-process.

This relationship is evidenced in the legacy module documentation, including references to `sm-shop/pom.xml` and `sm-core/pom.xml`, where `sm-core` defines Java 6 source/target and core infrastructure dependencies (Spring ORM, Hibernate, caches, integration SDKs).

## Web module (`sm-shop`) map

### HTTP entrypoints and Spring MVC configuration

The web application uses classic `web.xml` configuration with a `ContextLoaderListener`, a `DispatcherServlet` mapped to `/`, and a `DelegatingFilterProxy` named `springSecurityFilterChain`. The specific Spring XML descriptors loaded are listed in `WEB-INF/web.xml`.

The MVC servlet context enables annotation-driven controllers and configures Tiles/JSP view resolution, multipart handling, and message bundles for i18n.

### Component scanning across web and core

The MVC layer performs component scanning across both web and core packages, including:

- `com.salesmanager.web`
- `com.salesmanager.core.business`
- `com.salesmanager.core.utils`

This is a key architectural coupling: the web application context discovers and wires `sm-core` services directly.

### Packages and responsibilities

The following package areas are the primary entrypoints for web behavior.

`com.salesmanager.web.shop.controller` contains storefront MVC controllers, including shopping cart and checkout flows.

`com.salesmanager.web.admin.controller` contains admin MVC controllers for managing catalog, orders, shipping, payment configuration, and other backoffice functions.

`com.salesmanager.web.services.controller` contains REST-like endpoints under `/services/**`. These controllers commonly accept web DTOs and use “populator” classes to map to `sm-core` entities.

`com.salesmanager.web.populator` contains DTO/entity mapping components, including components such as `PersistableProductPopulator`.

`com.salesmanager.web.shop.controller.*.facade` contains orchestration services (“facades”) that coordinate multiple `sm-core` services and apply web-specific business rules. `ShoppingCartFacadeImpl` is a representative example.

## Core module (`sm-core`) map

### Domain model (JPA entities)

The core module contains JPA entities under `com.salesmanager.core.business.*.model`. A strong indicator of the core entity set is the explicit list of persistence-unit classes in `sm-core/src/main/resources/META-INF/sm-persistence.xml`.

### DAO layer

The core module uses a DAO pattern, typically under packages like:

- `com.salesmanager.core.business.<area>.dao`
- `com.salesmanager.core.business.<area>.dao.<subarea>`

Services delegate to DAOs for persistence queries and list/search operations.

### Service layer

Services generally live under `com.salesmanager.core.business.<domain>.service` and use Spring stereotypes (for example `@Service("productService")` in `ProductServiceImpl`). Transaction management is configured in the core Spring context.

### Integration modules and registries

The core module uses a “pluggable module registry” pattern for shipping and payments. Spring beans implement integration interfaces and are assembled into `util:map` structures keyed by module code strings. This wiring is evidenced in `shopizer-core-modules.xml`.

Module metadata such as regions and endpoint URIs is also represented in `reference/integrationmodules.json`.

### CMS and static content storage

CMS-like storage for images and static content is implemented via Infinispan-backed managers. The Infinispan cache store uses a file-based backing store configured in `cms/infinispan_configuration.xml`, creating a runtime dependency on local disk paths relative to the servlet container working directory.

## Cross-module coupling notes

This fork is strongly coupled between `sm-shop` and `sm-core` because the web layer component-scans and autowires core services. This reduces friction in a monolithic deployment, but it also means changes to `sm-core` service wiring can break the web module at runtime.

The system also uses shared constants and request attributes across layers, such as request attributes for merchant store resolution.

## Sources

- `shopizer-modern-java21-329083/docs/documentation-conventions.md`: documentation placement conventions for the modern repo.
- `kavia-docs/CodeWiki/Architecture/shopizer-2x-legacy-modules.md`: primary source for legacy module/package organization.
- `kavia-docs/CodeWiki/Architecture/shopizer-2x-legacy-architecture.md`: supporting source for runtime/container coupling.
- `kavia-docs/CodeWiki/Architecture/shopizer-2x-legacy-service-layer.md`: supporting source for controller/facade/populator patterns.
