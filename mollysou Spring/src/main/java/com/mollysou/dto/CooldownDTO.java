package com.mollysou.dto;

public class CooldownDTO {
    private Long wheelCooldown;
    private Long puzzleCooldown;
    private Long videoCooldown;

    public CooldownDTO(Long wheelCooldown, Long puzzleCooldown, Long videoCooldown) {
        this.wheelCooldown = wheelCooldown;
        this.puzzleCooldown = puzzleCooldown;
        this.videoCooldown = videoCooldown;
    }

    public Long getWheelCooldown() {
        return wheelCooldown;
    }

    public Long getPuzzleCooldown() {
        return puzzleCooldown;
    }

    public Long getVideoCooldown() {
        return videoCooldown;
    }

    public void setWheelCooldown(Long wheelCooldown) {
        this.wheelCooldown = wheelCooldown;
    }

    public void setPuzzleCooldown(Long puzzleCooldown) {
        this.puzzleCooldown = puzzleCooldown;
    }

    public void setVideoCooldown(Long videoCooldown) {
        this.videoCooldown = videoCooldown;
    }
}
