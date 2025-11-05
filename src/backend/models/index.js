// backend/models/index.js
const { Sequelize, DataTypes } = require('sequelize');
require('dotenv').config();

const sequelize = new Sequelize(
    process.env.DB_NAME || 'ecommerce_db',
    process.env.DB_USER || 'root',
    process.env.DB_PASSWORD || '',
    {
        host: process.env.DB_HOST || 'localhost',
        dialect: 'mysql',
        logging: false,
    }
);

const db = {};

// Inicializar modelos
db.User = require('./User')(sequelize, DataTypes);
db.Product = require('./Product')(sequelize, DataTypes);
db.Cart = require('./Cart')(sequelize, DataTypes);
db.Order = require('./Order')(sequelize, DataTypes);

// 🔗 Asociaciones sin conflictos
db.User.hasMany(db.Cart, { foreignKey: 'userId', as: 'cartItems' });
db.Cart.belongsTo(db.User, { foreignKey: 'userId', as: 'user' });

db.Product.hasMany(db.Cart, { foreignKey: 'productId', as: 'cartEntries' });
db.Cart.belongsTo(db.Product, { foreignKey: 'productId', as: 'productData' }); // 👈 CAMBIAMOS EL ALIAS

db.User.hasMany(db.Order, { foreignKey: 'userId', as: 'orders' });
db.Order.belongsTo(db.User, { foreignKey: 'userId', as: 'user' });

db.Sequelize = Sequelize;
db.sequelize = sequelize;

module.exports = db;