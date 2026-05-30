import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: const QuickBite(),
    ),
  );
}

class QuickBite extends StatelessWidget {
  const QuickBite({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- RECIPE MODEL ---
class Recipe {
  String id, title, time, desc, img;
  List<String> ingredients, steps;
  double price;
  bool isFavorite;

  Recipe({
    required this.id, required this.title, required this.time, required this.desc,
    required this.img, required this.ingredients, required this.steps,
    required this.price, this.isFavorite = false,
  });
}

// --- ORDER MODEL ---
class OrderItem {
  final String orderId;
  final List<Recipe> items;
  final double totalPrice;
  final DateTime orderTime;
  String status;
  final String deliveryEta;

  OrderItem({
    required this.orderId,
    required this.items,
    required this.totalPrice,
    required this.orderTime,
    this.status = "Pending",
    required this.deliveryEta,
  });
}

// --- PROVIDER (STATE MANAGEMENT WITH API INTEGRATION) ---
class AppProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  final List<Recipe> _cart = [];
  final List<OrderItem> _orders = [];
  bool _isLoading = false;

  List<Recipe> get recipes => _recipes;
  List<Recipe> get cart => _cart;
  List<OrderItem> get orders => _orders;
  bool get isLoading => _isLoading;

  String currentUserEmail = "";
  String currentUserName = "Guest User";
  int? currentUserId;

  // Localhost IP for Chrome/Web Architecture
  final String baseUrl = "http://localhost:5000/api";

  // ==========================================
  // FETCH RECIPES FROM MYSQL DATABASE API
  // ==========================================
  Future<void> fetchRecipes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse("$baseUrl/recipes"));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _recipes = data.map((jsonItem) => Recipe(
          id: jsonItem['id'].toString(),
          title: jsonItem['title'],
          time: jsonItem['time'],
          desc: jsonItem['desc'],
          img: jsonItem['img'],
          price: double.parse(jsonItem['price'].toString()),
          ingredients: List<String>.from(jsonItem['ingredients']),
          steps: List<String>.from(jsonItem['steps']),
        )).toList();
      }
    } catch (e) {
      print("Error fetching recipes: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // ==========================================
  // SIGNUP API CONNECTIVITY
  // ==========================================
  Future<Map<String, dynamic>> signupUser(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"name": name, "email": email, "password": password}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {"message": "Server connection failed!"};
    }
  }

  // ==========================================
  // LOGIN API CONNECTIVITY
  // ==========================================
  Future<bool> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        currentUserId = data['user']['id'];
        currentUserName = data['user']['name'];
        currentUserEmail = data['user']['email'];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void toggleFavorite(Recipe recipe) {
    recipe.isFavorite = !recipe.isFavorite;
    notifyListeners();
  }

  void addToCart(Recipe recipe) {
    _cart.add(recipe);
    notifyListeners();
  }

  void removeFromCart(Recipe recipe) {
    _cart.remove(recipe);
    notifyListeners();
  }

  double get totalCartPrice => _cart.fold(0, (sum, item) => sum + item.price);

  void placeOrder() {
    if (_cart.isEmpty) return;
    final newOrder = OrderItem(
      orderId: "#QB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
      items: List.from(_cart),
      totalPrice: totalCartPrice,
      orderTime: DateTime.now(),
      status: "Processing",
      deliveryEta: "30-45 mins",
    );
    _orders.insert(0, newOrder);
    _cart.clear();
    notifyListeners();
  }

  void cancelOrder(String orderId) {
    _orders.removeWhere((o) => o.orderId == orderId);
    notifyListeners();
  }
}

// --- REUSABLE HELPER WIDGET FOR SAFE IMAGE LOADING ---
class SafeImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const SafeImage({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = double.infinity,
    this.fit = BoxFit.cover
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.orange.shade50,
          child: const Icon(Icons.fastfood, color: Colors.orange, size: 30),
        );
      },
    );
  }
}

// --- AUTHENTICATION SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignUp = false;
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool localLoading = false;

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded, size: 80, color: Colors.orange),
              const Text("QuickBite Pro", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.orange)),
              Text(isSignUp ? "Create a MySQL account" : "Welcome back, please login", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              if (isSignUp) ...[
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(hintText: "Full Name", prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 15),
              ],

              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(hintText: "Email Address", prefixIcon: const Icon(Icons.mail_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(hintText: "Password", prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 30),

              localLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.orange),
                onPressed: () async {
                  setState(() => localLoading = true);
                  if (isSignUp) {
                    final res = await appProvider.signupUser(nameCtrl.text, emailCtrl.text, passCtrl.text);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                    if (res['message'].contains('successfully')) {
                      setState(() => isSignUp = false);
                    }
                  } else {
                    bool success = await appProvider.loginUser(emailCtrl.text, passCtrl.text);
                    if (success) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid credentials or Email not found!")));
                    }
                  }
                  setState(() => localLoading = false);
                },
                child: Text(isSignUp ? "Register Database" : "Secure Login", style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  setState(() {
                    isSignUp = !isSignUp;
                  });
                },
                child: Text(
                  isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = "";
  bool showOnlyFavs = false;

  @override
  void initState() {
    super.initState();
    // Fetch products automatically from MySQL server on start
    Future.delayed(Duration.zero, () {
      Provider.of<AppProvider>(context, listen: false).fetchRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    List<Recipe> displayList = appProvider.recipes.where((r) {
      final matchesSearch = r.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          r.ingredients.any((i) => i.toLowerCase().contains(searchQuery.toLowerCase()));
      return showOnlyFavs ? (matchesSearch && r.isFavorite) : matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("QuickBite Market (Live)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_shipping_outlined, color: Colors.blue),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const OrdersTrackerScreen())),
          ),
          IconButton(
            icon: Icon(showOnlyFavs ? Icons.favorite : Icons.favorite_border, color: Colors.red),
            onPressed: () => setState(() => showOnlyFavs = !showOnlyFavs),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen())),
              ),
              if (appProvider.cart.isNotEmpty)
                Positioned(
                  right: 5, top: 5,
                  child: CircleAvatar(
                    radius: 8, backgroundColor: Colors.red,
                    child: Text("${appProvider.cart.length}", style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                )
            ],
          ),
        ],
      ),

      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 45, color: Colors.orange),
              ),
              accountName: Text(appProvider.currentUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(appProvider.currentUserEmail),
              decoration: const BoxDecoration(color: Colors.orange),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined, color: Colors.orange),
              title: const Text("Market Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text("Logout Session", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      body: appProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                  hintText: "Search live recipes...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
              ),
            ),
          ),
          Expanded(
            child: displayList.isEmpty
                ? const Center(child: Text("No live products found in MySQL database!"))
                : ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final recipe = displayList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SafeImage(imageUrl: recipe.img, width: 60, height: 60)
                    ),
                    title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${recipe.time} • Box: Rs. ${recipe.price}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                          onPressed: () => appProvider.toggleFavorite(recipe),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
                          onPressed: () {
                            appProvider.addToCart(recipe);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${recipe.title} box added!"), duration: const Duration(seconds: 1))
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailScreen(recipe: recipe))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- DETAIL SCREEN ---
class DetailScreen extends StatelessWidget {
  final Recipe recipe;
  const DetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeImage(imageUrl: recipe.img, width: double.infinity, height: 250),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(recipe.title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                      Chip(
                        avatar: const Icon(Icons.timer, size: 16, color: Colors.orange),
                        label: Text(recipe.time, style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.orange.withOpacity(0.15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(recipe.desc, style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  const Divider(height: 35),
                  Card(
                    color: Colors.orange.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Missing ingredients?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              Text("Rs. ${recipe.price}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: Colors.orange),
                            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                            label: const Text("Add Fresh Ingredients Box to Cart", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              provider.addToCart(recipe);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("${recipe.title} box added!"), duration: const Duration(seconds: 1))
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 35),
                  const Text("Ingredients Included", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...recipe.ingredients.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 16, color: Colors.orange),
                        const SizedBox(width: 10),
                        Text(i, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 25),
                  const Text("Cooking Instructions", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...recipe.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 11, backgroundColor: Colors.orange,
                          child: Text("${e.key + 1}", style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value, style: const TextStyle(fontSize: 15, height: 1.4))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CART SCREEN ---
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Review Items")),
      body: provider.cart.isEmpty
          ? const Center(child: Text("Cart is empty! Add ingredients to buy."))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: provider.cart.length,
              itemBuilder: (context, index) {
                final item = provider.cart[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SafeImage(imageUrl: item.img, width: 50, height: 50)
                    ),
                    title: Text("${item.title} Ingredients"),
                    subtitle: Text("Rs. ${item.price}"),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        onPressed: () => provider.removeFromCart(item)
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Amount:", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    Text("Rs. ${provider.totalCartPrice}", style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.green),
                  onPressed: () {
                    provider.placeOrder();
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("Order Placed Successfully! 🎉"),
                        content: const Text("Your customized bundle has been locked."),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(c);
                                Navigator.pop(context);
                                Navigator.push(context, MaterialPageRoute(builder: (c) => const OrdersTrackerScreen()));
                              },
                              child: const Text("Track Order")
                          )
                        ],
                      ),
                    );
                  },
                  child: const Text("Confirm Order (Checkout)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- ORDER TRACKER SCREEN ---
class OrdersTrackerScreen extends StatelessWidget {
  const OrdersTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("My Orders & Tracking")),
      body: provider.orders.isEmpty
          ? const Center(child: Text("You haven't placed any orders yet!"))
          : ListView.builder(
        itemCount: provider.orders.length,
        itemBuilder: (context, index) {
          final order = provider.orders[index];
          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Order ID: ${order.orderId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Rs. ${order.totalPrice}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 20),
                  Text("Items: ${order.items.map((i) => i.title).join(', ')}", style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text("Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Chip(
                        label: Text(order.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        backgroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.orange),
                      const SizedBox(width: 5),
                      Text("Estimated Delivery: ${order.deliveryEta}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 25),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        backgroundColor: Colors.red.shade50,
                        side: BorderSide(color: Colors.red.shade200)
                    ),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text("Cancel This Order", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("Cancel Order?"),
                          content: const Text("Are you sure you want to cancel this delivery?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c), child: const Text("No")),
                            TextButton(
                              onPressed: () {
                                provider.cancelOrder(order.orderId);
                                Navigator.pop(c);
                              },
                              child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}