import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/shop_provider.dart';
import '../services/auth_provider.dart';
import '../models/product.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0;

  final List<_SidebarItem> _sidebarItems = [
    _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _SidebarItem(icon: Icons.inventory_2_rounded, label: 'Products'),
    _SidebarItem(icon: Icons.receipt_long_rounded, label: 'Orders'),
    _SidebarItem(icon: Icons.people_rounded, label: 'Users'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    final List<Widget> pages = [
      const _DashboardSection(),
      const _ProductsSection(),
      const _OrdersSection(),
      const _UsersSection(),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: isMobile ? Drawer(child: _buildSidebar(theme, auth)) : null,
      body: Row(
        children: [
          // ─── Left Sidebar (Web/Desktop only) ────────────────────────
          if (!isMobile) _buildSidebar(theme, auth),

          // ─── Main Content Area ──────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isMobile) ...[
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _sidebarItems[_selectedIndex].label,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9EAA).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 14, color: Color(0xFFFF9EAA)),
                            SizedBox(width: 4),
                            Text('Admin', style: TextStyle(fontSize: 11, color: Color(0xFFFF9EAA), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Page Content
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, AuthProvider auth) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          // Logo / Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9EAA), Color(0xFFFFB347)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'BabyHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Admin Control Panel',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 32),

          // Nav Items
          ...List.generate(_sidebarItems.length, (i) => _buildNavItem(i, theme)),

          const Spacer(),

          // Admin Name
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFFF9EAA),
                    child: Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.displayName ?? 'Admin',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          auth.currentUser?.email ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // View as User button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                icon: const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFFFF9EAA)),
                label: const Text('View as User', style: TextStyle(fontSize: 11, color: Color(0xFFFF9EAA))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF9EAA), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: Icon(Icons.logout_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
                label: Text('Logout', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, ThemeData theme) {
    final isSelected = _selectedIndex == index;
    final item = _sidebarItems[index];

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold != null && scaffold.isDrawerOpen) {
          Navigator.of(context).pop();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF9EAA).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: const Color(0xFFFF9EAA).withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected ? const Color(0xFFFF9EAA) : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFFF9EAA), shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardSection extends StatefulWidget {
  const _DashboardSection();

  @override
  State<_DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<_DashboardSection> {
  int _totalOrders = 0;
  int _totalUsers = 0;
  double _totalRevenue = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final ordersSnap = await FirebaseFirestore.instance.collection('orders').get();
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      double revenue = 0;
      for (var doc in ordersSnap.docs) {
        revenue += (doc.data()['total'] ?? 0.0) as double;
      }
      if (mounted) {
        setState(() {
          _totalOrders = ordersSnap.docs.length;
          _totalUsers = usersSnap.docs.length;
          _totalRevenue = revenue;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = Provider.of<ShopProvider>(context);
    final products = shop.products;
    final outOfStock = products.where((p) => p.stock == 0).length;

    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(theme, 'Total Products', '${products.length}', Icons.inventory_2_rounded, const Color(0xFF6C63FF)),
              _buildStatCard(theme, 'Total Orders', '$_totalOrders', Icons.receipt_long_rounded, const Color(0xFF00BFA5)),
              _buildStatCard(theme, 'Total Users', '$_totalUsers', Icons.people_rounded, const Color(0xFFFF7043)),
              _buildStatCard(theme, 'Total Revenue', '\$${_totalRevenue.toStringAsFixed(2)}', Icons.attach_money_rounded, const Color(0xFFFF9EAA)),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stock Alerts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$outOfStock products are out of stock', style: TextStyle(color: outOfStock > 0 ? Colors.redAccent : Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        ...products.where((p) => p.stock <= 5).map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: p.stock == 0 ? Colors.redAccent : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(p.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                              Text('${p.stock} left', style: TextStyle(fontSize: 11, color: p.stock == 0 ? Colors.redAccent : Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                        if (products.where((p) => p.stock <= 5).isEmpty)
                          Text('All products are well-stocked!', style: TextStyle(color: Colors.green, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _quickAction(context, Icons.add_box_rounded, 'Add New Product', 'Add a product to the store', const Color(0xFF6C63FF)),
                        const SizedBox(height: 10),
                        _quickAction(context, Icons.receipt_long_rounded, 'View All Orders', 'Review all customer orders', const Color(0xFF00BFA5)),
                        const SizedBox(height: 10),
                        _quickAction(context, Icons.people_rounded, 'Manage Users', 'View and manage all users', const Color(0xFFFF7043)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.2))),
      color: color.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ProductsSection extends StatelessWidget {
  const _ProductsSection();

  void _showProductForm(BuildContext context, {Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product != null ? product.price.toString() : '');
    final stockCtrl = TextEditingController(text: product != null ? product.stock.toString() : '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final imgCtrl = TextEditingController(text: product?.imageUrl ?? '');
    String selectedCategory = product?.category ?? 'Toys';
    final formKey = GlobalKey<FormState>();
    final categories = ['Diapers', 'Baby Food', 'Clothing', 'Toys', 'Bath'];
    final isNew = product == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isNew ? 'Add New Product' : 'Edit Product', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.label_outline)),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            decoration: const InputDecoration(labelText: 'Price (\$)', prefixIcon: Icon(Icons.attach_money)),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(labelText: 'Stock Qty', prefixIcon: Icon(Icons.inventory_2_outlined)),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setDialogState(() => selectedCategory = v ?? selectedCategory),
                      decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imgCtrl,
                      decoration: const InputDecoration(labelText: 'Image URL', prefixIcon: Icon(Icons.image_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: Icon(isNew ? Icons.add : Icons.save_rounded, size: 16),
              label: Text(isNew ? 'Add Product' : 'Save Changes'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final shop = Provider.of<ShopProvider>(context, listen: false);
                final data = {
                  'name': nameCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
                  'category': selectedCategory,
                  'description': descCtrl.text.trim(),
                  'imageUrl': imgCtrl.text.trim(),
                  'rating': product?.rating ?? 5.0,
                  'reviewsCount': product?.reviewsCount ?? 0,
                };
                try {
                  if (isNew) {
                    await FirebaseFirestore.instance.collection('products').add(data);
                  } else {
                    await FirebaseFirestore.instance.collection('products').doc(product.id).update(data);
                    shop.updateProductStock(product.id, int.tryParse(stockCtrl.text.trim()) ?? 0);
                  }
                  await shop.refreshProducts();
                } catch (_) {}
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = Provider.of<ShopProvider>(context);
    final products = shop.products;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${products.length} products in store', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showProductForm(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9EAA), foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 56),
                        Expanded(flex: 3, child: Text('Product Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(p.imageUrl, width: 40, height: 40, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: Colors.grey.shade200,
                                    child: const Icon(Icons.child_care_rounded, size: 20)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(flex: 3, child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                              Expanded(child: Text(p.category, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)))),
                              Expanded(child: Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: p.stock == 0 ? Colors.redAccent : p.stock <= 5 ? Colors.orange : Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('${p.stock}', style: TextStyle(fontSize: 13, color: p.stock == 0 ? Colors.redAccent : theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, size: 18),
                                      color: const Color(0xFF6C63FF),
                                      tooltip: 'Edit',
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _showProductForm(context, product: p),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, size: 18),
                                      color: Colors.redAccent,
                                      tooltip: 'Delete',
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Text('Delete Product'),
                                            content: Text('Are you sure you want to delete "${p.name}"?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  try {
                                                    await FirebaseFirestore.instance.collection('products').doc(p.id).delete();
                                                    await shop.refreshProducts();
                                                  } catch (_) {}
                                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDERS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersSection extends StatefulWidget {
  const _OrdersSection();

  @override
  State<_OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends State<_OrdersSection> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _orders = snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('No orders yet', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 16)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_orders.length} total orders', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              const Spacer(),
              IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('Order ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Customer Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Text('Shipping Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final orderId = (order['id'] as String? ?? '').substring(0, 8).toUpperCase();
                        final email = order['email'] as String? ?? 'N/A';
                        final address = order['address'] as String? ?? 'N/A';
                        final total = (order['total'] ?? 0.0) as double;
                        final items = order['items'] as List? ?? [];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BFA5).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('#$orderId', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00BFA5))),
                                ),
                              ),
                              Expanded(flex: 2, child: Text(email, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                              Expanded(flex: 3, child: Text(address, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)), overflow: TextOverflow.ellipsis)),
                              Expanded(
                                child: Text('\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF9EAA))),
                              ),
                              Expanded(
                                child: Text('${items.length} item${items.length != 1 ? 's' : ''}',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USERS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _UsersSection extends StatefulWidget {
  const _UsersSection();

  @override
  State<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends State<_UsersSection> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        _users = snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleUserRole(String uid, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': newRole});
      _loadUsers();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUid = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('No users found', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 16)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${_users.length} registered users', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              const Spacer(),
              IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 44),
                        Expanded(flex: 2, child: Text('Display Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 3, child: Text('Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Role', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        SizedBox(width: 120, child: Text('Manage Role', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final uid = user['id'] as String? ?? '';
                        final name = user['displayName'] as String? ?? 'Unknown';
                        final email = user['email'] as String? ?? '';
                        final role = user['role'] as String? ?? 'user';
                        final isCurrentUser = uid == currentUid;
                        final isAdmin = role == 'admin';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isAdmin ? const Color(0xFFFF9EAA).withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                                child: Icon(
                                  isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                  size: 16,
                                  color: isAdmin ? const Color(0xFFFF9EAA) : Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  isCurrentUser ? '$name (You)' : name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(flex: 3, child: Text(email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)), overflow: TextOverflow.ellipsis)),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? const Color(0xFFFF9EAA).withOpacity(0.12) : Colors.blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isAdmin ? 'Admin' : 'User',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAdmin ? const Color(0xFFFF9EAA) : Colors.blue),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: isCurrentUser
                                    ? Text('Cannot edit self', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.3)))
                                    : TextButton.icon(
                                        onPressed: () => _toggleUserRole(uid, role),
                                        icon: Icon(isAdmin ? Icons.person_remove_rounded : Icons.admin_panel_settings_rounded, size: 14),
                                        label: Text(isAdmin ? 'Revoke Admin' : 'Make Admin', style: const TextStyle(fontSize: 11)),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isAdmin ? Colors.redAccent : const Color(0xFFFF9EAA),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
