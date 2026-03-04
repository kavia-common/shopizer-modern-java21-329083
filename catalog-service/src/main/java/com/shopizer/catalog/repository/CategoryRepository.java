package com.shopizer.catalog.repository;

import com.shopizer.catalog.domain.Category;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, Long> {

  Optional<Category> findByCode(String code);
}
