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
}