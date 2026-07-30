import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String url = prefs.getString('supabase_url') ?? '';
  String key = prefs.getString('supabase_key') ?? '';

  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, anonKey: key);
    } catch (_) {}
  }

  runApp(const ViziaMarketplaceApp());
}

class ViziaMarketplaceApp extends StatelessWidget {
  const ViziaMarketplaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizia Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primaryColor: const Color(0xFF0284C7),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF0284C7),
          secondary: const Color(0xFF10B981),
        ),
      ),
      home: const MarketplaceFeedScreen(),
    );
  }
}

class MarketplaceFeedScreen extends StatefulWidget {
  const MarketplaceFeedScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceFeedScreen> createState() => _MarketplaceFeedScreenState();
}

class _MarketplaceFeedScreenState extends State<MarketplaceFeedScreen> {
  int _currentIndex = 0;
  
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopImageController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  bool _isLocked = false;
  String? _selectedShopForNewItem;

  final List<Map<String, dynamic>> _cart = [];
  final double _platformCommissionPercent = 10.0; 
  double _totalPlatformEarnings = 0.0;

  List<Map<String, dynamic>> feedVendors = [
    {
      'id': 'v1',
      'shop_name': 'ज्ञानी जी फ्रूट वाले',
      'shop_image': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=500',
      'isOpen': true,
      'deliveryInfo': 'Express Delivery (15-20 mins) • ₹25 Fee',
      'items': [
        {'name': 'Kashmiri Juicy Apples', 'price': 140.0, 'available': true},
        {'name': 'Nagpur Premium Oranges', 'price': 90.0, 'available': true},
        {'name': 'Fresh Bananas (Dozen)', 'price': 60.0, 'available': false},
      ]
    },
    {
      'id': 'v2',
      'shop_name': 'राजू फ्रूट शॉप',
      'shop_image': 'https://images.unsplash.com/photo-1543083477-4f785aeafaa9?w=500',
      'isOpen': true,
      'deliveryInfo': 'Standard Delivery (30 mins) • Free Delivery above ₹200',
      'items': [
        {'name': 'Fresh Papaya (Slice/Whole)', 'price': 50.0, 'available': true},
        {'name': 'Sweet Pomegranates (Anar)', 'price': 160.0, 'available': true},
        {'name': 'Fresh Green Grapes', 'price': 100.0, 'available': true},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    if (feedVendors.isNotEmpty) {
      _selectedShopForNewItem = feedVendors[0]['shop_name'];
    }
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('supabase_url') ?? '';
      _keyController.text = prefs.getString('supabase_key') ?? '';
      _isLocked = prefs.getBool('supabase_locked') ?? false;
      _totalPlatformEarnings = prefs.getDouble('platform_earnings') ?? 0.0;
    });
  }

  void _saveAndLockConfig() async {
    if (_urlController.text.trim().isEmpty || _keyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Supabase credentials!')));
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_url', _urlController.text.trim());
    await prefs.setString('supabase_key', _keyController.text.trim());
    await prefs.setBool('supabase_locked', true);

    setState(() => _isLocked = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config Saved & Locked! 🔒')));
    setState(() => _currentIndex = 0);
  }

  void _unlockConfig() {
    TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Unlock Settings', style: TextStyle(color: Color(0xFF38BDF8))),
        content: TextField(controller: pinController, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Enter PIN (1234)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (pinController.text == '1234') {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('supabase_locked', false);
                setState(() => _isLocked = false);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unlocked! 🔓')));
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN!')));
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _verifyAdminAccess(int targetIndex) {
    if (targetIndex == 1) {
      TextEditingController pinController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Admin Passcode', style: TextStyle(color: Color(0xFF38BDF8))),
          content: TextField(controller: pinController, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Enter PIN (1234)')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (pinController.text == '1234') {
                  Navigator.pop(context);
                  setState(() => _currentIndex = targetIndex);
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong PIN!')));
                }
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _currentIndex = targetIndex);
    }
  }

  void _addNewShop() {
    if (_shopNameController.text.trim().isEmpty) return;
    setState(() {
      feedVendors.add({
        'id': 'v${feedVendors.length + 1}',
        'shop_name': _shopNameController.text.trim(),
        'shop_image': _shopImageController.text.trim().isNotEmpty 
            ? _shopImageController.text.trim() 
            : 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500',
        'isOpen': true,
        'deliveryInfo': 'Standard Delivery • ₹20 Fee',
        'items': []
      });
      _shopNameController.clear();
      _shopImageController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New Shop Profile Added Successfully! 🏪')));
  }

  void _addItemToShop() {
    if (_itemNameController.text.isEmpty || _priceController.text.isEmpty || _selectedShopForNewItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all details!')));
      return;
    }

    var vendor = feedVendors.firstWhere((v) => v['shop_name'] == _selectedShopForNewItem);
    setState(() {
      vendor['items'].add({
        'name': _itemNameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'available': true,
      });
      _itemNameController.clear();
      _priceController.clear();
      _currentIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item published to shop feed successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia Marketplace Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.shopping_cart), onPressed: _showCartDialog),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('${_cart.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          )
        ],
      ),
      body: _currentIndex == 0
          ? _buildInstagramFeedScreen()
          : _currentIndex == 1
              ? _buildAdminPanel()
              : _buildSettingsPanel(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.grey,
        onTap: _verifyAdminAccess,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Live Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildInstagramFeedScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: feedVendors.length,
      itemBuilder: (context, shopIndex) {
        final shop = feedVendors[shopIndex];
        List items = shop['items'];
        bool isOpen = shop['isOpen'];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isOpen ? const Color(0xFF334155) : Colors.red.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: Image.network(
                      shop['shop_image'],
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: const Color(0xFF0F172A),
                        child: const Center(child: Icon(Icons.store, size: 40, color: Colors.grey)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFF10B981) : Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(isOpen ? 'OPEN' : 'CLOSED', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF0F172A),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['shop_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(shop['deliveryInfo'], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOpen,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        setState(() {
                          shop['isOpen'] = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No fruits listed by this shop yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, itemIndex) {
                          final item = items[itemIndex];
                          bool isAvailable = item['available'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.between,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isAvailable ? Colors.white : Colors.grey,
                                          decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('₹${item['price']}/kg', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          item['available'] = !isAvailable;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isAvailable ? const Color(0xFF065F46) : const Color(0xFF7F1D1D),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isAvailable ? 'In Stock' : 'Out of Stock',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAvailable ? const Color(0xFF34D399) : const Color(0xFFFCA5A5)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: (isOpen && isAvailable) ? const Color(0xFF10B981) : Colors.grey.shade700,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: (isOpen && isAvailable)
                                          ? () {
                                              setState(() {
                                                _cart.add({
                                                  'shop': shop['shop_name'],
                                                  'name': item['name'],
                                                  'price': item['price'],
                                                });
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Added ${item['name']} from ${shop['shop_name']}!')),
                                              );
                                            }
                                          : null,
                                      child: const Text('Add', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCartDialog() {
    double totalAmount = _cart.fold(0, (sum, item) => sum + (item['price'] as double));
    double platformCut = totalAmount * (_platformCommissionPercent / 100);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Marketplace Cart 🛒', style: TextStyle(color: Color(0xFF38BDF8))),
        content: SizedBox(
          width: double.maxFinite,
          child: _cart.isEmpty
              ? const Text('Your cart is empty!', style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    return ListTile(
                      title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text('Shop: ${item['shop']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      trailing: Text('₹${item['price'].toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
        actions: [
          if (_cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.between, children: [
                    const Text('Total Items Price:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.between, children: [
                    const Text('Platform Cut (10%):', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                    Text('+₹${platformCut.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      onPressed: () async {
                        setState(() {
                          _totalPlatformEarnings += platformCut;
                          _cart.clear();
                        });
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setDouble('platform_earnings', _totalPlatformEarnings);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed with delivery partner! 🛵')));
                      },
                      child: const Text('Checkout Order'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 PLATFORM COMMISSION EARNINGS', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Text('₹${_totalPlatformEarnings.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Register New Shop Profile (Vendor)', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                TextField(controller: _shopNameController, decoration: const InputDecoration(hintText: 'Shop Name e.g. राजू फ्रूट शॉप', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextField(controller: _shopImageController, decoration: const InputDecoration(hintText: 'Shop Image URL (Optional photo link)', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  onPressed: _addNewShop,
                  child: const Text('Add Shop Profile to Feed'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Fruit Item to Shop', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedShopForNewItem,
                  dropdownColor: const Color(0xFF0F172A),
                  items: feedVendors.map((v) => DropdownMenuItem(value: v['shop_name'].toString(), child: Text(v['shop_name']))).toList(),
                  onChanged: (val) => setState(() => _selectedShopForNewItem = val),
                  decoration: const InputDecoration(filled: true, fillColor: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                TextField(controller: _itemNameController, decoration: const InputDecoration(hintText: 'Fruit Name (e.g. Papaya / Anar)', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Price per KG (₹)', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  onPressed: _addItemToShop,
                  child: const Text('Publish Fruit Live'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SUPABASE CONFIGURATION', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _urlController, enabled: !_isLocked, decoration: const InputDecoration(hintText: 'Supabase URL', filled: true, fillColor: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            TextField(controller: _keyController, enabled: !_isLocked, obscureText: true, decoration: const InputDecoration(hintText: 'Supabase Anon Key', filled: true, fillColor: Color(0xFF0F172A))),
            const SizedBox(height: 15),
            _isLocked
                ? ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: _unlockConfig, child: const Text('Unlock Settings'))
                : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)), onPressed: _saveAndLockConfig, child: const Text('Save & Lock')),
          ],
        ),
      ),
    );
  }
}
