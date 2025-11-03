// backend/models/Order.js
module.exports = (sequelize, DataTypes) => {
    return sequelize.define('Order', {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        userId: { type: DataTypes.INTEGER, allowNull: false },
        total: { type: DataTypes.FLOAT, allowNull: false },
        details: { type: DataTypes.JSON }, // productos comprados
        createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
    });
};