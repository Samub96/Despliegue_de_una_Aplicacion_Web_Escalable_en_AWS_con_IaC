// backend/routes/checkout.js
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { Cart, Product, Order } = require('../models');

// 💳 Simular pago y guardar compra
router.post('/', auth, async (req, res) => {
    try {
        const userId = req.user.id;

        // Obtener los productos del carrito
        const items = await Cart.findAll({
            where: { userId },
            include: [{ model: Product, as: 'productData' }]
        });

        if (!items.length) {
            return res.status(400).json({ message: 'El carrito está vacío' });
        }

        // Calcular el total
        const total = items.reduce(
            (sum, item) => sum + (item.productData?.price || 0) * item.quantity,
            0
        );

        // Guardar la orden
        const order = await Order.create({
            userId,
            total,
            details: items.map(i => ({
                id: i.productData.id,
                name: i.productData.name,
                price: i.productData.price,
                quantity: i.quantity
            }))
        });

        // Vaciar carrito
        await Cart.destroy({ where: { userId } });

        res.json({ message: '✅ Compra simulada con éxito', order });
    } catch (err) {
        console.error('❌ Error en checkout:', err);
        res.status(500).json({ message: 'Error al procesar la compra' });
    }
});

module.exports = router;