// backend/server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { sequelize, Product } = require('./models');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors({ origin: 'http://127.0.0.1:5500', credentials: true }));

app.use(express.json());
app.use('/api/auth', require('./routes/auth'));
app.use('/api/products', require('./routes/products'));
app.use('/api/cart', require('./routes/Cart'));
app.use('/api/checkout', require('./routes/checkout'));

app.get('/', (req, res) => res.json({ message: 'OK' }));
app.get('/health', (req, res) => res.json({ status: 'healthy', timestamp: new Date().toISOString() }));

(async () => {
    try {
        await sequelize.authenticate();
        console.log('✅ Conexión DB OK');
        await sequelize.sync({ alter: true });
        console.log('🗄️ Base de datos sincronizada');

        const count = await Product.count();
        if (count === 0) {
            const seed = require('./seed/seedProducts');
            await seed();
            console.log('🌱 Productos semilla insertados');
        }

        app.listen(PORT, () => console.log(`Servidor en http://localhost:${PORT}`));
    } catch (err) {
        console.error('❌ Error al iniciar servidor:', err);
    }
})();
