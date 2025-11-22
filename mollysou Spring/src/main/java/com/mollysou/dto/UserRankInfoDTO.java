package com.mollysou.dto;

public class UserRankInfoDTO {
    private String name;
    private String color;
    private String borderColor;
    private String discount;
    private String[] gradient;

    public UserRankInfoDTO(String name, String color, String borderColor, String discount, String[] gradient) {
        this.name = name;
        this.color = color;
        this.borderColor = borderColor;
        this.discount = discount;
        this.gradient = gradient;
    }

    public String getName() {
        return name;
    }

    public String getColor() {
        return color;
    }

    public String getBorderColor() {
        return borderColor;
    }

    public String getDiscount() {
        return discount;
    }

    public String[] getGradient() {
        return gradient;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public void setBorderColor(String borderColor) {
        this.borderColor = borderColor;
    }

    public void setDiscount(String discount) {
        this.discount = discount;
    }

    public void setGradient(String[] gradient) {
        this.gradient = gradient;
    }
}

