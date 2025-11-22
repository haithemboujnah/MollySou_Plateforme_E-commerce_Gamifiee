package com.mollysou.entities;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "products")
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nom;

    private String description;
    private BigDecimal prix;
    private String image;
    private Integer stock;
    private Double rating = 0.0;
    private Integer nombreAvis = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    private Boolean disponible = true;

    public Long getId() {
        return id;
    }

    public String getNom() {
        return nom;
    }

    public String getDescription() {
        return description;
    }

    public BigDecimal getPrix() {
        return prix;
    }

    public String getImage() {
        return image;
    }

    public Integer getStock() {
        return stock;
    }

    public Double getRating() {
        return rating;
    }

    public Integer getNombreAvis() {
        return nombreAvis;
    }

    public Category getCategory() {
        return category;
    }

    public Boolean getDisponible() {
        return disponible;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setPrix(BigDecimal prix) {
        this.prix = prix;
    }

    public void setImage(String image) {
        this.image = image;
    }

    public void setStock(Integer stock) {
        this.stock = stock;
    }

    public void setRating(Double rating) {
        this.rating = rating;
    }

    public void setNombreAvis(Integer nombreAvis) {
        this.nombreAvis = nombreAvis;
    }

    public void setCategory(Category category) {
        this.category = category;
    }

    public void setDisponible(Boolean disponible) {
        this.disponible = disponible;
    }
}