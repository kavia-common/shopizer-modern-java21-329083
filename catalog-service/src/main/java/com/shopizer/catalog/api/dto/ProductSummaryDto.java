package com.shopizer.catalog.api.dto;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "ProductSummary", description = "Minimal product representation for catalog browsing.")
public record ProductSummaryDto(
    @Schema(description = "Database identifier", example = "1001") Long id,
    @Schema(description = "Stock keeping unit", example = "SKU-123") String sku,
    @Schema(description = "Display name", example = "Blue T-Shirt") String name,
    @Schema(description = "Whether the product is active and visible", example = "true") boolean active
) {}
