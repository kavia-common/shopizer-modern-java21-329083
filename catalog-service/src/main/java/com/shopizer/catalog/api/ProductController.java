package com.shopizer.catalog.api;

import com.shopizer.catalog.api.dto.ProductSummaryDto;
import com.shopizer.catalog.service.ProductQueryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "/api/v1/catalog/products", produces = MediaType.APPLICATION_JSON_VALUE)
@Tag(name = "Catalog - Products")
public class ProductController {

  private final ProductQueryService productQueryService;

  public ProductController(ProductQueryService productQueryService) {
    this.productQueryService = productQueryService;
  }

  // PUBLIC_INTERFACE
  @GetMapping
  @Operation(
      summary = "List active products",
      description = "Returns active products ordered by name. This is a public catalog-browse endpoint."
  )
  public List<ProductSummaryDto> listActiveProducts() {
    /** Returns a list of active products. */
    return productQueryService.listActiveProducts();
  }
}
