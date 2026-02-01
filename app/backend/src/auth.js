export function auth(req, res, next) {
  const password = req.headers["x-app-password"];
  if (!password || password !== process.env.APP_PASSWORD) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  next();
}
