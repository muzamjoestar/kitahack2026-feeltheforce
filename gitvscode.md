---
marp: true
theme: gaia
class: lead
backgroundColor: #1e1e1e
color: #d4d4d4
---

# Mastering Git inside VS Code
## A visual guide to version control

![width:100px](https://upload.wikimedia.org/wikipedia/commons/9/9a/Visual_Studio_Code_1.35_icon.svg) + ![width:100px](https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png)

---

## 1. Why VS Code Source Control?
### GUI vs. CLI

While the terminal (`CLI`) is powerful, the VS Code Interface (`GUI`) offers speed and clarity.

* **Visual Diffing:** See exactly what lines changed side-by-side.
* **One-Click Actions:** Stage, commit, and sync without typing commands.
* **Conflict Resolution:** Highlighted code blocks make merging safer.

> **Pro Tip:** You can open the integrated terminal anytime with `Ctrl + ~` if you need to run complex commands.

---

## 2. The Setup: Source Control Tab

Access the Git panel from the **Activity Bar** on the left.

* **Icon:** Look for the "Branch" icon (three circles connected by lines).
    * *Shortcut:* `Ctrl + Shift + G`
* **The View:** This panel shows:
    * **Source Control:** Your active repository.
    * **Changes:** Files you have modified.
    * **Staged Changes:** Files ready to commit.

---

## 3. Initializing a Repository

No need to open the terminal to type `git init`.

1.  Open the **Command Palette** (`Ctrl + Shift + P`).
2.  Type and select: `Git: Initialize Repository`.
3.  Select your workspace folder.

**Equivalent Terminal Command:**
```bash
git init