const { Product } = require('../models');

module.exports = async () => {
    await Product.bulkCreate([
        { name: 'Mouse Gamer', description: 'Mouse óptico RGB', price: 39.99, image: 'mouse.jpg' },
        { name: 'Teclado Mecánico', description: 'Switches azules, retroiluminado', price: 79.99, image: 'keyboard.jpg' },
        { name: 'Monitor 24”', description: 'Full HD, 75Hz', price: 149.99, image: 'monitor.jpg' },
        { name: 'Audífonos Bluetooth', description: 'Cancelación de ruido', price: 99.99, image: 'earbuds.jpg' }
    ]);
    console.log('✅ Productos semilla insertados');
};
