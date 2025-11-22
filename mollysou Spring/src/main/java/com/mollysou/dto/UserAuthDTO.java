package com.mollysou.dto;

public class UserAuthDTO {
    private String email;
    private String password;
    private String nomComplet;
    private String genre;

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
}


