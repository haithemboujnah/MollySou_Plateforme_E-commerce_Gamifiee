package com.mollysou.services;

import com.mollysou.dto.CategoryDTO;
import com.mollysou.entities.Category;
import com.mollysou.repositories.CategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class CategoryService {

    @Autowired
    private CategoryRepository categoryRepository;

    public List<CategoryDTO> getAllCategories() {
        return categoryRepository.findAll().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public CategoryDTO getCategoryById(Long id) {
        return categoryRepository.findById(id)
                .map(this::convertToDTO)
                .orElse(null);
    }

    private CategoryDTO convertToDTO(Category category) {
        CategoryDTO dto = new CategoryDTO();
        dto.setId(category.getId());
        dto.setNom(category.getNom());
        dto.setIcon(category.getIcon());
        dto.setColor(category.getColor());
        dto.setDescription(category.getDescription());
        dto.setNombreProduits(category.getProduits() != null ? category.getProduits().size() : 0);
        return dto;
    }
}