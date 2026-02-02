import app from "./app.js";
import { register } from "./metrics.js";

const PORT = 3000;

// Prometheus metrics endpoint (NO auth here)
app.get("/metrics", async (req, res) => {
  res.setHeader("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.listen(PORT, () => {
  console.log(`Canary backend running on port ${PORT}`);
});
