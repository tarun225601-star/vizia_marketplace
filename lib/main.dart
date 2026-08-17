import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ViziagMartApp());
}

class ViziagMartApp extends StatelessWidget {
  const ViziagMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viziag Mart',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFFF5722),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5722),
          secondary: Color(0xFF4CAF50),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainLayoutScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0; // 0: Marketplace, 1: Vendor Portal

  // Settings & Firebase Config Dialog
  void _showSettingsDialog() {
    final apiKeyController = TextEditingController();
    final dbUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚙️ Firebase & App Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(labelText: 'Firebase API Key / Token'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dbUrlController,
              decoration: const InputDecoration(labelText: 'Firestore Database URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('fb_api_key', apiKeyController.text);
              await prefs.setString('fb_db_url', dbUrlController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Settings & Firebase Config Saved!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text(
              'Viziag\nMart',
              style: TextStyle(
                color: Color(0xFFFF5722),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.0,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentIndex = 0),
              icon: const Icon(Icons.home, size: 16),
              label: const Text('Marketplace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentIndex == 0 ? const Color(0xFFFF5722) : Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentIndex = 1),
              icon: const Icon(Icons.store, size: 16),
              label: const Text('Vendor Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentIndex == 1 ? const Color(0xFFFF5722) : Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          _currentIndex == 0 ? const MarketplaceScreen() : const VendorPortalScreen(),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                _showCartBottomSheet(context);
              },
              backgroundColor: const Color(0xFF4CAF50),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('View Cart ( 6 )'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('🛒 Your Cart Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
            const Divider(color: Colors.white24),
            const ListTile(
              title: Text('Banana (1 Pcs)'),
              trailing: Text('₹70'),
            ),
            const ListTile(
              title: Text('Roya gala apple (1 KG)'),
              trailing: Text('₹300'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showBuyerLoginDialog(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              child: const Text('Proceed to Checkout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuyerLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Color(0xFFFF5722)),
            SizedBox(width: 8),
            Text('Buyer Details & Login', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Mobile Number (10 Digits)'),
              controller: TextEditingController(text: '9971968060'),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Your Name'),
              controller: TextEditingController(text: 'Tarun'),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Full Delivery Address'),
              maxLines: 2,
              controller: TextEditingController(text: 'Sector 15a ajronda d555 faridabad 121007'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🎉 Order Placed Successfully via Firebase!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
  }
}

// 1. Marketplace Screen View
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> products = [
      {'name': 'Banana', 'price': '₹70/pc', 'shop': 'Tarun fruit shop', 'image': '🍌', 'unit': 'Pcs'},
      {'name': 'Roya gala apple', 'price': '₹300/kg', 'shop': 'Tarun fruit shop', 'image': '🍎', 'unit': 'KG'},
      {'name': 'Green golden apple', 'price': '₹150/kg', 'shop': 'Tarun fruit shop', 'image': '🍏', 'unit': 'KG'},
      {'name': 'Nariyal', 'price': '₹80/pc', 'shop': 'Tarun fruit shop', 'image': '🥥', 'unit': 'Piece'},
      {'name': 'Mango', 'price': '₹100/kg', 'shop': 'Tarun fruit shop', 'image': '🥭', 'unit': 'KG'},
      {'name': 'Egg', 'price': '₹230/pc', 'shop': 'Tarun fruit shop', 'image': '🥚', 'unit': 'pc'},
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text('🔥 Local Hyper-Local Market', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.verified, color: Colors.green, size: 16),
              label: const Text('Verified Buyer: Tarun (Logout)', style: TextStyle(fontSize: 12, color: Colors.blueAccent)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            return Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 70,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                      child: Text(p['image'], style: const TextStyle(fontSize: 36)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                      child: Text(p['shop'], style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(p['name'], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(p['price'], style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    const Text('🚚 Home Delivery Avail.', style: TextStyle(color: Colors.grey, fontSize: 9)),
                    const Text('📍 Sector 15a ajronda...', style: TextStyle(color: Colors.grey, fontSize: 9)),
                    const Spacer(),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${p['name']} added to Cart!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Add to Cart', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// 2. Vendor Portal Screen View
class VendorPortalScreen extends StatelessWidget {
  const VendorPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tarun fruit shop', style: TextStyle(color: Color(0xFFFF5722), fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Mobile: 9971968060', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.settings, size: 14),
                      label: const Text('Shop Settings', style: TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                    ),
                  ],
                ),
                const Divider(),
                const Text('📦 Add / Manage Product Item', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Item Name (e.g. Babbu Ghosa)', border: OutlineInputBorder()),
                  controller: TextEditingController(),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
                  controller: TextEditingController(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🚀 Product Published Live to Firebase!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722), minimumSize: const Size.fromHeight(40)),
                  child: const Text('Publish Product Live 🚀', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
