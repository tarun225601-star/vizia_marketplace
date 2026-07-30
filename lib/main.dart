import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ViziaMarketplaceApp());
}

class ViziaMarketplaceApp extends StatelessWidget {
  const ViziaMarketplaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizia Marketplace Faridabad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.teal,
      ),
      home: const MarketplaceFeedScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. MAIN FEED & MARKETPLACE SCREEN
// -----------------------------------------------------------------------------
class MarketplaceFeedScreen extends StatefulWidget {
  const MarketplaceFeedScreen({Key? key}) : super(key: key);

  @override
  _MarketplaceFeedScreenState createState() => _MarketplaceFeedScreenState();
}

class _MarketplaceFeedScreenState extends State<MarketplaceFeedScreen> {
  String _searchQuery = "";
  final List<Map<String, dynamic>> _cart = [];
  bool _isSupabaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkSupabaseConfig();
  }

  Future<void> _checkSupabaseConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('supabase_url') ?? '';
    final key = prefs.getString('supabase_key') ?? '';

    if (url.isNotEmpty && key.isNotEmpty) {
      try {
        await Supabase.initialize(url: url, anonKey: key);
        setState(() {
          _isSupabaseInitialized = true;
        });
      } catch (e) {
        // Initialization error handled silently or show settings
      }
    }
  }

  void _addToCart(String productName, double price, String shopName) {
    setState(() {
      _cart.add({'name': productName, 'price': price, 'shop': shopName});
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$productName कार्ट में जोड़ दिया गया!'), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia Marketplace'),
        backgroundColor: Colors.teal[800],
        actions: [
          // कार्ट आइकॉन
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCartModal(context),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_cart.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // वेंडर लॉगिन बटन
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => _showVendorLoginDialog(context),
          ),
          // सेटिंग्स बटन (URL और Key डालने के लिए)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _checkSupabaseConfig();
            },
          ),
        ],
      ),
      body: !_isSupabaseInitialized
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'कृपया सेटिंग्स में जाकर अपनी Supabase URL और Key दर्ज करें!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                        _checkSupabaseConfig();
                      },
                      child: const Text('सेटिंग्स खोलें'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // सर्च बार
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'दुकान या सामान सर्च करें...',
                      prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                
                // लाइव फीड और शॉप्स लिस्ट
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client.from('shops').stream(primaryKey: ['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.teal));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'अभी कोई दुकान उपलब्ध नहीं है।',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      final shops = snapshot.data!;

                      return ListView.builder(
                        itemCount: shops.length,
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          final shopName = shop['shop_name'] ?? 'Unnamed Shop';
                          final ownerName = shop['owner_name'] ?? '';
                          final shopImage = shop['shop_image'] ?? '';
                          final ownerImage = shop['owner_image'] ?? '';
                          final shopId = shop['id'].toString();

                          if (_searchQuery.isNotEmpty && !shopName.toLowerCase().contains(_searchQuery)) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.all(10),
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (shopImage.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(
                                      shopImage,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: ownerImage.isNotEmpty ? NetworkImage(ownerImage) : null,
                                        child: ownerImage.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shopName,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Owner: $ownerName',
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(color: Colors.grey, height: 1),

                                // उस दुकान के प्रोडक्ट्स की लाइव लिस्ट
                                StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: Supabase.instance.client
                                      .from('products')
                                      .stream(primaryKey: ['id'])
                                      .eq('shop_id', shopId),
                                  builder: (context, productSnapshot) {
                                    if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          'इस दुकान पर अभी कोई सामान लिस्ट नहीं है।',
                                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                        ),
                                      );
                                    }

                                    final products = productSnapshot.data!;

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: products.length,
                                      itemBuilder: (context, pIndex) {
                                        final product = products[pIndex];
                                        final productName = product['product_name'] ?? '';
                                        final productPrice = (product['price'] ?? 0).toDouble();
                                        final productImage = product['product_image'] ?? '';

                                        return ListTile(
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: productImage.isNotEmpty
                                                ? Image.network(productImage, width: 50, height: 50, fit: BoxFit.cover)
                                                : Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.shopping_bag)),
                                          ),
                                          title: Text(productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          subtitle: Text('₹$productPrice', style: const TextStyle(color: Colors.greenAccent)),
                                          trailing: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                            onPressed: () => _addToCart(productName, productPrice, shopName),
                                            child: const Text('Add'),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // वेंडर लॉगिन डायलॉग (अलग एडमिन पैनल के लिए)
  void _showVendorLoginDialog(BuildContext context) {
    final TextEditingController shopIdController = TextEditingController();
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Vendor Admin Login', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: shopIdController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Shop ID / Name', labelStyle: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Secret PIN', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorAdminPanel(
                      shopId: shopIdController.text.trim(),
                      shopName: shopIdController.text.trim(),
                    ),
                  ),
                );
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  // कार्ट चेकआउट बॉटम शीट
  void _showCartModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        double total = _cart.fold(0, (sum, item) => sum + (item['price'] as double));
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('आपकी कार्ट (Cart)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.grey),
              _cart.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20.0), child: Text('कार्ट खाली है!', style: TextStyle(color: Colors.grey)))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final item = _cart[index];
                          return ListTile(
                            title: Text(item['name'], style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Shop: ${item['shop']}', style: const TextStyle(color: Colors.grey)),
                            trailing: Text('₹${item['price']}', style: const TextStyle(color: Colors.greenAccent)),
                          );
                        },
                      ),
                    ),
              if (_cart.isNotEmpty) ...[
                const Divider(color: Colors.grey),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: ₹$total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _cart.clear());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ऑर्डर सफलतापूर्वक प्लेस हो गया!')),
                        );
                      },
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 2. VENDOR ADMIN PANEL (फोटो अपलोड और प्रोडक्ट जोड़ने की सुविधा के साथ)
// -----------------------------------------------------------------------------
class VendorAdminPanel extends StatefulWidget {
  final String shopId;
  final String shopName;

  const VendorAdminPanel({Key? key, required this.shopId, required this.shopName}) : super(key: key);

  @override
  _VendorAdminPanelState createState() => _VendorAdminPanelState();
}

class _VendorAdminPanelState extends State<VendorAdminPanel> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  File? _productImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _productImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_productNameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया सामान का नाम और कीमत भरें!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;

      if (_productImage != null) {
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('product_images')
            .upload(fileName, _productImage!);
        
        imageUrl = Supabase.instance.client.storage
            .from('product_images')
            .getPublicUrl(fileName);
      }

      await Supabase.instance.client.from('products').insert({
        'shop_id': widget.shopId,
        'product_name': _productNameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'product_image': imageUrl ?? '',
      });

      _productNameController.clear();
      _priceController.clear();
      setState(() {
        _productImage = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('सामान सफलतापूर्वक जुड़ गया!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('एरर: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('${widget.shopName} (Admin Panel)'),
        backgroundColor: Colors.teal[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "🛒 नया सामान (Product) जोड़ें",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 15),

            // फोटो पिकर बॉक्स
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal, width: 2),
                  ),
                  child: _productImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_productImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.tealAccent),
                            SizedBox(height: 8),
                            Text("फोटो जोड़ें", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _productNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'सामान का नाम (जैसे: अनार, सेब)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'कीमत ₹ (Price)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),

            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saveProduct,
                    child: const Text(
                      "सामान सेव करें ➕",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. SETTINGS SCREEN (Supabase URL और Key डालने के लिए)
// -----------------------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('supabase_url') ?? '';
      _keyController.text = prefs.getString('supabase_key') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_url', _urlController.text.trim());
    await prefs.setString('supabase_key', _keyController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('सेटिंग्स सेव हो गई हैं! ऐप रीस्टार्ट करें।'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Supabase Settings'),
        backgroundColor: Colors.teal[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Supabase URL',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _keyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Supabase Anon Key',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _saveSettings,
              child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
