package com.mollysou.entities;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "categories")
public class Category {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nom;

    private String icon;
    private String color;
    private String description;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<Product> produits = new ArrayList<>();

    public Category() {
    }

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

    public List<Product> getProduits() {
        return produits;
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

    public void setProduits(List<Product> produits) {
        this.produits = produits;
    }
}