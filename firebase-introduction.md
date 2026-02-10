---
marp: true
theme: gaia
class: lead
backgroundColor: #1e1e1e
color: #d4d4d4
paginate: true
---

# Firebase for Beginners
## The "Instant Backend" for your Apps

![width:150px](https://firebase.google.com/static/images/brand-guidelines/logo-vertical.png)

---

## 1. What is Firebase?
### "Backend-as-a-Service" (BaaS)

**The Old Way:**
* Buy a server.
* Install Linux.
* Install a Database (SQL).
* Write API code to talk to the database.
* *Spend 2 weeks configuring security.*

---

**The Firebase Way:**
* Click "Create Database".
* **Done.** You can now save data from your app instantly.

> **Analogy:** Instead of building your own kitchen (Server), you just order Pizza (Data) from a restaurant that already exists.

---

## 2. The "Big Three" Services
What you will actually use in your student projects:

1.  **Authentication (Auth):**
    * Handles "Sign Up", "Login", and "Forgot Password".
    * Supports Google, Facebook, Apple, and GitHub Sign-In.

2.  **Cloud Firestore (The Database):**
    * A NoSQL database. It stores data like **JSON objects**, not rows and columns.
    * It updates your app in **Real-Time** (Chat apps!).

---

3.  **Storage:**
    * Where you keep files (Images, Videos, PDFs).
    * *Database = Text only. Storage = Files.*

---

## 3. Setting Up a Project (The Console)

1.  Go to **[console.firebase.google.com](https://console.firebase.google.com)**.
2.  Click **"Add project"**.
3.  Give it a name (e.g., `my-first-app`).
4.  **Disable Google Analytics** (For now—it simplifies setup).
5.  Click **Create Project**.

*Wait 30 seconds, and your backend is ready.*

---

## 4. Enabling Google Sign-In (Step-by-Step)

Most apps need a "Login with Google" button. Here is how to turn it on:

1.  In the Firebase Console, go to **Build** -> **Authentication**.
2.  Click **"Get Started"**.
3.  Click the **"Sign-in method"** tab.
4.  Select **Google**.
5.  **Toggle "Enable"** (Top right switch).
6.  Select your **Support Email** (Required).
7.  Click **Save**.

*The backend is now ready to accept Google accounts!*

---

## 5. Connecting Your App (The "Config")

Your code needs to know *which* Firebase project to talk to.

**For Web (React/JS):**
1.  Click the **Gear Icon** (Project Settings).
2.  Scroll down to "Your Apps" -> Click the **Web (</>)** icon.
3.  Copy the `firebaseConfig` object (API Keys).

---

**For Flutter (The Easy Way):**
1.  Open your terminal.
2.  Run: `dart pub global activate flutterfire_cli`
3.  Run: `flutterfire configure`
4.  *It automatically downloads the keys for Android and iOS!*

---

## 6. Understanding the Database (Firestore)
### Collections vs. Documents

Stop thinking about SQL "Tables." Think about **Folders** and **Files**.

* **Collection (Folder):** A container for documents.
    * Example: `users`

---

* **Document (File):** A single item with data.
    * Example: `user_abc123`
* **Fields (Data):** The actual content inside the document.
    * `name: "Ali"`
    * `age: 21`

**Structure:** `Collection (users)` -> `Document (ali)` -> `Data`

---

## 7. Security Rules (The Danger Zone ⚠️)

By default, Firebase blocks everyone from reading your data.

**For Development ONLY (Dangerous!):**
You can set rules to allow anyone to read/write while you test.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // <--- DANGEROUS!
    }
  }
}