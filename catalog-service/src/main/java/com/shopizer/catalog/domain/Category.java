package com.shopizer.catalog.domain;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "category", schema = "catalog")
public class Category {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, length = 64, unique = true)
  private String code;

  @Column(nullable = false, length = 255)
  private String name;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "parent_id")
  private Category parent;

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

  public String getCode() {
    return code;
  }

  public Category setCode(String code) {
    this.code = code;
    return this;
  }

  public String getName() {
    return name;
  }

  public Category setName(String name) {
    this.name = name;
    return this;
  }

  public Category getParent() {
    return parent;
  }

  public Category setParent(Category parent) {
    this.parent = parent;
    return this;
  }

  public OffsetDateTime getCreatedAt() {
    return createdAt;
  }

  public OffsetDateTime getUpdatedAt() {
    return updatedAt;
  }
}
