package com.mollysou.dto;

public class CategoryDTO {
    private Long id;
    private String nom;
    private String icon;
    private String color;
    private String description;
    private Integer nombreProduits;

    public Long getId() {
        return id;
    }

    public String getNom() {
        return nom;
    }

    public String getIcon() {
        return icon;
    }

    public String getColor() {
        return color;
    }

    public String getDescription() {
        return description;
    }

    public Integer getNombreProduits() {
        return nombreProduits;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setNombreProduits(Integer nombreProduits) {
        this.nombreProduits = nombreProduits;
    }
}