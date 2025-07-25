import dotenv from "dotenv";
import express from "express";
import morgan from "morgan";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";
import cors from "cors";
import { connectDB } from "./config/db.js";
import userRouter from "./routes/userRouter.js";
import productRouter from "./routes/productRouter.js";
import categoryRouter from "./routes/categoryRouter.js";
import orderRouter from "./routes/orderRouter.js";
import relationRouter from "./routes/relationRouter.js";
import authRouter from "./routes/authRouter.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();

connectDB();

const uploadsDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const app = express();

app.use(express.json());

const allowedOrigins = [
  'http://localhost:5173',
  'https://techno-gamer.netlify.app'
];

app.use(cors({
  origin: function (origin, callback) {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('No permitido por CORS'));
    }
  },
  credentials: true,
}));

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use(morgan('dev'));

app.use((req, res, next) => {
    console.log(`${new Date()}: METHOD: ${req.method}`)
    next()
})

app.use("/api/auth", authRouter);
app.use("/api/users", userRouter);
app.use("/api/products", productRouter);
app.use("/api/categories", categoryRouter);
app.use("/api/orders", orderRouter);
app.use("/api/relations", relationRouter);

const port = process.env.PORT
console.log(`Puerto configurado: ${port}`);

app.listen(port, () => {
    console.log(`Server (backend) running on port: ${port}`)
})
app.get("/", (req, res) => {
    res.send("API funcionando correctamente 🚀");
});
