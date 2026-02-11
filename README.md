# 🚀 [APP NAME] - Kitahack 2026

> **The "Grab" for IIUM Students — Safe, Verified, and Powered by AI.**

![Project Banner](https://placehold.co/1200x300?text=Project+Banner+Image+Here)
*(Add a screenshot or banner image here later)*

## 📖 About The Project
**[APP NAME]** is a centralized marketplace and safety platform designed exclusively for IIUM students. It solves the problem of fragmented Telegram groups and unverified strangers on campus.

Unlike standard marketplaces, we use **Gemini Multimodal AI** to verify student identities physically via their Matric Cards, creating a trusted "Sejahtera" ecosystem.

### 🌟 Key Features
* **🛡️ AI Identity Verification:** Scans RHB MySiswa/Matric cards using Google Gemini to prevent fraud.
* **🛒 Student Marketplace:** Buy/sell services and products (Nasi Lemak, Printing, Rides) in a trust-based environment.
* **🚨 Safety First:** Verified "Mahallah" location tracking for safe meetups.
* **💬 Real-Time Chat:** Built-in messaging for buyers and sellers (Planned).

---

## 🛠️ Tech Stack (The "Google Sandwich")

We utilized a modern, scalable architecture powered by Google technologies:

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Mobile App** | **Flutter** | Cross-platform UI (Android/iOS) |
| **Brain (AI)** | **Gemini 3 Flash Preview** | ID Card verification & Fraud detection |
| **Backend API** | **FastAPI (Python)** | High-speed orchestration layer |
| **Database** | **Firebase Firestore** | Real-time NoSQL database |
| **Tunneling** | **Ngrok** | Secure exposure of local AI server |

---

## ⚙️ Installation & Setup

To run this project locally, you need to run the **Backend** and **Mobile App** separately.

### 1️⃣ Backend Setup (The Brain)
*Prerequisite: Python 3.9+ installed*

```bash
# 1. Navigate to the backend folder
cd backend_api

# 2. Create and activate virtual environment
python -m venv venv
.\venv\Scripts\activate  # Windows
# source venv/bin/activate # Mac/Linux

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up Environment Variables
# Create a .env file and add: GEMINI_API_KEY=your_key_here

# 5. Run the Server
uvicorn main:app --reload
#----------------