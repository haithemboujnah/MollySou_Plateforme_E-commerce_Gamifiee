package com.mollysou.services;

import com.mollysou.dto.*;
import com.mollysou.entities.*;
import com.mollysou.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    public UserDTO createUser(UserAuthDTO userDTO) {
        User user = new User();
        user.setEmail(userDTO.getEmail());
        user.setPassword(userDTO.getPassword()); // Should be encrypted
        user.setNomComplet(userDTO.getNomComplet());
        user.setGenre(userDTO.getGenre());

        User savedUser = userRepository.save(user);
        return convertToDTO(savedUser);
    }

    public Optional<UserDTO> login(String email, String password) {
        return userRepository.findByEmail(email)
                .filter(user -> user.getPassword().equals(password)) // Use proper password encoding
                .map(this::convertToDTO);
    }

    public UserRankInfoDTO getUserRankInfo(Integer level) {
        if (level >= 200) {
            return new UserRankInfoDTO("DIAMOND", "#1E3A8A", "#0BC5EA", "50% discount",
                    new String[]{"#1E3A8A", "#3B82F6"});
        } else if (level >= 100) {
            return new UserRankInfoDTO("PLATINUM", "#0BC5EA", "#1E3A8A", "20% discount",
                    new String[]{"#06B6D4", "#0BC5EA"});
        } else if (level >= 50) {
            return new UserRankInfoDTO("GOLD", "#FFD700", "#FFA500", "15% discount",
                    new String[]{"#FFF8DC", "#FFD700"});
        } else if (level >= 30) {
            return new UserRankInfoDTO("SILVER", "#C0C0C0", "#A9A9A9", "10% discount",
                    new String[]{"#F0F0F0", "#C0C0C0"});
        } else {
            return new UserRankInfoDTO("BRONZE", "#CD7F32", "#8B4513", "5% discount",
                    new String[]{"#DEB887", "#CD7F32"});
        }
    }

    public void updateUserCooldown(Long userId, String type) {
        User user = userRepository.findById(userId).orElseThrow();
        LocalDateTime now = LocalDateTime.now();

        switch (type) {
            case "wheel":
                user.setLastWheelSpin(now);
                break;
            case "puzzle":
                user.setLastPuzzleGame(now);
                break;
            case "video":
                user.setLastVideoAd(now);
                break;
        }

        userRepository.save(user);
    }

    public CooldownDTO getUserCooldowns(Long userId) {
        User user = userRepository.findById(userId).orElseThrow();
        LocalDateTime now = LocalDateTime.now();

        return new CooldownDTO(
                calculateRemainingTime(user.getLastWheelSpin(), now, 24),
                calculateRemainingTime(user.getLastPuzzleGame(), now, 1),
                calculateRemainingTime(user.getLastVideoAd(), now, 3)
        );
    }

    private Long calculateRemainingTime(LocalDateTime lastTime, LocalDateTime now, int hours) {
        if (lastTime == null) return 0L;

        LocalDateTime nextAvailable = lastTime.plusHours(hours);
        if (now.isBefore(nextAvailable)) {
            return java.time.Duration.between(now, nextAvailable).getSeconds();
        }
        return 0L;
    }

    private UserDTO convertToDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setEmail(user.getEmail());
        dto.setNomComplet(user.getNomComplet());
        dto.setGenre(user.getGenre());
        dto.setNiveau(user.getNiveau());
        dto.setPoints(user.getPoints());
        dto.setXpActuel(user.getXpActuel());
        dto.setXpProchainNiveau(user.getXpProchainNiveau());
        dto.setRank(user.getRank());
        dto.setPhotoProfil(user.getPhotoProfil());
        dto.setLastWheelSpin(user.getLastWheelSpin());
        dto.setLastPuzzleGame(user.getLastPuzzleGame());
        dto.setLastVideoAd(user.getLastVideoAd());
        return dto;
    }
}