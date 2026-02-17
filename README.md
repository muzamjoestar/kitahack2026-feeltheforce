# Uniserve - IIUM Student SuperApp 🚀

**Uniserve** is a comprehensive mobile platform designed to digitize and streamline campus life for IIUM students. From verifying student identity to requesting print services and finding runners, Uniserve connects the campus community in one premium, easy-to-use app.

## ✨ Key Features

### 🆔 Smart Identity Verification
- **AI-Powered Scanner**: Scan your IIUM Matric card to instantly verify your identity.
- **Smart Camera UI**: Features a custom overlay, tap-to-focus, flash toggle, and visual guidance.
- **Validation Logic**: Automatically detects valid/invalid cards with helpful error handling and "Retake" options.
- **Secure**: Extracted details (Name, Matric No, Kulliyyah) are verified against student records.

### 🖨️ Print Services
- **Remote Printing**: Upload documents (PDF, Images) directly from your phone.
- **Custom Options**: Select paper size (A4/A3), color/B&W, double-sided, and copy count.
- **Runner Integration**: Request a runner to pick up and deliver your printed documents.

### 🛒 Campus Marketplace & Services
- **Buy & Sell**: A dedicated space for students to trade items securely.
- **Service Listings**: Offer skills like PC repair, tutoring, or barber services.
- **Runner & Express**: Get food delivered or parcels picked up.
- **Transport**: Carpooling and ride-sharing within campus.

### 🔐 Authentication & Profile
- **Flexible Login**: Sign in using Matric Number or Google.
- **Profile Management**: Edit profile details, manage settings, and view digital ID status.
- **Deep Linking**: Support for external links (e.g., `/verify-identity`, `/wallet`).

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Camera**: `camera` package with custom overlays, image compression, and gesture handling.
- **UI/UX**: Premium Glassmorphism design, `flutter_animate` for smooth interactions, Dark/Light mode support.
- **Navigation**: Named routes with Deep Link support (`app_links`).

## 📱 Getting Started

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/uniserve.git
    ```
2.  **Install dependencies**:
    ```bash
    cd mobile_app
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

---
*Built for KitaHack 2026 - Team FeelTheForce*