package com.shopizer.catalog.repository;

import com.shopizer.catalog.domain.Manufacturer;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ManufacturerRepository extends JpaRepository<Manufacturer, Long> {

  Optional<Manufacturer> findByCode(String code);
}
