const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bcrypt = require('bcryptjs');

const app = express();
app.use(cors());
app.use(express.json());

// MySQL Connection Config (Port 3307 set kiya hai jo aapka chal raha hai)
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'quickbite_db',
    port: 3307
});

db.connect((err) => {
    if (err) {
        console.error('Database connection failed: ' + err.stack);
        return;
    }
    console.log('Connected to MySQL Database on Port 3307! 🗄️');
});

// ==========================================
// 1. SIGNUP API (Register User)
// ==========================================
app.post('/api/auth/signup', async (req, res) => {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ message: "Please fill all fields, bhai!" });
    }

    try {
        // Check if user already exists
        db.query('SELECT email FROM users WHERE email = ?', [email], async (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            if (result.length > 0) {
                return res.status(400).json({ message: "Email already registered!" });
            }

            // Secure/Hash Password
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);

            // Insert into Database
            db.query('INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
            [name, email, hashedPassword], (err, insertResult) => {
                if (err) return res.status(500).json({ error: err.message });
                return res.status(201).json({ message: "User registered successfully! 🎉" });
            });
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ==========================================
// 2. LOGIN API (Authenticate User)
// ==========================================
app.post('/api/auth/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: "Email and password are required!" });
    }

    db.query('SELECT * FROM users WHERE email = ?', [email], async (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        if (result.length === 0) {
            return res.status(400).json({ message: "User not found! Incorrect email." });
        }

        const user = result[0];

        // Match Hashed Password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ message: "Invalid credentials! Check password again." });
        }

        // Return user data to frontend
        return res.status(200).json({
            message: "Login successful! Welcome back.",
            user: {
                id: user.id,
                name: user.name,
                email: user.email
            }
        });
    });
});

// ==========================================
// 3. GET RECIPES API (Fetch products from MySQL)
// ==========================================
app.get('/api/recipes', (req, res) => {
    db.query('SELECT * FROM recipes', (err, results) => {
        if (err) return res.status(500).json({ error: err.message });

        // Format data to match our Flutter model structure
        const formattedRecipes = results.map(recipe => ({
            id: recipe.id,
            title: recipe.title,
            time: recipe.time,
            desc: recipe.description,
            img: recipe.image_url,
            price: parseFloat(recipe.price),
            ingredients: recipe.ingredients ? recipe.ingredients.split(', ') : [],
            steps: recipe.steps ? recipe.steps.split('#') : []
        }));

        res.status(200).json(formattedRecipes);
    });
});

// Start Server
const PORT = 5000;
app.listen(PORT, () => {
    console.log(`Server running smoothly on port ${PORT} 🚀`);
});