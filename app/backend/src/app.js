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

app.use("/notes", auth, notes);

export default app;
