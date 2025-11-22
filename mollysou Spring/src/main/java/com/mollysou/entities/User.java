package com.mollysou.entities;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String password;

    private String nomComplet;
    private String genre;
    private Integer niveau = 1;
    private Integer points = 0;
    private Integer xpActuel = 0;
    private Integer xpProchainNiveau = 1000;
    @Column(name = "user_rank")
    private String rank = "BRONZE";

    private String photoProfil;

    @Column(name = "last_wheel_spin")
    private LocalDateTime lastWheelSpin;

    @Column(name = "last_puzzle_game")
    private LocalDateTime lastPuzzleGame;

    @Column(name = "last_video_ad")
    private LocalDateTime lastVideoAd;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public User() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public String getPassword() {
        return password;
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

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void setPassword(String password) {
        this.password = password;
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

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
