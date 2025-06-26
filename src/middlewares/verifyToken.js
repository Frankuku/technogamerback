import jwt from 'jsonwebtoken';
import User from '../models/User.js';

export const verifyToken = async (req, res, next) => {
    try {
        const authHeader = req.header('Authorization');
        
        if (!authHeader) {
            return res.status(401).json({ success: false, message: "invalid token" })
        }
        
        // Usar directamente el valor de Authorization como token
        const decoded = jwt.verify(authHeader, process.env.JWT_SECRET);

        if (!decoded) {
            return res.status(401).json({ success: false, message: "error token" })
        }

        // Obtener usuario completo de la base de datos
        const user = await User.findOne({ email: decoded.email });
        
        if (!user) {
            return res.status(401).json({ success: false, message: "Usuario no encontrado" })
        }
        
        // Incluir tanto los datos del token como el _id del usuario
        req.user = {
            ...decoded,
            _id: user._id
        };
        
        next();
    } catch (error) {
        res.status(401).json({ success: false })
    }
}
