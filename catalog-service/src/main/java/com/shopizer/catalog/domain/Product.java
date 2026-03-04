package com.shopizer.catalog.domain;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "product", schema = "catalog")
public class Product {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, length = 64, unique = true)
  private String sku;

  @Column(nullable = false, length = 255)
  private String name;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Column(nullable = false)
  private boolean active = true;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "manufacturer_id")
  private Manufacturer manufacturer;

  @ManyToMany
  @JoinTable(
      schema = "catalog",
      name = "product_category",
      joinColumns = @JoinColumn(name = "product_id"),
      inverseJoinColumns = @JoinColumn(name = "category_id")
  )
  private Set<Category> categories = new HashSet<>();

  @Column(name = "created_at", nullable = false)
  private OffsetDateTime createdAt;

  @Column(name = "updated_at", nullable = false)
  private OffsetDateTime updatedAt;

  @PrePersist
  void prePersist() {
    var now = OffsetDateTime.now();
    createdAt = now;
    updatedAt = now;
  }

  @PreUpdate
  void preUpdate() {
    updatedAt = OffsetDateTime.now();
  }

  public Long getId() {
    return id;
  }

  public String getSku() {
    return sku;
  }

  public Product setSku(String sku) {
    this.sku = sku;
    return this;
  }

  public String getName() {
    return name;
  }

  public Product setName(String name) {
    this.name = name;
    return this;
  }

  public String getDescription() {
    return description;
  }

  public Product setDescription(String description) {
    this.description = description;
    return this;
  }

  public boolean isActive() {
    return active;
  }

  public Product setActive(boolean active) {
    this.active = active;
    return this;
  }

  public Manufacturer getManufacturer() {
    return manufacturer;
  }

  public Product setManufacturer(Manufacturer manufacturer) {
    this.manufacturer = manufacturer;
    return this;
  }

  public Set<Category> getCategories() {
    return categories;
  }

  public OffsetDateTime getCreatedAt() {
    return createdAt;
  }

  public OffsetDateTime getUpdatedAt() {
    return updatedAt;
  }
}
