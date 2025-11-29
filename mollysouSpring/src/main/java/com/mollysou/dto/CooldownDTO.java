package com.mollysou.dto;

public class CooldownDTO {
    private Long wheelCooldown;
    private Long puzzleCooldown;
    private Long videoCooldown;
    private Long reflexCooldown;

    public CooldownDTO(Long wheelCooldown, Long puzzleCooldown, Long videoCooldown, Long reflexCooldown) {
        this.wheelCooldown = wheelCooldown;
        this.puzzleCooldown = puzzleCooldown;
        this.videoCooldown = videoCooldown;
        this.reflexCooldown = reflexCooldown;
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

    public Long getReflexCooldown() {
        return reflexCooldown;
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

    public void setReflexCooldown(Long reflexCooldown) {this.reflexCooldown = reflexCooldown;}
}
