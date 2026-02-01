import express from "express";
import db from "./db.js";

const router = express.Router();

/* CREATE */
router.post("/", (req, res) => {
  const { title, content } = req.body;
  if (!title || !content) {
    return res.status(400).json({ error: "Title and content required" });
  }

  const result = db
    .prepare("INSERT INTO notes (title, content) VALUES (?, ?)")
    .run(title, content);

  res.status(201).json({ id: result.lastInsertRowid });
});

/* READ */
router.get("/", (req, res) => {
  const notes = db
    .prepare("SELECT * FROM notes ORDER BY updated_at DESC")
    .all();
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
    return res.status(404).json({ error: "Note not found" });
  }

  res.json({ success: true });
});

/* DELETE */
router.delete("/:id", (req, res) => {
  const result = db
    .prepare("DELETE FROM notes WHERE id = ?")
    .run(req.params.id);

  if (result.changes === 0) {
    return res.status(404).json({ error: "Note not found" });
  }

  res.json({ success: true });
});

export default router;
