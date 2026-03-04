package com.shopizer.catalog.domain;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "manufacturer", schema = "catalog")
public class Manufacturer {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, length = 255)
  private String name;

  @Column(nullable = false, length = 64, unique = true)
  private String code;

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

  public String getName() {
    return name;
  }

  public Manufacturer setName(String name) {
    this.name = name;
    return this;
  }

  public String getCode() {
    return code;
  }

  public Manufacturer setCode(String code) {
    this.code = code;
    return this;
  }

  public OffsetDateTime getCreatedAt() {
    return createdAt;
  }

  public OffsetDateTime getUpdatedAt() {
    return updatedAt;
  }
}
