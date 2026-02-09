---
marp: true
theme: gaia
class: lead
backgroundColor: #1e1e1e
color: #d4d4d4
paginate: true
---

# Git in VS Code: The "Cloning" Workflow
## How to download & work on an existing repo

![width:150px](https://git-scm.com/images/logos/downloads/Git-Icon-1788C.png) + ![width:150px](https://upload.wikimedia.org/wikipedia/commons/9/9a/Visual_Studio_Code_1.35_icon.svg)

---

## 1. Why use the GUI?
### "Stop memorizing commands"

We use the visual interface because it's safer for beginners.

* **No Typos:** You can't accidentally type the wrong command.
* **Visual Status:** See exactly which files are changed (colored yellow/green).
* **One Click:** Syncing is just one button press.



---

## 2. The Scenario: "Cloning"
### We already have a repo online.

We don't need `git init`. We need to **Clone** (download) it.

**Prerequisite:**
1.  Go to the repository on GitHub/GitLab.
2.  Click the green **Code** button.
3.  **Copy the URL** (starts with `https://...`).

---

## 3. How to Clone in VS Code

1.  Open VS Code (Empty window is fine).
2.  Open the **Command Palette** (`Ctrl + Shift + P`).
3.  Type `Git: Clone` and press Enter.
4.  **Paste the URL** you copied from GitHub.
5.  Select a folder on your laptop to save it in.

*VS Code will ask "Would you like to open the cloned repository?" Click **Open**.*

---

## 4. The "Daily Loop": Stage & Commit

Once the code is on your laptop, this is your cycle:

1.  **Edit:** Make changes to a file. (It turns 'M' for Modified).
2.  **Stage (+):** Go to the Source Control tab (Left bar). Click the **+** next to the file.
    * *This prepares the file for saving.*
3.  **Commit:** Type a message ("Fixed the login bug") and click the **Checkmark** (✓).
    * *This saves a snapshot of your work.*

---

## 5. Branching (Safety First)

Don't break the main code! Create a safe space to work.

1.  Look at the **bottom-left corner** (Status Bar).
2.  Click the branch name (e.g., `main`).
3.  Select **+ Create new branch...**.
4.  Name it (e.g., `update-readme`).

*You are now working in a parallel universe. Your changes won't break the main code.*

---

## 6. Syncing (Push & Pull)

Send your work back to the internet.

* **The "Sync" Button:** Look for the **Rotate Arrows** 🔄 icon in the bottom-left corner next to your branch name.
* **Click it once.**
    * It pulls (downloads) any new changes from friends.
    * It pushes (uploads) your new commits.



---

## 7. Visualizing History (Git Graph)

See what your teammates are doing.

* **Extension:** Install "Git Graph" from the Extensions marketplace.
* **Usage:** Click the "Git Graph" button in the status bar.
* **Result:** You see a beautiful "subway map" of everyone's work.

---

## 8. Merge Conflicts (When things clash)

If you and a friend edit the exact same line, VS Code helps you.

It highlights the conflict in colors:
* **Current Change (Green):** What *you* wrote.
* **Incoming Change (Blue):** What *they* wrote.

**The Fix:**
Just click the small text button that appears above the code:
`Accept Current Change` or `Accept Incoming Change`.

---

## 9(a). Handling Secrets (API Keys)
### The `.env` vs `.env.template` Rule

**The Problem:** You have a Gemini API Key. You want to share code, but **NOT** the key.

1.  **`.env`** (🛑 **SECRET**):
    * Contains: `API_KEY=AIzaSy...`
    * **NEVER commit this file.** (Add it to `.gitignore`).

2.  **`.env.template`** (✅ **SAFE**):
    * Contains: `API_KEY=` (Empty value).
    * **Commit this file.**
    * *Why?* It tells teammates: "You need a key here to run this."

---


## 9(b). Keeping it Clean (Ignore the Junk)

Don't upload 50,000 files by accident!

1.  **`venv/`** (🛑 **IGNORE**):
    * Your "Virtual Environment" folder.
    * It's huge and specific to *your* laptop. **Never commit.**

2.  **`.gitignore`** (⚙️ **THE GUARD**):
    * A text file that lists folders like `venv/` and `.env`.
    * Git automatically ignores anything listed here.

3.  **`README.md`** (📖 **THE MANUAL**):
    * Instructions on how to run your code.
    * *Always write this for your future self!*


---

## 9(c). DOs and DON'Ts (Crucial!)

| ✅ DO | ❌ DON'T |
| :--- | :--- |
| **Pull** before you start coding every day. | **Commit** `node_modules` or `.env` files. |
| Write **clear messages** (e.g., "Added logo"). | Write **vague messages** (e.g., "update" or "fix"). |
| use `.gitignore` to hide junk files. | **Force Push** unless you are 100% sure. |

---
## 10. Troubleshooting: "Who are you?"

**Error:** `Please tell me who you are.`
**Reason:** Git doesn't know your name yet.

**The Fix (Run in Terminal once):**
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

---

## 9. Troubleshooting: "Permission Denied"

**Error:** `Permission denied (publickey)` or `Authentication failed`.
**Reason:** VS Code isn't logged into GitHub.

**The Fix:**
1.  Look for the **Accounts** icon (Person icon) at the bottom-left sidebar.
2.  Click "Sign in to Sync Settings" or check for an alert.
3.  Select **Sign in with GitHub**.
4.  Follow the browser popup to authorize.

---

## 10. Troubleshooting: Merge Conflicts

**Error:** `CONFLICT (content): Merge conflict in...`
**Reason:** Two people changed the same line.

**The Fix (Don't Panic):**
1.  Open the file with the conflict (it will be red in the list).
2.  Look for the highlighted colors (Green vs Blue).
3.  Click **Accept Incoming Change** (Their code) or **Accept Current Change** (Your code).
4.  Save and Commit.



---

## 11. The Emergency Output Panel

If Git is acting weird and you don't know why:

1.  Press `Ctrl + Shift + U` to open the **Output** panel.
2.  In the dropdown (top-right of the panel), select **Git**.
3.  Read the last few lines—it will tell you exactly what command failed.