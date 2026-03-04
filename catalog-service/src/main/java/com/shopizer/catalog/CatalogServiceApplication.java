package com.shopizer.catalog;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Catalog Service application entrypoint.
 *
 * Exposes product and category read APIs (and initial write APIs) backed by PostgreSQL.
 */
@SpringBootApplication
@OpenAPIDefinition(
    info = @Info(
        title = "Shopizer Catalog Service",
        version = "0.1.0",
        description = "Catalog microservice for products, categories, and manufacturers in the Shopizer modernized platform."
    ),
    tags = {
        @Tag(name = "Catalog - Products", description = "Product browse and admin operations"),
        @Tag(name = "Catalog - Categories", description = "Category browse and admin operations"),
        @Tag(name = "Operations", description = "Health and operational endpoints")
    }
)
public class CatalogServiceApplication {

  // PUBLIC_INTERFACE
  public static void main(String[] args) {
    /** Service entrypoint. */
    SpringApplication.run(CatalogServiceApplication.class, args);
  }
}
