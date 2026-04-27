import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const QuickBite());

class QuickBite extends StatelessWidget {
  const QuickBite({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- RECIPE MODEL ---
class Recipe {
  final String title, time, desc, img;
  final List<String> ingredients, steps;
  bool isFavorite; // Proposal feature

  Recipe({
    required this.title, required this.time, required this.desc, 
    required this.img, required this.ingredients, required this.steps,
    this.isFavorite = false,
  });
}

// --- 8 LOGICAL & QUICK STUDENT RECIPES ---
final List<Recipe> allRecipes = [
  Recipe(title: "Masala Maggi", time: "05 min", desc: "Classic spicy noodles for late nights.", img: "https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?q=80&w=400", ingredients: ["Maggi", "Tastemaker", "Onion"], steps: ["Boil water", "Add Maggi", "Cook 3 mins"]),
  Recipe(title: "Egg Mayo Sandwich", time: "08 min", desc: "Creamy filling sandwich.", img: "https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=400", ingredients: ["Bread", "Boiled Egg", "Mayo"], steps: ["Mash egg", "Mix mayo", "Spread on bread"]),
  Recipe(title: "Cheese Omelette", time: "06 min", desc: "Fluffy eggs with melted cheese.", img: "https://images.unsplash.com/photo-1496042399014-dc73c4f2bde1?q=80&w=400", ingredients: ["2 Eggs", "Cheese Slice", "Butter"], steps: ["Whisk eggs", "Fry on pan", "Add cheese & fold"]),
  Recipe(title: "Fruit Chaat", time: "10 min", desc: "Fresh seasonal fruits with spices.", img: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400", ingredients: ["Apple", "Banana", "Chaat Masala"], steps: ["Chop fruits", "Mix spices", "Serve chilled"]),
  Recipe(title: "Bread Pizza", time: "12 min", desc: "Quick pizza cravings on a pan.", img: "https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400", ingredients: ["Bread", "Ketchup", "Capsicum", "Cheese"], steps: ["Spread ketchup", "Add toppings", "Toast on pan until cheese melts"]),
  Recipe(title: "Peanut Butter Toast", time: "03 min", desc: "Quick energy snack.", img: "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?q=80&w=400", ingredients: ["Toast", "Peanut Butter", "Honey"], steps: ["Toast bread", "Spread PB", "Drizzle honey"]),
  Recipe(title: "Vegetable Pasta", time: "15 min", desc: "Pasta with minimal veggies.", img: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400", ingredients: ["Pasta", "Tomato Sauce", "Onion"], steps: ["Boil pasta", "Sauté onions in sauce", "Mix together"]),
  Recipe(title: "Cold Coffee", time: "04 min", desc: "Instant refreshing caffeine hit.", img: "https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?q=80&w=400", ingredients: ["Milk", "Instant Coffee", "Sugar", "Ice"], steps: ["Mix coffee in little water", "Add to blender with milk", "Blend until frothy"]),
];

// --- LOGIN SCREEN ---
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.bolt_rounded, size: 80, color: Colors.orange),
              const Text("QuickBite", style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 50),
              TextField(decoration: InputDecoration(hintText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 15),
              TextField(obscureText: true, decoration: InputDecoration(hintText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55), 
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen())),
                // Button Text Color changed to Black for visibility
                child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())), child: const Text("New here? Create Account"))
            ],
          ),
        ),
      ),
    );
  }
}

// --- SIGNUP SCREEN ---
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(decoration: InputDecoration(hintText: "Full Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 15),
            TextField(decoration: InputDecoration(hintText: "Email", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 15),
            TextField(obscureText: true, decoration: InputDecoration(hintText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Create Account")),
          ],
        ),
      ),
    );
  }
}

// --- HOME SCREEN (Favorite & Search Logic) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recipe> filteredRecipes = allRecipes;
  bool showOnlyFavs = false; // Filter state

  void filterSearch(String query) {
    setState(() {
      filteredRecipes = allRecipes.where((r) => r.title.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Recipe> displayList = showOnlyFavs ? filteredRecipes.where((r) => r.isFavorite).toList() : filteredRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quick Recipes"),
        actions: [
          // Favorite Filter Button
          IconButton(
            icon: Icon(showOnlyFavs ? Icons.favorite : Icons.favorite_border, color: Colors.red),
            onPressed: () => setState(() => showOnlyFavs = !showOnlyFavs),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen()))),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (value) => filterSearch(value),
              decoration: InputDecoration(hintText: "Search noodle, bread...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
          ),
          if (showOnlyFavs) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text("Showing Favorites", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          Expanded(
            child: displayList.isEmpty 
              ? const Center(child: Text("No recipes found!"))
              : ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final recipe = displayList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: ListTile(
                        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(recipe.img, width: 60, height: 60, fit: BoxFit.cover)),
                        title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(recipe.time),
                        trailing: IconButton(
                          icon: Icon(recipe.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                          onPressed: () => setState(() => recipe.isFavorite = !recipe.isFavorite),
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
    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(recipe.img, width: double.infinity, height: 250, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(recipe.desc, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const Divider(height: 30),
                  const Text("Ingredients", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ...recipe.ingredients.map((i) => Padding(padding: const EdgeInsets.only(top: 5), child: Text("• $i"))),
                  const SizedBox(height: 25),
                  const Text("Steps", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ...recipe.steps.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(top: 8), child: Text("${e.key + 1}. ${e.value}"))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}