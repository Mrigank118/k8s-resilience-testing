import express from "express";
import cors from "cors";
import notes from "./notes.js";
import { auth } from "./auth.js";

const app = express();

app.use(cors());
app.use(express.json());




app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.use("/notes", async (req, res, next) => {
  await new Promise(r => setTimeout(r, 2000));
  next();
}, auth, notes);

export default app;
