export const verifyAdminRole = (req, res, next) => {

    const user = req.user;

    if (user.role !== "admin") {
        return res.json({ success: false, message: "you need admin role" })
    }

    next()
}
