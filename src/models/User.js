import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
    username: {
        type: String,
        required: [true, 'El nombre de usuario es obligatorio'],
        unique: true,
        trim: true
    },
    email: {
        type: String,
        required: [true, 'El correo electrónico es obligatorio'],
        unique: true,
        trim: true
    },
    password: {
        type: String,
        required: [true, 'La contraseña es obligatoria']
    },
    role: {
        type: String,
        enum: ['user', 'admin'],
        default: 'user'
    }
}, {
    timestamps: true
    // Se eliminaron las opciones de virtuals para simplificar el modelo
});

// Nota: Las relaciones entre usuarios y órdenes pueden manejarse directamente en las consultas
// usando los métodos find() de Mongoose, sin necesidad de virtuales

const User = mongoose.model('User', userSchema);

export default User;
