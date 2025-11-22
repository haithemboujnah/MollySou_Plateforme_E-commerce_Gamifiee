package com.mollysou.repositories;

import com.mollysou.entities.Cart;
import com.mollysou.entities.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CartRepository extends JpaRepository<Cart, Long> {
    List<Cart> findByUser(User user);
    Optional<Cart> findByUserAndProductId(User user, Long productId);

    @Modifying
    @Query("DELETE FROM Cart c WHERE c.user = :user AND c.product.id = :productId")
    void deleteByUserAndProductId(@Param("user") User user, @Param("productId") Long productId);

    @Modifying
    @Query("DELETE FROM Cart c WHERE c.user = :user")
    void deleteByUser(@Param("user") User user);

    int countByUser(User user);
}