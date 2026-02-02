import express from "express";
import db from "./db.js";
import { httpRequests } from "./metrics.js";

const router = express.Router();

/* CREATE */
router.post("/", (req, res) => {
  const { title, content } = req.body;

  if (!title || !content) {
    httpRequests.inc({ method: "POST", route: "/notes", status: "400" });
    return res.status(400).json({ error: "Title and content required" });
  }

  const result = db
    .prepare("INSERT INTO notes (title, content) VALUES (?, ?)")
    .run(title, content);

  httpRequests.inc({ method: "POST", route: "/notes", status: "201" });
  res.status(201).json({ id: result.lastInsertRowid });
});

/* READ */
router.get("/", (req, res) => {
  const notes = db
    .prepare("SELECT * FROM notes ORDER BY updated_at DESC")
    .all();

  httpRequests.inc({ method: "GET", route: "/notes", status: "200" });
  res.json(notes);
});

/* UPDATE */
router.put("/:id", (req, res) => {
  const { title, content } = req.body;
  const { id } = req.params;

  const result = db.prepare(`
    UPDATE notes
    SET title = ?, content = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
  `).run(title, content, id);

  if (result.changes === 0) {
    httpRequests.inc({ method: "PUT", route: "/notes/:id", status: "404" });
    return res.status(404).json({ error: "Note not found" });
  }

  httpRequests.inc({ method: "PUT", route: "/notes/:id", status: "200" });
  res.json({ success: true });
});

/* DELETE */
router.delete("/:id", (req, res) => {
  const result = db
    .prepare("DELETE FROM notes WHERE id = ?")
    .run(req.params.id);

  if (result.changes === 0) {
    httpRequests.inc({ method: "DELETE", route: "/notes/:id", status: "404" });
    return res.status(404).json({ error: "Note not found" });
  }

  httpRequests.inc({ method: "DELETE", route: "/notes/:id", status: "200" });
  res.json({ success: true });
});

export default router;
