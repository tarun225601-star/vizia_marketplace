import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  
  // यूज़र प्रोफाइल कंट्रोलर्स (ग्राहक के लिए)
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final TextEditingController _userAddressController = TextEditingController();
  bool _isUserRegistered = false;

  // शॉप रजिस्ट्रेशन कंट्रोलर्स
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _shopPhoneController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _shopUpiController = TextEditingController();
  
  // आइटम जोड़ने के लिए
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  // सेटिंग्स
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  bool _isLocked = false;
  String? _selectedShopForNewItem;
  
  String? _pickedShopImagePath;
  String? _pickedOwnerImagePath;

  final List<Map<String, dynamic>> _cart = [];
  final List<Map<String, dynamic>> _incomingOrders = []; // दुकानदार और डिलीवरी के लिए लाइव आर्डर लिस्ट

  List<Map<String, dynamic>> feedVendors = [
    {
      'id': 'v1',
      'shop_name': 'अजरोदा फ्रूट & वेजिटेबल',
      'owner_name': 'रोहित शर्मा',
      'shop_phone': '9876543210',
      'shop_address': 'Sector 16 / Ajronda, Faridabad',
      'shop_upi': 'rohit@paytm',
      'shop_image': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=500',
      'owner_image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
      'isLocalShopPhoto': false,
      'isLocalOwnerPhoto': false,
      'isOpen': true,
      'items': [
        {'name': 'Kashmiri Juicy Apples (1kg)', 'price': 140.0, 'available': true},
        {'name': 'Nagpur Premium Oranges (1kg)', 'price': 90.0, 'available': true},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndUser();
    if (feedVendors.isNotEmpty) {
      _selectedShopForNewItem = feedVendors[0]['shop_name'];
    }
  }

  void _loadSettingsAndUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('supabase_url') ?? '';
      _keyController.text = prefs.getString('supabase_key') ?? '';
      _isLocked = prefs.getBool('supabase_locked') ?? false;

      // यूज़र डेटा लोड करें
      _userNameController.text = prefs.getString('user_name') ?? '';
      _userPhoneController.text = prefs.getString('user_phone') ?? '';
      _userAddressController.text = prefs.getString('user_address') ?? '';
      _isUserRegistered = prefs.getBool('is_user_registered') ?? false;
    });
  }

  void _saveUserProfile() async {
    if (_userNameController.text.trim().isEmpty || 
        _userPhoneController.text.trim().isEmpty || 
        _userAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया नाम, मोबाइल नंबर और पूरा पता भरें!')));
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userNameController.text.trim());
    await prefs.setString('user_phone', _userPhoneController.text.trim());
    await prefs.setString('user_address', _userAddressController.text.trim());
    await prefs.setBool('is_user_registered', true);

    setState(() => _isUserRegistered = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('प्रोफाइल सेव हो गई! अब आर्डर कर सकते हैं। 🎉')));
  }

  void _editUserProfile() {
    setState(() => _isUserRegistered = false);
  }

  void _saveAndLockConfig() async {
    if (_urlController.text.trim().isEmpty || _keyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supabase credentials दर्ज करें!')));
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
        content: TextField(controller: pinController, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'PIN डालें (1234)')),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('गलत पिन!')));
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
          title: const Text('Shop & Delivery Passcode', style: TextStyle(color: Color(0xFF38BDF8))),
          content: TextField(controller: pinController, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'PIN डालें (1234)')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (pinController.text == '1234') {
                  Navigator.pop(context);
                  setState(() => _currentIndex = targetIndex);
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('गलत पिन!')));
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

  Future<void> _pickShopImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedShopImagePath = result.files.single.path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('दुकान का फोटो चुन लिया गया है! 📸')));
    }
  }

  Future<void> _pickOwnerImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _pickedOwnerImagePath = result.files.single.path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ओनर का फोटो चुन लिया गया है! 👤')));
    }
  }

  void _registerNewCompleteShop() {
    if (_shopNameController.text.trim().isEmpty || 
        _ownerNameController.text.trim().isEmpty || 
        _shopPhoneController.text.trim().isEmpty || 
        _shopAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया सभी जरूरी जानकारी भरें!')));
      return;
    }

    setState(() {
      feedVendors.add({
        'id': 'v${feedVendors.length + 1}',
        'shop_name': _shopNameController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'shop_phone': _shopPhoneController.text.trim(),
        'shop_address': _shopAddressController.text.trim(),
        'shop_upi': _shopUpiController.text.trim().isNotEmpty ? _shopUpiController.text.trim() : 'vendor@upi',
        'shop_image': _pickedShopImagePath ?? 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500',
        'owner_image': _pickedOwnerImagePath ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500',
        'isLocalShopPhoto': _pickedShopImagePath != null,
        'isLocalOwnerPhoto': _pickedOwnerImagePath != null,
        'isOpen': true,
        'items': []
      });

      _shopNameController.clear();
      _ownerNameController.clear();
      _shopPhoneController.clear();
      _shopAddressController.clear();
      _shopUpiController.clear();
      _pickedShopImagePath = null;
      _pickedOwnerImagePath = null;
      _currentIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('दुकान सफलतापूर्वक रजिस्टर हो गई! 🎉')));
  }

  void _addItemToShop() {
    if (_itemNameController.text.isEmpty || _priceController.text.isEmpty || _selectedShopForNewItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('आइटम की पूरी जानकारी भरें!')));
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
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('आइटम फीड में जोड़ दिया गया है!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizia Marketplace Faridabad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          if (_isUserRegistered)
            IconButton(
              icon: const Icon(Icons.person_pin, color: Color(0xFF38BDF8)),
              tooltip: 'Edit Profile',
              onPressed: _editUserProfile,
            ),
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
      body: !_isUserRegistered
          ? _buildUserRegistrationScreen()
          : _currentIndex == 0
              ? _buildFeedScreen()
              : _currentIndex == 1
                  ? _buildShopAndDeliveryPanel()
                  : _buildSettingsPanel(),
      bottomNavigationBar: _isUserRegistered
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              backgroundColor: const Color(0xFF1E293B),
              selectedItemColor: const Color(0xFF38BDF8),
              unselectedItemColor: Colors.grey,
              onTap: _verifyAdminAccess,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Live Feed'),
                BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Shop & Delivery Alerts'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            )
          : null,
    );
  }

  // यूज़र रजिस्ट्रेशन स्क्रीन (जब ऐप पहली बार खुले या प्रोफाइल एडिट करनी हो)
  Widget _buildUserRegistrationScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👋 स्वागत है Vizia Marketplace में!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              const Text('आर्डर करने के लिए कृपया अपनी जानकारी दर्ज करें:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: _userNameController,
                decoration: const InputDecoration(labelText: 'आपका नाम (Your Name)', filled: true, fillColor: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'मोबाइल नंबर (Mobile Number)', filled: true, fillColor: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _userAddressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'डिलीवरी का पूरा पता (Sector/House No, Faridabad)', filled: true, fillColor: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: _saveUserProfile,
                  child: const Text('सेव करें और आगे बढ़ें 🚀', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: feedVendors.length,
      itemBuilder: (context, shopIndex) {
        final shop = feedVendors[shopIndex];
        List items = shop['items'];
        bool isOpen = shop['isOpen'];
        
        bool isLocalShop = shop['isLocalShopPhoto'] ?? false;
        String shopImg = shop['shop_image'];

        bool isLocalOwner = shop['isLocalOwnerPhoto'] ?? false;
        String ownerImg = shop['owner_image'];

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
                    child: isLocalShop
                        ? Image.file(File(shopImg), height: 150, width: double.infinity, fit: BoxFit.cover)
                        : Image.network(shopImg, height: 150, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 150, color: const Color(0xFF0F172A),
                              child: const Center(child: Icon(Icons.store, size: 40, color: Colors.grey)),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: isOpen ? const Color(0xFF10B981) : Colors.red, borderRadius: BorderRadius.circular(6)),
                      child: Text(isOpen ? 'OPEN' : 'CLOSED', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF0F172A),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: isLocalOwner 
                          ? FileImage(File(ownerImg)) as ImageProvider 
                          : NetworkImage(ownerImg),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['shop_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('Owner: ${shop['owner_name']} • 📞 ${shop['shop_phone']}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                          const SizedBox(height: 2),
                          Text('📍 ${shop['shop_address']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          Text('💳 UPI: ${shop['shop_upi']}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 10)),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOpen,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setState(() => shop['isOpen'] = val),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('इस दुकान पर अभी कोई सामान लिस्ट नहीं है।', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13,
                                          color: isAvailable ? Colors.white : Colors.grey,
                                          decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('₹${item['price']}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                                    ],
                                  ),
                                ),
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
                                              'shop_phone': shop['shop_phone'],
                                              'shop_address': shop['shop_address'],
                                              'shop_upi': shop['shop_upi'],
                                              'name': item['name'],
                                              'price': item['price'],
                                            });
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${item['name']} कार्ट में जुड़ गया!')),
                                          );
                                        }
                                      : null,
                                  child: const Text('Add', style: TextStyle(fontSize: 11)),
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

  // चेकआउट और आर्डर कन्फर्मेशन (दुकानदार और डिलीवरी के लिए अलर्ट ट्रिगर)
  void _showCartDialog() {
    double totalAmount = _cart.fold(0, (sum, item) => sum + (item['price'] as double));
    String targetShopUpi = _cart.isNotEmpty ? _cart.first['shop_upi'] : 'vendor@upi';
    String targetShopName = _cart.isNotEmpty ? _cart.first['shop'] : 'Shop';
    String targetShopPhone = _cart.isNotEmpty ? _cart.first['shop_phone'] : '9876543210';
    String targetShopAddress = _cart.isNotEmpty ? _cart.first['shop_address'] : 'Shop Address';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('ऑर्डर चेकआउट 🛒', style: TextStyle(color: Color(0xFF38BDF8))),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('चुने हुए सामान:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 5),
                ..._cart.map((item) => ListTile(
                      dense: true,
                      title: Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                      subtitle: Text('दुकान: ${item['shop']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      trailing: Text('₹${item['price'].toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF38BDF8))),
                    )),
                const Divider(color: Colors.grey),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('कुल राशि:', style: TextStyle(color: Colors.grey)),
                  Text('₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                  child: Text('दुकानदार का UPI ID (डायरेक्ट पेमेंट):\n$targetShopUpi', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 15),
                const Text('डिलीवरी की जानकारी (आपकी प्रोफाइल से):', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('नाम: ${_userNameController.text}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text('मोबाइल: ${_userPhoneController.text}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text('पता: ${_userAddressController.text}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_cart.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                setState(() {
                  _incomingOrders.add({
                    'customer_name': _userNameController.text,
                    'customer_phone': _userPhoneController.text,
                    'delivery_address': _userAddressController.text,
                    'items': List.from(_cart),
                    'total': totalAmount,
                    'shop_name': targetShopName,
                    'shop_phone': targetShopPhone,
                    'shop_address': targetShopAddress,
                    'time': TimeOfDay.now().format(context),
                  });
                  _cart.clear();
                });

                Navigator.pop(context);
                
                // दुकानदार और डिलीवरी बॉय के लिए पॉप-अप नोटिफिकेशन अलर्ट
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text('🔔 आर्डर कन्फर्म हो गया!', style: TextStyle(color: Color(0xFF10B981))),
                    content: Text('दुकानदार ($targetShopName) और डिलीवरी बॉय के पास नोटिफिकेशन भेज दिया गया है!\n\n• दुकान का फोन: $targetShopPhone\n• माल जल्दी ही पैक होकर आपके पते पर पहुँचेगा।'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('ठीक है'),
                      )
                    ],
                  ),
                );
              },
              child: const Text('आर्डर कन्फर्म करें 🛒'),
            ),
        ],
      ),
    );
  }

  // दुकानदार और डिलीवरी बॉय के लिए लाइव आर्डर डैशबोर्ड और नोटिफिकेशन पैनल
  Widget _buildShopAndDeliveryPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔔 लाइव आर्डर अलर्ट्स (दुकानदार और डिलीवरी बॉय के लिए)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.6), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🔔 लाइव आर्डर & पिकअप अलर्ट', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: Text('${_incomingOrders.length} नए आर्डर', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _incomingOrders.isEmpty
                    ? const Text('अभी कोई नया आर्डर नहीं है। ग्राहक के आर्डर का इंतज़ार है...', style: TextStyle(color: Colors.grey, fontSize: 12))
                    : ListView.builder(
                        shrinkId: true,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _incomingOrders.length,
                        itemBuilder: (context, index) {
                          final order = _incomingOrders[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Text('दुकान: ${order['shop_name']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 12)),
                                   Text('₹${order['total'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                 ],
                                ),
                                const Divider(color: Colors.grey),
                                Text('📦 यह सामान पैक करें (${order['customer_name']}):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
                                ...List.from(order['items']).map((it) => Text('• ${it['name']} (₹${it['price']})', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                const SizedBox(height: 6),
                                Text('📞 ग्राहक फोन: ${order['customer_phone']}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11)),
                                Text('📍 डिलीवरी पता: ${order['delivery_address']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), minimumSize: const Size(0, 30)),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('डिलीवरी बॉय को पिकअप का नोटिफिकेशन भेज दिया गया है! 🛵'))
                                        );
                                      },
                                      icon: const Icon(Icons.delivery_dining, size: 14),
                                      label: const Text('डिलीवरी बॉय को भेजें', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // नई दुकान रजिस्टर करने का फॉर्म
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🏪 नई दुकान रजिस्टर करें (Add Shop)', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                TextField(controller: _shopNameController, decoration: const InputDecoration(hintText: 'दुकान का नाम (उदा. गुप्ता किराना)', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextField(controller: _ownerNameController, decoration: const InputDecoration(hintText: 'ओनर का नाम', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextField(controller: _shopPhoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'दुकानदार का मोबाइल नंबर', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextField(controller: _shopAddressController, decoration: const InputDecoration(hintText: 'दुकान का पूरा पता / सेक्टर', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextField(controller: _shopUpiController, decoration: const InputDecoration(hintText: 'दुकान का UPI ID (उदा. gupta@paytm)', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                        onPressed: _pickShopImage,
                        icon: const Icon(Icons.storefront, size: 16),
                        label: Text(_pickedShopImagePath != null ? 'फोटो ✅' : 'दुकान फोटो'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
                        onPressed: _pickOwnerImage,
                        icon: const Icon(Icons.person, size: 16),
                        label: Text(_pickedOwnerImagePath != null ? 'फोटो ✅' : 'ओनर फोटो'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    onPressed: _registerNewCompleteShop,
                    child: const Text('दुकान लाइव पब्लिश करें'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // दुकान में आइटम जोड़ने का फॉर्म
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📦 दुकान में सामान जोड़ें (Add Product)', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedShopForNewItem,
                  dropdownColor: const Color(0xFF0F172A),
                  items: feedVendors.map((v) => DropdownMenuItem(value: v['shop_name'].toString(), child: Text(v['shop_name']))).toList(),
                  onChanged: (val) => setState(() => _selectedShopForNewItem = val),
                  decoration: const InputDecoration(filled: true, fillColor: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                TextField(controller: _itemNameController, decoration: const InputDecoration(hintText: 'सामान का नाम', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'कीमत (₹)', filled: true, fillColor: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  onPressed: _addItemToShop,
                  child: const Text('सामान लाइव करें'),
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
