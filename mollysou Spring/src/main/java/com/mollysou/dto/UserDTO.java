package com.mollysou.dto;

import java.time.LocalDateTime;

public class UserDTO {
    private Long id;
    private String email;
    private String nomComplet;
    private String genre;
    private Integer niveau;
    private Integer points;
    private Integer xpActuel;
    private Integer xpProchainNiveau;
    private String rank;
    private String photoProfil;
    private LocalDateTime lastWheelSpin;
    private LocalDateTime lastPuzzleGame;
    private LocalDateTime lastVideoAd;

    public UserDTO(String email, String nomComplet, String genre, Integer niveau, Integer points, Integer xpActuel, Integer xpProchainNiveau, String rank, String photoProfil, LocalDateTime lastWheelSpin, LocalDateTime lastPuzzleGame, LocalDateTime lastVideoAd) {
        this.email = email;
        this.nomComplet = nomComplet;
        this.genre = genre;
        this.niveau = niveau;
        this.points = points;
        this.xpActuel = xpActuel;
        this.xpProchainNiveau = xpProchainNiveau;
        this.rank = rank;
        this.photoProfil = photoProfil;
        this.lastWheelSpin = lastWheelSpin;
        this.lastPuzzleGame = lastPuzzleGame;
        this.lastVideoAd = lastVideoAd;
    }

    public UserDTO() {

    }

    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getNomComplet() {
        return nomComplet;
    }

    public String getGenre() {
        return genre;
    }

    public Integer getNiveau() {
        return niveau;
    }

    public Integer getPoints() {
        return points;
    }

    public Integer getXpActuel() {
        return xpActuel;
    }

    public Integer getXpProchainNiveau() {
        return xpProchainNiveau;
    }

    public String getRank() {
        return rank;
    }

    public String getPhotoProfil() {
        return photoProfil;
    }

    public LocalDateTime getLastWheelSpin() {
        return lastWheelSpin;
    }

    public LocalDateTime getLastPuzzleGame() {
        return lastPuzzleGame;
    }

    public LocalDateTime getLastVideoAd() {
        return lastVideoAd;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setNomComplet(String nomComplet) {
        this.nomComplet = nomComplet;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

    public void setNiveau(Integer niveau) {
        this.niveau = niveau;
    }

    public void setPoints(Integer points) {
        this.points = points;
    }

    public void setXpActuel(Integer xpActuel) {
        this.xpActuel = xpActuel;
    }

    public void setXpProchainNiveau(Integer xpProchainNiveau) {
        this.xpProchainNiveau = xpProchainNiveau;
    }

    public void setRank(String rank) {
        this.rank = rank;
    }

    public void setPhotoProfil(String photoProfil) {
        this.photoProfil = photoProfil;
    }

    public void setLastWheelSpin(LocalDateTime lastWheelSpin) {
        this.lastWheelSpin = lastWheelSpin;
    }

    public void setLastPuzzleGame(LocalDateTime lastPuzzleGame) {
        this.lastPuzzleGame = lastPuzzleGame;
    }

    public void setLastVideoAd(LocalDateTime lastVideoAd) {
        this.lastVideoAd = lastVideoAd;
    }
}

