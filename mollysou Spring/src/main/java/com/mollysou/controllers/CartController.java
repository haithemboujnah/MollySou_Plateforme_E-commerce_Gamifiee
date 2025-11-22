package com.mollysou.controllers;

import com.mollysou.dto.CartDTO;
import com.mollysou.dto.AddToCartDTO;
import com.mollysou.services.CartService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/cart")
@CrossOrigin(origins = "*")
public class CartController {

    @Autowired
    private CartService cartService;

    @GetMapping("/{userId}")
    public ResponseEntity<List<CartDTO>> getUserCart(@PathVariable Long userId) {
        try {
            List<CartDTO> cartItems = cartService.getUserCart(userId);
            return ResponseEntity.ok(cartItems);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/{userId}/add")
    public ResponseEntity<CartDTO> addToCart(@PathVariable Long userId, @RequestBody AddToCartDTO addToCartDTO) {
        try {
            CartDTO cartItem = cartService.addToCart(userId, addToCartDTO);
            return ResponseEntity.ok(cartItem);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PutMapping("/{userId}/update/{productId}")
    public ResponseEntity<Void> updateCartItem(@PathVariable Long userId, @PathVariable Long productId, @RequestParam Integer quantity) {
        try {
            cartService.updateCartItemQuantity(userId, productId, quantity);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @DeleteMapping("/{userId}/remove/{productId}")
    public ResponseEntity<Void> removeFromCart(@PathVariable Long userId, @PathVariable Long productId) {
        try {
            cartService.removeFromCart(userId, productId);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @DeleteMapping("/{userId}/clear")
    public ResponseEntity<Void> clearCart(@PathVariable Long userId) {
        try {
            cartService.clearCart(userId);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/{userId}/count")
    public ResponseEntity<Integer> getCartItemCount(@PathVariable Long userId) {
        try {
            int count = cartService.getCartItemCount(userId);
            return ResponseEntity.ok(count);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}
