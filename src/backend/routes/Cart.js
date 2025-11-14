// backend/routes/Cart.js
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { Cart, Product } = require('../models');

// 🛒 Obtener carrito
router.get('/', auth, async (req, res) => {
    try {
        const userId = req.user.id;

        const items = await Cart.findAll({
            where: { userId },
            include: [{
                model: Product,
                as: 'productData', // 👈 coincide con el alias nuevo
                attributes: ['id', 'name', 'price', 'image']
            }]
        });

        console.log('🧾 Carrito crudo:', JSON.stringify(items, null, 2));

        const normalized = items.map(item => ({
            id: item.id,
            productId: item.productId,
            quantity: item.quantity,
            product: item.productData // 👈 ajustamos la referencia aquí
        }));

        res.json(normalized);
    } catch (err) {
        console.error('❌ Error al obtener carrito:', err);
        res.status(500).json({ message: 'Error al obtener el carrito' });
    }
});

// ➕ Agregar producto
router.post('/:productId', auth, async (req, res) => {
    try {
        const userId = req.user.id;
        const productId = req.params.productId;

        const existing = await Cart.findOne({ where: { userId, productId } });
        if (existing) {
            existing.quantity += 1;
            await existing.save();
        } else {
            await Cart.create({ userId, productId, quantity: 1 });
        }

        res.json({ message: 'Producto agregado al carrito ✅' });
    } catch (err) {
        console.error('❌ Error al agregar producto:', err);
        res.status(500).json({ message: 'Error al agregar producto al carrito' });
    }
});

// ❌ Eliminar producto
router.delete('/:productId', auth, async (req, res) => {
    try {
        const userId = req.user.id;
        const productId = req.params.productId;
        await Cart.destroy({ where: { userId, productId } });
        res.json({ message: 'Producto eliminado del carrito 🗑️' });
    } catch (err) {
        console.error('❌ Error al eliminar producto:', err);
        res.status(500).json({ message: 'Error al eliminar producto del carrito' });
    }
});

module.exports = router;