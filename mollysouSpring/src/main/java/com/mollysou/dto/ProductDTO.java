package com.mollysou.dto;

import java.math.BigDecimal;

public class ProductDTO {
    private Long id;
    private String nom;
    private String description;
    private BigDecimal prix;
    private String image;
    private Integer stock;
    private Double rating;
    private String categoryNom;
    private Long categoryId;
    private Boolean disponible;

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

    public String getCategoryNom() {
        return categoryNom;
    }

    public Long getCategoryId() {
        return categoryId;
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

    public void setCategoryNom(String categoryNom) {
        this.categoryNom = categoryNom;
    }

    public void setCategoryId(Long categoryId) {
        this.categoryId = categoryId;
    }

    public void setDisponible(Boolean disponible) {
        this.disponible = disponible;
    }
}