import { Router } from "express";
import { check, param } from 'express-validator';
import { handleValidationErrors } from "../middlewares/validationMiddleware.js";
import { verifyToken } from "../middlewares/verifyToken.js";
import {
    getProducts,
    getProductById,
    createProduct,
    updateProduct,
    deleteProduct,
    searchProducts,
    filterProducts,
    patchProduct,
    uploadProductImage
} from "../controllers/productController.js";
import upload from '../config/multer.js';
import { verifyAdminRole } from "../middlewares/verifyAdminRole.js";

const productRouter = Router();

productRouter.get("/", getProducts);

productRouter.get("/search", searchProducts);

productRouter.get("/filter", filterProducts);

productRouter.get("/:id", [
    param('id').isMongoId().withMessage('ID de producto no válido'),
    handleValidationErrors
], getProductById);

productRouter.post("/", [
    check('name').notEmpty().withMessage('El nombre del producto es obligatorio'),
    handleValidationErrors,
    verifyToken,
    verifyAdminRole
], createProduct);

productRouter.put("/:id", [
    param('id').isMongoId().withMessage('ID de producto no válido'),
    check('name').optional().notEmpty().withMessage('El nombre no puede estar vacío'),
    handleValidationErrors,
    verifyToken
], updateProduct);

productRouter.patch("/:id", [
    param('id').isMongoId().withMessage('ID de producto no válido'),
    handleValidationErrors,
    verifyToken,
    verifyAdminRole
], patchProduct);

productRouter.delete("/:id", [
    param('id').isMongoId().withMessage('ID de producto no válido'),
    handleValidationErrors,
    verifyToken,
    verifyAdminRole
], deleteProduct);

productRouter.post("/:id/upload", [
    param('id').isMongoId().withMessage('ID de producto no válido'),
    handleValidationErrors,
    verifyToken,
    verifyAdminRole
],
    upload.single('image'),
    uploadProductImage
);

export default productRouter;
