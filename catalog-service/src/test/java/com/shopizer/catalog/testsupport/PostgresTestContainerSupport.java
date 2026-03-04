package com.shopizer.catalog.testsupport;

import org.springframework.boot.test.context.DynamicPropertyRegistry;
import org.springframework.boot.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * Shared Testcontainers support for PostgreSQL-backed tests.
 *
 * Contract:
 * - Starts a PostgreSQL container once per test JVM.
 * - Publishes Spring datasource properties dynamically.
 * - Flyway will run automatically on application startup in tests.
 */
public abstract class PostgresTestContainerSupport {

  static final PostgreSQLContainer<?> postgres =
      new PostgreSQLContainer<>("postgres:16")
          .withDatabaseName("shopizer")
          .withUsername("shopizer")
          .withPassword("shopizer");

  static {
    postgres.start();
  }

  // PUBLIC_INTERFACE
  @DynamicPropertySource
  static void registerPgProperties(DynamicPropertyRegistry registry) {
    /** Registers datasource properties so Spring Boot uses the container DB. */
    registry.add("spring.datasource.url", postgres::getJdbcUrl);
    registry.add("spring.datasource.username", postgres::getUsername);
    registry.add("spring.datasource.password", postgres::getPassword);
  }
}
