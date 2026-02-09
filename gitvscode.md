---
marp: true
theme: gaia
class: lead
backgroundColor: #1e1e1e
color: #d4d4d4
paginate: true
---

# Git for Beginners: The VS Code Way
## specific guide for CS Students

![width:150px](https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png) + ![width:150px](https://upload.wikimedia.org/wikipedia/commons/9/9a/Visual_Studio_Code_1.35_icon.svg)

---

## 1. Why use the GUI (Buttons)?
### "Work smarter, not harder"

The Terminal (`CLI`) is great, but the VS Code Interface (`GUI`) is faster for learning.

* **Visual Feedback:** See your changes side-by-side.
* **Safety:** Harder to accidentally delete things.
* **Speed:** Click "Stage" instead of typing `git add .` every time.

> **Analogy:** CLI is driving manual. VS Code GUI is driving automatic.

---

## 2. The Setup: Finding the "Source Control" Tab

Everything happens in the **Source Control** panel.

1.  Look at the **Activity Bar** on the far left.
2.  Find the icon that looks like a **Branch** (three dots connected by lines).
3.  **Keyboard Shortcut:** `Ctrl + Shift + G`

![width:40px](https://code.visualstudio.com/assets/docs/editor/versioncontrol/icon-source-control.png) <--- Look for this!

---

## 3. Starting a Project (Initialize)

You don't need to type `git init` in the terminal!

1.  Open your project folder in VS Code.
2.  Open the **Command Palette** (`Ctrl + Shift + P`).
3.  Type: `Git: Initialize Repository`.
4.  Pick your folder.

*Boom! Your project is now a Git repository.*

---

## 4. The Golden Workflow
### The "Stage & Commit" Loop

This is 90% of what you will do.

1.  **Change:** Edit a file. It turns "M" (Modified).
2.  **Stage (+):** Hover over the file in the list and click the **+** button.
    * *This saves the file to the "staging area".*
3.  **Commit:** Type a message in the box (e.g., "Fixed login bug") and press **Commit** (Checkmark).
    * *This saves the snapshot forever.*

---

## 5. Branching (The Bottom Left Corner)

Never work on the `main` branch directly!

1.  Look at the very **bottom-left corner** of VS Code.
2.  Click the name (usually says `main` or `master`).
3.  Select **+ Create new branch...** at the top.
4.  Name it (e.g., `feature/login-page`).

*VS Code automatically switches you to the new branch.*

---

## 6. Syncing (Push & Pull)

Save your work to GitHub/GitLab.

* **Publish:** If it's a new branch, click the **Cloud Icon** ☁️ in the Source Control panel.
* **Sync:** If you are already connected, just click the **Rotate Arrows** 🔄 in the bottom-left corner.

> **Note:** This does a `git pull` (download) AND `git push` (upload) in one click.

---

## 7. Visualizing History (Git Graph)

VS Code is good, but **Git Graph** makes it perfect.

* **Install It:** Search "Git Graph" in Extensions.
* **Use It:** Click the "Git Graph" button in your status bar.
* **See It:** It draws a "subway map" of your project history.

*This helps you see who did what, and when branches merged.*

---

## 8. Merge Conflicts (Don't Panic!)

When two people edit the same line, VS Code helps you fix it.

It highlights the code in colors:
* **Green:** Current Change (What you wrote).
* **Blue:** Incoming Change (What your friend wrote).

**How to fix:**
Just click the little text buttons that appear:
`Accept Current Change` | `Accept Incoming Change` | `Accept Both`

---