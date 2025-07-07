import { Router } from 'express';
import {
    createOrder,
    getOrders,
    getOrderById,
    updateOrderStatus,
    cancelOrder
} from '../controllers/orderController.js';
import { verifyToken } from '../middlewares/verifyToken.js';

const router = Router();

router.post('/', verifyToken, verifyAdminRole,
    createOrder);

router.get('/', verifyToken, verifyAdminRole,
    getOrders);

router.get('/:id', verifyToken, verifyAdminRole,
    getOrderById);

router.patch('/:id/status', verifyToken, 
    updateOrderStatus);

router.post('/:id/cancel', verifyToken, 
    cancelOrder);

export default router;
