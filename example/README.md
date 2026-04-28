# Awesome Node Auth - Flutter Integration Example

This example demonstrates a complete authentication flow using the Flutter `awesome_node_auth_flutter` client library with a Node.js backend powered by `awesome-node-auth`.

## 📱 Architecture

```
┌──────────────────┐         HTTP/REST          ┌──────────────────┐
│  Flutter App     │◄──────────────────────────►│  Node.js Server  │
│  (iOS/Android)   │      Bearer Tokens         │ (awesome-node-   │
│                  │         + Cookies          │   auth)          │
└──────────────────┘                            └──────────────────┘
   • Login Form                                    • Express App
   • Profile Screen                                • In-Memory Store
   • Token Refresh                                 • Auth Routes
```

## 🚀 Quick Start

### Prerequisites

- **Flutter 3.5+** ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Node.js 18+** ([Install Node.js](https://nodejs.org/))
- **Dart 3.5+** (comes with Flutter)

### 1. Start the Node.js Server

```bash
cd example/server

# Install dependencies
npm install

# Start the server (http://localhost:3000)
npm start
```

You should see:
```
╔═══════════════════════════════════════════════════════════╗
║   Awesome Node Auth - Flutter Example Server              ║
║   Running on http://localhost:3000                         ║
╠═══════════════════════════════════════════════════════════╣
║   Test Credentials:                                       ║
║   • Email: demo@example.com                               ║
║   • Password: demo123                                     ║
╚═══════════════════════════════════════════════════════════╝
```

### 2. Run the Flutter App

In a separate terminal:

```bash
cd example

# Get dependencies
flutter pub get

# Run on a device or emulator
flutter run

# Or for web:
flutter run -d chrome
```

## 🧪 Testing

### Using the Demo User

1. **Open the Flutter app** (login screen shows)
2. **Click "Login"**
3. **Enter demo credentials:**
   - Email: `demo@example.com`
   - Password: `demo123`
4. **You'll see the profile screen with your user info**
5. **Click "Logout"** to clear the session

### Creating a New User

1. **Fill email and password** in the login screen
2. **Click "Register"** instead of Login
3. **The app will automatically log you in** after registration
4. **You'll see your profile with the new email**

## 📡 API Endpoints

### Authentication Endpoints

```bash
# Register a new user
POST /auth/register
Content-Type: application/json
{
  "email": "user@example.com",
  "password": "secure-password"
}
# Response: { "id": "123", "email": "user@example.com", ... }

# Login with credentials
POST /auth/login
Content-Type: application/json
{
  "email": "demo@example.com",
  "password": "demo123"
}
# Response: JWT in cookies + refresh token

# Get current user (requires Bearer token)
GET /auth/me
Authorization: Bearer <access-token>
# Response: { "id": "123", "email": "demo@example.com", ... }

# Refresh expired access token
POST /auth/refresh
# Uses refresh token from cookies

# Logout (clears tokens)
POST /auth/logout
```

### Server Info Endpoints

```bash
# Health check
GET http://localhost:3000/health

# Server info + available endpoints
GET http://localhost:3000/info

# Protected route example
GET http://localhost:3000/profile
Authorization: Bearer <access-token>
```

## 🔒 Security Notes

### For Development Only

This example uses:
- **Hardcoded secrets** (change in production via `.env`)
- **In-memory storage** (data lost on server restart)
- **Disabled CSRF** (appropriate for mobile/Bearer token clients)
- **HTTP over localhost** (no HTTPS)

### For Production

1. **Use strong secrets:**
   ```bash
   export ACCESS_TOKEN_SECRET="your-strong-secret-key"
   export REFRESH_TOKEN_SECRET="your-strong-refresh-key"
   ```

2. **Use a real database** (MongoDB, PostgreSQL, MySQL):
   - See [awesome-node-auth examples](../../examples)

3. **Enable HTTPS** and set `secure: true` in cookies

4. **Implement proper CORS** for your domains

5. **Store credentials in `.env`** file (never commit to git)

## 📂 Project Structure

```
example/
├── lib/
│   └── main.dart              # Flutter app with login/profile/logout
├── pubspec.yaml               # Flutter dependencies
├── server/
│   ├── package.json           # Node.js dependencies
│   ├── server.js              # Express server + awesome-node-auth
│   └── README.md              # This file
└── android/
└── ios/
└── web/
```

## 🛠️ Customization

### Change Server URL

In [lib/main.dart](lib/main.dart), modify:

```dart
late final AuthClient authClient = AuthClient(
  baseUrl: 'https://your-api.example.com', // Change this
  onAuthStateChange: (state) {
    setState(() {});
  },
);
```

### Add More API Endpoints

In [server/server.js](server/server.js):

```javascript
// Example: GET user by ID
app.get('/api/users/:id', auth.middleware(), (req, res) => {
  const userId = req.params.id;
  const user = userStore.findById(userId);
  res.json(user);
});
```

### Store User Data

The in-memory store is initialized as:

```javascript
const userStore = new InMemoryUserStore();

// Pre-populate demo user
const testUser = await userStore.create({
  email: 'demo@example.com',
  password: await passwordService.hash('demo123'),
});
```

To use MongoDB or another database, implement the `IUserStore` interface from `awesome-node-auth`.

## 📚 Learn More

- **Flutter Client:** [awesome_node_auth_flutter on pub.dev](https://pub.dev/packages/awesome_node_auth_flutter)
- **Node.js Server:** [awesome-node-auth on npm](https://www.npmjs.com/package/awesome-node-auth)
- **Flutter Docs:** [flutter.dev](https://flutter.dev/docs)
- **awesome-node-auth Docs:** [github.com/nik2208/awesome-node-auth](https://github.com/nik2208/awesome-node-auth)

## 🐛 Troubleshooting

### "Connection refused" in Flutter app

- Make sure server is running: `npm start` in `example/server/`
- Check server is on `http://localhost:3000`
- On mobile device, use your computer's IP instead of `localhost`

### "Port 3000 already in use"

```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use a different port
PORT=3001 npm start
```

### Flutter app crashes on login

- Check browser console for CORS errors
- Verify server logs for auth errors
- Ensure credentials match exactly

### CORS errors

Server enables CORS for:
- `http://localhost:3000`
- `http://localhost:8080`
- `http://localhost:5000`

To add more origins, modify [server/server.js](server/server.js):

```javascript
app.use(cors({
  origin: ['http://localhost:3000', 'https://your-domain.com'],
  credentials: true,
}));
```

## 📄 License

This example is part of [awesome-node-auth-flutter](https://github.com/nik2208/awesome-node-auth-flutter) and is licensed under the MIT License.
