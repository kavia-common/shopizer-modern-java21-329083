package com.shopizer.catalog.repository;

import com.shopizer.catalog.domain.Product;
import com.shopizer.catalog.testsupport.PostgresTestContainerSupport;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class ProductRepositoryIT extends PostgresTestContainerSupport {

  @Autowired
  ProductRepository productRepository;

  @Test
  void saveAndFindBySku_roundTrip() {
    var p = new Product()
        .setSku("SKU-IT-1")
        .setName("Integration Test Product")
        .setDescription("Created in IT")
        .setActive(true);

    productRepository.save(p);

    var loaded = productRepository.findBySku("SKU-IT-1");
    assertThat(loaded).isPresent();
    assertThat(loaded.get().getName()).isEqualTo("Integration Test Product");
  }
}
