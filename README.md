# 🚀 Uniserve: The IIUM SuperApp

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Google Cloud](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Gemini AI](https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google-bard&logoColor=white)

> **Digitizing Campus Life.** A comprehensive mobile platform designed to streamline the student experience at the International Islamic University Malaysia (IIUM).

---

## 📖 Overview

**Uniserve** is more than just an app; it's a digital ecosystem. Built for **KitaHack 2026**, it bridges the gap between students, services, and campus logistics. From AI-powered identity verification to peer-to-peer marketplaces and runner services, Uniserve connects the community in one premium, easy-to-use interface.

## ✨ Key Features

### 🆔 **AI-Powered Identity Verification**
* **Smart Scanning:** Uses Google Gemini AI to instantly extract and verify student details from Matric cards.
* **Premium UX:** Custom camera overlay with tap-to-focus, flash toggle, and real-time visual guidance.
* **Security:** Validates matric numbers against student records automatically.

### 🖨️ **Smart Print Services**
* **Remote Printing:** Upload PDF/Images directly from your phone to campus printing shops.
* **Customization:** Select paper size (A4/A3), color options, and binding preferences.
* **Delivery Integration:** Request a student "Runner" to pick up and deliver your documents to your dorm.

### 🛒 **Campus Marketplace & Gig Economy**
* **Buy & Sell:** A secure platform for students to trade textbooks, electronics, and dorm essentials.
* **Service Listings:** Find or offer skills like PC repair, tutoring, or barbering.
* **Runner & Express:** On-demand food delivery and parcel pickup by students, for students.
* **Transport:** Carpooling and ride-sharing coordination within campus grounds.

### 🔐 **Secure Profile Management**
* **Flexible Login:** Sign in via Matric Number or Google Auth.
* **Digital ID:** View verification status and manage personal details.
* **Deep Linking:** Seamless navigation with external link support (e.g., `uniserve://verify`).

---

## 🛠️ Tech Stack

| Category | Technology |
| :--- | :--- |
| **Frontend** | Flutter (Dart) |
| **Backend** | Python (FastAPI) |
| **AI Model** | Google Gemini 1.5 Flash |
| **Cloud** | Google Cloud Run |
| **State Management** | Provider |
| **UI/UX** | Glassmorphism Design, `flutter_animate` |
| **Camera** | `camera` package with `flutter_image_compress` |

---

## 📱 Getting Started

Follow these steps to set up the project locally.

### Prerequisites
* Flutter SDK installed
* Dart SDK installed
* Git

### Installation

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/yourusername/uniserve.git](https://github.com/yourusername/uniserve.git)
    cd uniserve
    ```

2.  **Install Dependencies**
    ```bash
    cd mobile_app
    flutter pub get
    ```

3.  **Run the App**
    ```bash
    flutter run
    ```

---

## 📸 Screenshots

| Identity Scan | Marketplace | Print Service |
| :---: | :---: | :---: |
| *[Add Screenshot Here]* | *[Add Screenshot Here]* | *[Add Screenshot Here]* |

---

## 🤝 Contributors

* **Team FeelTheForce** - *KitaHack 2026*

---

<p align="center">
  Made with ❤️ for IIUM
</p>
