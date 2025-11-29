package com.mollysou.dto;

import java.time.LocalDate;
import java.math.BigDecimal;

public class EventDTO {
    private Long id;
    private String titre;
    private String description;
    private LocalDate date;
    private BigDecimal prix;
    private String image;
    private String lieu;
    private Double rating;
    private String type;

    public Long getId() {
        return id;
    }

    public String getTitre() {
        return titre;
    }

    public String getDescription() {
        return description;
    }

    public LocalDate getDate() {
        return date;
    }

    public BigDecimal getPrix() {
        return prix;
    }

    public String getImage() {
        return image;
    }

    public String getLieu() {
        return lieu;
    }

    public Double getRating() {
        return rating;
    }

    public String getType() {
        return type;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setTitre(String titre) {
        this.titre = titre;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setDate(LocalDate date) {
        this.date = date;
    }

    public void setPrix(BigDecimal prix) {
        this.prix = prix;
    }

    public void setImage(String image) {
        this.image = image;
    }

    public void setLieu(String lieu) {
        this.lieu = lieu;
    }

    public void setRating(Double rating) {
        this.rating = rating;
    }

    public void setType(String type) {
        this.type = type;
    }
}