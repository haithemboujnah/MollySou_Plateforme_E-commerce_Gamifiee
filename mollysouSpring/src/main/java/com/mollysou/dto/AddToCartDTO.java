package com.mollysou.dto;

public class AddToCartDTO {
    private Long productId;
    private Integer quantity;

    public AddToCartDTO() {}

    public AddToCartDTO(Long productId, Integer quantity) {
        this.productId = productId;
        this.quantity = quantity;
    }

    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }

    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
}