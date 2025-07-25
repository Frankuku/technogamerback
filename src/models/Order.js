import mongoose from 'mongoose';

const orderSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    items: [
        {
            productId: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Product',
                required: true
            },
            quantity: {
                type: Number,
                required: true,
                min: 1
            },
            price: {
                type: Number,
                required: true
            },
            productName: {
                type: String,
                required: true
            }
        }
    ],
    shippingAddress: {
        street: String,
        city: String,
        postalCode: String,
        country: String
    },
    paymentInfo: {
        type: String,
        enum: ['cash', 'credit', 'card'],
        default: 'cash'
    },
    totalItems: {
        type: Number,
        required: true
    },
    totalPrice: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'sent', 'delivered', 'cancelled'],
        default: 'pending'
    }
}, {
    timestamps: true
});

// Nota: Se eliminó el cálculo automático de totales para simplificar
// Los totales son calculados en el controlador

const Order = mongoose.model('Order', orderSchema);

export default Order;
