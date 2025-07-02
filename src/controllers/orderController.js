import Order from "../models/Order.js";
import Product from "../models/Product.js";
import User from "../models/User.js";

export const createOrder = async (req, res) => {
    try {
        const {
            items,
            shippingAddress,
            paymentInfo
        } = req.body;

        if (!items || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'La orden debe contener al menos un producto'
            });
        }

        const orderItems = [];
        for (const item of items) {
            const product = await Product.findById(item.productId);
            if (!product) {
                return res.status(404).json({
                    success: false,
                    message: `Producto con ID ${item.product} no encontrado`
                });
            }

            if (product.stock < item.quantity) {
                return res.status(400).json({
                    success: false,
                    message: `Stock insuficiente para ${product.name}. Disponible: ${product.stock}, Solicitado: ${item.quantity}`
                });
            }
            orderItems.push({
                productId: product._id,
                quantity: item.quantity,
                price: product.price,
                productName: product.name
            });

            product.stock -= item.quantity;
            await product.save();
        }

        const order = await Order.create({
            user: "685dd8489f2b33b59c5b546d",
            items: orderItems,
            shippingAddress,
            paymentInfo,
            totalItems: orderItems.reduce((sum, item) => sum + item.quantity, 0),
            totalPrice: orderItems.reduce((sum, item) => sum + (item.price * item.quantity), 0),
        });

        res.status(201).json({
            success: true,
            message: 'Orden creada exitosamente',
            order
        });

    } catch (error) {
        console.log(error);
        res.status(500).json({
            success: false,
            message: 'Error al crear la orden',
            error: error.message
        });
    }
};

export const getOrders = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const { status, orderId, userSearch } = req.query;

        let query = {};

        if (status) {
            query.status = status;
        }

        let orders = await Order.find(query)
            .populate('user', 'username email')
            .sort({ createdAt: -1 });

        // Filtro por ID parcial (orderId)
        if (orderId) {
            const lowerId = orderId.toLowerCase();
            orders = orders.filter(o =>
                o._id.toString().toLowerCase().includes(lowerId)
            );
        }

        // Filtro por usuario (email o username)
        if (userSearch) {
            const lowerSearch = userSearch.toLowerCase();
            orders = orders.filter(o =>
                o.user?.username?.toLowerCase().includes(lowerSearch) ||
                o.user?.email?.toLowerCase().includes(lowerSearch)
            );
        }

        const total = orders.length;
        const totalPages = Math.ceil(total / limit);
        const paginatedOrders = orders.slice(skip, skip + limit);

        res.json({
            success: true,
            orders: paginatedOrders,
            total,
            totalPages,
            currentPage: page
        });

    } catch (error) {
        console.error("ERROR EN getOrders:", error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener las órdenes',
            error: error.message
        });
    }
};

export const getOrderById = async (req, res) => {
    try {
        const orderId = req.params.id;

        const order = await Order.findById(orderId)
            .populate('user', 'username email')
            .populate('items.productId');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Orden no encontrada'
            });
        }
        res.json({
            success: true,
            order
        });
    } catch (error) {
        console.log(error);
        res.status(500).json({
            success: false,
            message: 'Error al obtener la orden',
            error: error.message
        });
    }
};

export const updateOrderStatus = async (req, res) => {
    try {
        const orderId = req.params.id;
        const { status, paymentStatus } = req.body;
        const order = await Order.findById(orderId);

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Orden no encontrada'
            });
        }

        if (status) {
            order.status = status;

            if (status === 'delivered') {
                order.deliveredAt = Date.now();
            }
        }

        if (paymentStatus) {
            order.paymentInfo.status = paymentStatus;

            if (paymentStatus === 'completed') {
                order.paymentInfo.paidAt = Date.now();
            }
        }

        await order.save();

        res.json({
            success: true,
            message: 'Estado de la orden actualizado',
            order
        });
    } catch (error) {
        console.log(error);
        res.status(500).json({
            success: false,
            message: 'Error al actualizar el estado de la orden',
            error: error.message
        });
    }
};

export const cancelOrder = async (req, res) => {
    try {
        const orderId = req.params.id;

        const order = await Order.findById(orderId).populate('items.product');

        if (!order) {
            return res.status(404).json({
                success: false,
                message: 'Orden no encontrada'
            });
        }

        if (order.user.toString() !== req.user._id.toString() && !req.user.isAdmin) {
            return res.status(403).json({
                success: false,
                message: 'No tiene permiso para cancelar esta orden'
            });
        }

        if (!['pending', 'processing'].includes(order.status)) {
            return res.status(400).json({
                success: false,
                message: `No se puede cancelar una orden con estado "${order.status}"`
            });
        }

        for (const item of order.items) {
            const product = await Product.findById(item.product);
            if (product) {
                product.stock += item.quantity;
                await product.save();
            }
        }

        order.status = 'cancelled';
        await order.save();

        res.json({
            success: true,
            message: 'Orden cancelada exitosamente',
            order
        });
    } catch (error) {
        console.log(error);
        res.status(500).json({
            success: false,
            message: 'Error al cancelar la orden',
            error: error.message
        });
    }
};

