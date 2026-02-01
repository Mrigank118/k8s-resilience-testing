const API = "/api";

const PASSWORD = "canary123";

const notesEl = document.getElementById("notes");
const newTitle = document.getElementById("newTitle");
const newContent = document.getElementById("newContent");
const addBtn = document.getElementById("addNote");
const fab = document.getElementById("fab");

let editingId = null;

/* API */

async function api(path, method = "GET", body) {
  const res = await fetch(API + path, {
    method,
    headers: {
      "Content-Type": "application/json",
      "X-APP-PASSWORD": PASSWORD
    },
    body: body ? JSON.stringify(body) : undefined
  });
  return res.json();
}

/* Load Notes */

async function loadNotes() {
  const notes = await api("/notes");
  notesEl.innerHTML = "";
  notes.forEach(renderNote);
}

/* Render Note */

function renderNote(note) {
  const card = document.createElement("div");
  card.className = "card";

  if (editingId === note.id) {
    card.classList.add("editing");
    card.innerHTML = `
      <input value="${note.title}" />
      <textarea>${note.content}</textarea>
      <div class="inline-actions">
        <button class="save">Save</button>
        <button class="cancel">Cancel</button>
      </div>
    `;
  } else {
    card.innerHTML = `
      <span class="delete">×</span>
      <h3>${note.title}</h3>
      <p>${note.content}</p>
    `;

    card.onclick = () => {
      editingId = note.id;
      loadNotes();
    };

    card.querySelector(".delete").onclick = async (e) => {
      e.stopPropagation();
      await api(`/notes/${note.id}`, "DELETE");
      loadNotes();
    };
  }

  notesEl.appendChild(card);
}

/* Add Note */

addBtn.onclick = async () => {
  const title = newTitle.value.trim();
  const content = newContent.value.trim();
  if (!title || !content) return;

  await api("/notes", "POST", { title, content });
  newTitle.value = "";
  newContent.value = "";
  loadNotes();
};

/* FAB → focus composer */

fab.onclick = () => {
  newTitle.focus();
};

/* Edit actions */

notesEl.addEventListener("click", async (e) => {
  const card = e.target.closest(".card");
  if (!card) return;

  if (e.target.classList.contains("save")) {
    const title = card.querySelector("input").value.trim();
    const content = card.querySelector("textarea").value.trim();
    if (!title || !content) return;

    await api(`/notes/${editingId}`, "PUT", { title, content });
    editingId = null;
    loadNotes();
  }

  if (e.target.classList.contains("cancel")) {
    editingId = null;
    loadNotes();
  }
});

/* Init */

loadNotes();
