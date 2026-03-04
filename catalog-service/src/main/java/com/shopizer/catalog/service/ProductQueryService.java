package com.shopizer.catalog.service;

import com.shopizer.catalog.api.dto.ProductSummaryDto;
import com.shopizer.catalog.repository.ProductRepository;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProductQueryService {

  private static final Logger log = LoggerFactory.getLogger(ProductQueryService.class);

  private final ProductRepository productRepository;

  public ProductQueryService(ProductRepository productRepository) {
    this.productRepository = productRepository;
  }

  // PUBLIC_INTERFACE
  @Transactional(readOnly = true)
  public List<ProductSummaryDto> listActiveProducts() {
    /**
     * Contract:
     * - Inputs: none
     * - Output: list of active products ordered by name; never null
     * - Errors: propagates DB exceptions; boundary is REST controller
     * - Side effects: none (read-only)
     */
    log.info("flow=ProductQueryService.listActiveProducts start");
    var products = productRepository.findByActiveTrueOrderByNameAsc();
    var result = products.stream()
        .map(p -> new ProductSummaryDto(p.getId(), p.getSku(), p.getName(), p.isActive()))
        .toList();
    log.info("flow=ProductQueryService.listActiveProducts end count={}", result.size());
    return result;
  }
}
