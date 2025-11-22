package com.mollysou.services;

import com.mollysou.dto.CartDTO;
import com.mollysou.dto.AddToCartDTO;
import com.mollysou.entities.Cart;
import com.mollysou.entities.User;
import com.mollysou.entities.Product;
import com.mollysou.repositories.CartRepository;
import com.mollysou.repositories.UserRepository;
import com.mollysou.repositories.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class CartService {

    @Autowired
    private CartRepository cartRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProductRepository productRepository;

    public List<CartDTO> getUserCart(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return cartRepository.findByUser(user).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public CartDTO addToCart(Long userId, AddToCartDTO addToCartDTO) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Product product = productRepository.findById(addToCartDTO.getProductId())
                .orElseThrow(() -> new RuntimeException("Product not found"));

        // Check if product is available
        if (!product.getDisponible() || product.getStock() <= 0) {
            throw new RuntimeException("Product not available");
        }

        // Check if product already in cart
        Optional<Cart> existingCartItem = cartRepository.findByUserAndProductId(user, product.getId());

        if (existingCartItem.isPresent()) {
            // Update quantity
            Cart cartItem = existingCartItem.get();
            int newQuantity = cartItem.getQuantity() + addToCartDTO.getQuantity();

            // Check stock availability
            if (newQuantity > product.getStock()) {
                throw new RuntimeException("Not enough stock available");
            }

            cartItem.setQuantity(newQuantity);
            Cart savedCart = cartRepository.save(cartItem);
            return convertToDTO(savedCart);
        } else {
            // Add new item to cart
            Cart cartItem = new Cart();
            cartItem.setUser(user);
            cartItem.setProduct(product);
            cartItem.setQuantity(addToCartDTO.getQuantity());

            Cart savedCart = cartRepository.save(cartItem);
            return convertToDTO(savedCart);
        }
    }

    @Transactional
    public void updateCartItemQuantity(Long userId, Long productId, Integer quantity) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Cart cartItem = cartRepository.findByUserAndProductId(user, productId)
                .orElseThrow(() -> new RuntimeException("Cart item not found"));

        Product product = cartItem.getProduct();

        // Check stock availability
        if (quantity > product.getStock()) {
            throw new RuntimeException("Not enough stock available");
        }

        if (quantity <= 0) {
            cartRepository.delete(cartItem);
        } else {
            cartItem.setQuantity(quantity);
            cartRepository.save(cartItem);
        }
    }

    @Transactional
    public void removeFromCart(Long userId, Long productId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        cartRepository.deleteByUserAndProductId(user, productId);
    }

    @Transactional
    public void clearCart(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        cartRepository.deleteByUser(user);
    }

    public int getCartItemCount(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return cartRepository.countByUser(user);
    }

    private CartDTO convertToDTO(Cart cart) {
        CartDTO dto = new CartDTO();
        dto.setId(cart.getId());
        dto.setProductId(cart.getProduct().getId());
        dto.setProductName(cart.getProduct().getNom());
        dto.setProductImage(cart.getProduct().getImage());
        dto.setPrice(cart.getProduct().getPrix());
        dto.setQuantity(cart.getQuantity());
        dto.setStock(cart.getProduct().getStock());

        if (cart.getProduct().getCategory() != null) {
            dto.setCategory(cart.getProduct().getCategory().getNom());
        }

        return dto;
    }
}