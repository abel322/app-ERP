const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const generateTokens = (user) => {
    const accessToken = jwt.sign(
        { id: user.id, username: user.username, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '15m' }
    );

    const refreshToken = jwt.sign(
        { id: user.id },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: '7d' }
    );

    return { accessToken, refreshToken };
};

const login = async (req, res) => {
    try {
        const { username, password } = req.body;

        // Validate input
        if (!username || !password) {
            return res.status(400).json({ error: 'Username and password are required' });
        }

        // Find user
        const user = await prisma.user.findUnique({
            where: { username },
        });

        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Verify password
        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        // Check if active
        if (!user.is_active) {
            return res.status(403).json({ error: 'User is inactive' });
        }

        // Update last login
        await prisma.user.update({
            where: { id: user.id },
            data: { last_login: new Date() },
        });

        // Generate tokens
        const tokens = generateTokens(user);

        res.json({
            message: 'Login successful',
            user: {
                id: user.id,
                username: user.username,
                full_name: user.full_name,
                email: user.email,
                role: user.role,
            },
            ...tokens,
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

const refreshToken = async (req, res) => {
    const { refreshToken } = req.body;

    if (!refreshToken) {
        return res.status(401).json({ error: 'Refresh Token Required' });
    }

    try {
        const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

        const user = await prisma.user.findUnique({
            where: { id: payload.id },
        });

        if (!user || !user.is_active) {
            return res.status(403).json({ error: 'Invalid user or inactive' });
        }

        const tokens = generateTokens(user);
        res.json(tokens);

    } catch (error) {
        return res.status(403).json({ error: 'Invalid Refresh Token' });
    }
};

module.exports = { login, refreshToken };
