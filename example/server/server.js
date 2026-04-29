import express from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import { AuthConfigurator, PasswordService } from 'awesome-node-auth';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(cookieParser());
// Allow all localhost origins (for development)
app.use(cors({
  origin: /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/,
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
    // Token rotation is handled automatically by awesome-node-auth.
    // Your IUserStore implementation (this class implements that interface)
    // only needs to persist the current refresh token via updateRefreshToken —
    // the library handles old-token invalidation automatically.
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

  async updateLastLogin(userId) {
    const user = this.users.get(userId);
    if (user) {
      user.lastLogin = new Date();
    }
  }

  // Optional methods
  async findByResetToken(token) {
    for (const user of this.users.values()) {
      if (user.resetToken === token) {
        return user;
      }
    }
    return null;
  }

  async findByMagicLinkToken(token) {
    for (const user of this.users.values()) {
      if (user.magicLinkToken === token) {
        return user;
      }
    }
    return null;
  }

  async findByEmailVerificationToken(token) {
    for (const user of this.users.values()) {
      if (user.emailVerificationToken === token) {
        return user;
      }
    }
    return null;
  }

  async updateEmailChangeToken(userId, pendingEmail, token, expiry) {
    const user = this.users.get(userId);
    if (user) {
      user.emailChangeToken = token;
      user.emailChangeTokenExpiry = expiry;
      user.pendingEmail = pendingEmail;
    }
  }

  async updateEmail(userId, newEmail) {
    const user = this.users.get(userId);
    if (user) {
      user.email = newEmail;
      user.emailChangeToken = null;
      user.emailChangeTokenExpiry = null;
      user.pendingEmail = null;
    }
  }

  async findByEmailChangeToken(token) {
    for (const user of this.users.values()) {
      if (user.emailChangeToken === token) {
        return user;
      }
    }
    return null;
  }

  async updateAccountLinkToken(userId, pendingEmail, pendingProvider, token, expiry) {
    const user = this.users.get(userId);
    if (user) {
      user.accountLinkToken = token;
      user.accountLinkTokenExpiry = expiry;
      user.pendingEmail = pendingEmail;
      user.pendingProvider = pendingProvider;
    }
  }

  async findByAccountLinkToken(token) {
    for (const user of this.users.values()) {
      if (user.accountLinkToken === token) {
        return user;
      }
    }
    return null;
  }

  async updateRequire2FA(userId, required) {
    const user = this.users.get(userId);
    if (user) {
      user.require2FA = required;
    }
  }

  async findByProviderAccount(provider, providerAccountId) {
    for (const user of this.users.values()) {
      if (user.provider === provider && user.providerAccountId === providerAccountId) {
        return user;
      }
    }
    return null;
  }

  async listUsers(limit = 50, offset = 0) {
    return Array.from(this.users.values())
      .slice(offset, offset + limit);
  }

  async updateProfile(userId, data) {
    const user = this.users.get(userId);
    if (user) {
      if (data.firstName !== undefined) user.firstName = data.firstName;
      if (data.lastName !== undefined) user.lastName = data.lastName;
    }
  }

  async updatePhoneNumber(userId, phoneNumber) {
    const user = this.users.get(userId);
    if (user) {
      user.phoneNumber = phoneNumber;
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
  // CSRF is disabled here to support native (Bearer token) clients.
  // For web/WASM clients in production, enable CSRF:
  //   csrf: { enabled: true }
  // awesome-node-auth handles both strategies on the same server —
  // it detects the auth strategy from the X-Auth-Strategy header.
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
app.listen(PORT, '127.0.0.1', () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║   Awesome Node Auth - Flutter Example Server              ║
║   Running on http://localhost:${PORT}                        ║
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
║   Info: http://localhost:${PORT}/info                        ║
║   Health: http://localhost:${PORT}/health                    ║
╚═══════════════════════════════════════════════════════════╝
  `);
});
