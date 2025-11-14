// backend/models/Cart.js
const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
    return sequelize.define('Cart', {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        userId: { type: DataTypes.INTEGER, allowNull: false },
        productId: { type: DataTypes.INTEGER, allowNull: false },
        quantity: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 1 }
    });
};