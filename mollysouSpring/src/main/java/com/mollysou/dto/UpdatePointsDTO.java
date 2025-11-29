package com.mollysou.dto;

public class UpdatePointsDTO {
    private Integer points;
    private Integer xp;

    public UpdatePointsDTO() {}

    public UpdatePointsDTO(Integer points, Integer xp) {
        this.points = points;
        this.xp = xp;
    }

    public Integer getPoints() {
        return points;
    }

    public Integer getXp() {
        return xp;
    }

    public void setPoints(Integer points) {
        this.points = points;
    }

    public void setXp(Integer xp) {
        this.xp = xp;
    }
}
