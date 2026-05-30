import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/shop_provider.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = Provider.of<ShopProvider>(context);
    final isWish = shop.isProductWishlisted(product.id);
    final isOutOfStock = product.stock == 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isWish ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isWish ? Colors.redAccent : theme.colorScheme.onBackground,
            ),
            onPressed: () => shop.toggleWishlist(product.id),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Large Product Image block
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.04),
              ),
              child: Image.network(
                product.imageUrl,
                fit: product.category == 'Baby Food' ? BoxFit.contain : BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.child_care_rounded, size: 80),
              ),
            ),

            // Details Container
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Product Title & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Ratings Summary block
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${product.reviewsCount} Customer Reviews)',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onBackground.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock Status / Alert triggers
                  if (isOutOfStock)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Currently Out of Stock',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                                ),
                                Text(
                                  'Add this product to your wishlist! We will email you automatically the exact moment it is restocked.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'In Stock (${product.stock} items left)',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Description Paragraph
                  const Text(
                    'About this item',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onBackground.withOpacity(0.65),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Customer Reviews listing
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (product.reviews.isEmpty)
                    Text(
                      'No reviews yet. Be the first to share your thoughts!',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onBackground.withOpacity(0.4),
                      ),
                    )
                  else
                    ...product.reviews.map((rev) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: theme.colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rev.user,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      rev.date,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onBackground.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      Icons.star_rounded,
                                      color: i < rev.rating ? Colors.amber : Colors.grey.shade300,
                                      size: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  rev.comment,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isOutOfStock
                    ? () {
                        shop.toggleWishlist(product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isWish
                                  ? 'Removed from wishlist'
                                  : 'Wishlisted! You will receive an email once in stock.',
                            ),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        );
                      }
                    : () {
                        shop.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart!'),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              onPressed: () {
                                shop.removeFromCart(product.id);
                              },
                            ),
                          ),
                        );
                      },
                icon: Icon(isOutOfStock ? Icons.mail_outline_rounded : Icons.shopping_bag_outlined),
                label: Text(
                  isOutOfStock
                      ? (isWish ? 'Wishlisted (Alert Active)' : 'Notify Me When In Stock')
                      : 'Add to Shopping Cart',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? (isWish ? Colors.grey.shade600 : theme.colorScheme.secondary)
                      : theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
