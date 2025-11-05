const express = require('express');
const router = express.Router();
const { Product } = require('../models');

// Listar productos
router.get('/', async (req, res) => {
    const products = await Product.findAll();
    res.json(products);
});

// Obtener producto por ID
router.get('/:id', async (req, res) => {
    const p = await Product.findByPk(req.params.id);
    if (!p) return res.status(404).json({ error: 'Producto no encontrado' });
    res.json(p);
});

module.exports = router;
