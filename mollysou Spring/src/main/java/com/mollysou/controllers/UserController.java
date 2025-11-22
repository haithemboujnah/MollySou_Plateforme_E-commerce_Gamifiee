package com.mollysou.controllers;

import com.mollysou.dto.*;
import com.mollysou.services.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping("/register")
    public ResponseEntity<UserDTO> register(@RequestBody UserAuthDTO userDTO) {
        try {
            UserDTO createdUser = userService.createUser(userDTO);
            return ResponseEntity.ok(createdUser);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/login")
    public ResponseEntity<UserDTO> login(@RequestBody UserAuthDTO loginDTO) {
        return userService.login(loginDTO.getEmail(), loginDTO.getPassword())
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.status(401).build());
    }

    @GetMapping("/{userId}/rank-info")
    public ResponseEntity<UserRankInfoDTO> getRankInfo(@PathVariable Long userId, @RequestParam Integer level) {
        UserRankInfoDTO rankInfo = userService.getUserRankInfo(level);
        return ResponseEntity.ok(rankInfo);
    }

    @GetMapping("/{userId}/cooldowns")
    public ResponseEntity<CooldownDTO> getCooldowns(@PathVariable Long userId) {
        CooldownDTO cooldowns = userService.getUserCooldowns(userId);
        return ResponseEntity.ok(cooldowns);
    }

    @PostMapping("/{userId}/cooldown/{type}")
    public ResponseEntity<Void> updateCooldown(@PathVariable Long userId, @PathVariable String type) {
        userService.updateUserCooldown(userId, type);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{userId}/add-points")
    public ResponseEntity<UserDTO> addPoints(
            @PathVariable Long userId,
            @RequestBody UpdatePointsDTO pointsDTO) {
        try {
            UserDTO updatedUser = userService.addPoints(userId, pointsDTO.getPoints());
            return ResponseEntity.ok(updatedUser);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{userId}/add-xp")
    public ResponseEntity<UserDTO> addXP(
            @PathVariable Long userId,
            @RequestBody UpdatePointsDTO xpDTO) {
        try {
            UserDTO updatedUser = userService.addXP(userId, xpDTO.getXp());
            return ResponseEntity.ok(updatedUser);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{userId}/update-points-xp")
    public ResponseEntity<UserDTO> updatePointsAndXP(
            @PathVariable Long userId,
            @RequestBody UpdatePointsDTO updateDTO) {
        try {
            UserDTO updatedUser = userService.updateUserPointsAndXP(
                    userId,
                    updateDTO.getPoints(),
                    updateDTO.getXp()
            );
            return ResponseEntity.ok(updatedUser);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}