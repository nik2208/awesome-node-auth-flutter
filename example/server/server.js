import express from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import { AuthConfigurator, PasswordService } from 'awesome-node-auth';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(cookieParser());
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:5000'],
  credentials: true,
}));

// ============================================================================
// In-Memory User Store Implementation
// ============================================================================
class InMemoryUserStore {
  constructor() {
    this.users = new Map();
    this.nextId = 1;
  }

  async findByEmail(email) {
    for (const user of this.users.values()) {
      if (user.email === email) {
        return user;
      }
    }
    return null;
  }

  async findById(id) {
    return this.users.get(id) || null;
  }

  async create(data) {
    const id = String(this.nextId++);
    const user = {
      id,
      email: data.email,
      password: data.password,
      emailVerified: false,
      createdAt: new Date(),
      ...data,
    };
    this.users.set(id, user);
    return user;
  }

  async updateRefreshToken(userId, token, expiry) {
    const user = this.users.get(userId);
    if (user) {
      user.refreshToken = token;
      user.refreshTokenExpiry = expiry;
    }
  }

  async updatePassword(userId, hashedPassword) {
    const user = this.users.get(userId);
    if (user) {
      user.password = hashedPassword;
    }
  }

  async updateResetToken(userId, token, expiry) {
    const user = this.users.get(userId);
    if (user) {
      user.resetToken = token;
      user.resetTokenExpiry = expiry;
    }
  }

  async updateEmailVerificationToken(userId, token, expiry) {
    const user = this.users.get(userId);
    if (user) {
      user.emailVerificationToken = token;
      user.emailVerificationTokenExpiry = expiry;
    }
  }

  async updateEmailVerified(userId, verified) {
    const user = this.users.get(userId);
    if (user) {
      user.emailVerified = verified;
    }
  }

  async updateTotpSecret(userId, secret) {
    const user = this.users.get(userId);
    if (user) {
      user.totpSecret = secret;
    }
  }

  async updateMagicLinkToken(userId, token, expiry) {
    const user = this.users.get(userId);
    if (user) {
      user.magicLinkToken = token;
      user.magicLinkTokenExpiry = expiry;
    }
  }

  async updateSmsCode(userId, code, expiry) {
    const user = this.users.get(userId);
    if (user) {
      user.smsCode = code;
      user.smsCodeExpiry = expiry;
    }
  }
}

// ============================================================================
// Setup Authentication
// ============================================================================
const passwordService = new PasswordService();
const userStore = new InMemoryUserStore();

// Create test user for demo
const testUser = await userStore.create({
  email: 'demo@example.com',
  password: await passwordService.hash('demo123'),
});
console.log('✓ Demo user created: demo@example.com / demo123');

// Auth configuration - optimized for Flutter clients
const authConfig = {
  accessTokenSecret: process.env.ACCESS_TOKEN_SECRET || 'your-access-secret-key-change-in-production',
  refreshTokenSecret: process.env.REFRESH_TOKEN_SECRET || 'your-refresh-secret-key-change-in-production',
  accessTokenExpiresIn: '15m',
  refreshTokenExpiresIn: '7d',
  cookieOptions: {
    secure: process.env.NODE_ENV === 'production', // HTTPS only in production
    httpOnly: true,
    sameSite: 'lax',
  },
  // Disable CSRF for mobile/Flutter clients using Bearer tokens
  csrf: { enabled: false },
};

const auth = new AuthConfigurator(authConfig, userStore);

// Mount auth router with registration handler
app.use('/auth', auth.router({
  onRegister: async (data) => {
    const { email, password } = data;
    
    // Check if user already exists
    const existing = await userStore.findByEmail(email);
    if (existing) {
      throw new Error('User already exists');
    }
    
    const hashedPassword = await passwordService.hash(password);
    return userStore.create({
      email,
      password: hashedPassword,
    });
  },
}));

// ============================================================================
// Health Check & Info Endpoints
// ============================================================================
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    users: userStore.users.size,
  });
});

app.get('/info', (req, res) => {
  res.json({
    name: 'Awesome Node Auth - Flutter Example Server',
    version: '1.0.0',
    endpoints: {
      auth: '/auth/*',
      health: '/health',
      info: '/info',
    },
    demoUser: {
      email: 'demo@example.com',
      password: 'demo123',
    },
  });
});

// ============================================================================
// Protected Route Example
// ============================================================================
app.get('/profile', auth.middleware(), (req, res) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Not authenticated' });
  }

  const { password, refreshToken, ...userPublic } = req.user;
  res.json({
    message: 'Protected route accessed successfully',
    user: userPublic,
  });
});

// ============================================================================
// Error Handling
// ============================================================================
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'production' ? undefined : err.message,
  });
});

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ============================================================================
// Start Server
// ============================================================================
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║   Awesome Node Auth - Flutter Example Server              ║
║   Running on http://localhost:${PORT}                       ║
╠═══════════════════════════════════════════════════════════╣
║   Auth Endpoints:                                         ║
║   • POST   /auth/register                                 ║
║   • POST   /auth/login                                    ║
║   • POST   /auth/logout                                   ║
║   • POST   /auth/refresh                                  ║
║   • GET    /auth/me                                       ║
║                                                           ║
║   Test Credentials:                                       ║
║   • Email: demo@example.com                               ║
║   • Password: demo123                                     ║
║                                                           ║
║   Info: http://localhost:${PORT}/info                       ║
║   Health: http://localhost:${PORT}/health                   ║
╚═══════════════════════════════════════════════════════════╝
  `);
});
