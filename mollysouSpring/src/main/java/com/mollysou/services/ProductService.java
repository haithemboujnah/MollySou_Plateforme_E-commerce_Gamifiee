package com.mollysou.services;

import com.mollysou.dto.ProductDTO;
import com.mollysou.entities.Product;
import com.mollysou.repositories.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    public List<ProductDTO> getProductsByCategory(Long categoryId) {
        return productRepository.findByCategoryId(categoryId).stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public List<ProductDTO> getAvailableProducts() {
        return productRepository.findByDisponibleTrue().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public ProductDTO getProductById(Long id) {
        return productRepository.findById(id)
                .map(this::convertToDTO)
                .orElse(null);
    }

    private ProductDTO convertToDTO(Product product) {
        ProductDTO dto = new ProductDTO();
        dto.setId(product.getId());
        dto.setNom(product.getNom());
        dto.setDescription(product.getDescription());
        dto.setPrix(product.getPrix());
        dto.setImage(product.getImage());
        dto.setStock(product.getStock());
        dto.setRating(product.getRating());
        dto.setDisponible(product.getDisponible());

        if (product.getCategory() != null) {
            dto.setCategoryNom(product.getCategory().getNom());
            dto.setCategoryId(product.getCategory().getId());
        }

        return dto;
    }
}
