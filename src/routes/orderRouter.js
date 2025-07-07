import { Router } from 'express';
import {
    createOrder,
    getOrders,
    getOrderById,
    updateOrderStatus,
    cancelOrder
} from '../controllers/orderController.js';
import { verifyToken } from '../middlewares/verifyToken.js';
import {verifyAdminRole} from '../middlewares/verifyAdminRole.js';

const router = Router();

router.post('/', verifyToken, verifyAdminRole,
    createOrder);

router.get('/', 
    getOrders);

router.get('/:id', verifyToken,
    getOrderById);

router.patch('/:id/status', verifyToken, verifyAdminRole,
    updateOrderStatus);

router.post('/:id/cancel', verifyToken, verifyAdminRole,
    cancelOrder);

export default router;
