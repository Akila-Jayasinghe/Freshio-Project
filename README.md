# 🍎 Freshio: AI-Powered Fruit & Vegetable Quality Inspector

![Version](https://img.shields.io/badge/Version-2.1.0-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Phase%202%20Complete-success?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow%20Lite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)

**Freshio** is an intelligent mobile solution developed to help consumers assess the freshness and edibility of produce objectively. Created for the **Digital Image Processing** course at **General Sir John Kotelawala Defence University**.

---

## 🚀 Project Vision

The primary goal of Freshio is to provide a seamless, AI-driven interface for fruit and vegetable inspection. We have evolved from a simple scanner to a robust, **Offline-First** data collection tool.

<p align="center">
  <img src="Doc%20res/img_0001.jpg" width="600" alt="Freshio Conceptual Design">
  <br>
  <i>Figure 1: Conceptual UI/UX Design for the Freshio Scanner</i>
</p>

### ✨ New in v2.1 Features
* **Offline-First Architecture:** Inspect fruits without internet. Results are stored locally (SQLite) and auto-synced when online.
* **Hybrid Cloud Backend:**
    * **Images:** Securely uploaded to **Cloudinary**.
    * **Metadata:** Synced to **Firebase Firestore** for real-time analytics.
* **Smart Redundancy Check:** The system prevents unnecessary data uploads if the AI's prediction matches the user's feedback, saving bandwidth and storage.
* **Enhanced ML Pipeline:** Implements a strict **Center Crop → Resize (224px) → Normalize** pipeline to prevent image distortion and ensure high-accuracy inference.
* **Modern UX:**
    * **Stacked Toast Notifications:** Non-intrusive, top-aligned status updates.
    * **Zoom-to-Fill Camera:** Distortion-free camera preview on tall aspect-ratio devices.

---

## 🛠️ The Problem & Technical Solution

### The Challenge
As shown in our research phase (**Figure 2**), manual fruit inspection is often unhygienic and highly subjective. Consumers frequently struggle to identify internal rot from external surface patterns.

<p align="center">
  <img src="Doc%20res/img_0002.jpg" width="500" alt="Problem Analysis">
  <br>
  <i>Figure 2: Analysis of manual produce inspection challenges</i>
</p>

### High-Level Architecture (Store-and-Forward)
The system follows a sophisticated pipeline from data acquisition to mobile deployment. Our updated architecture bridges the gap between Python-based AI training and Flutter-based mobile execution with a **Bi-Directional Sync Service**.

<p align="center">
  <img src="Doc%20res/img_0003.png" width="800" alt="System Architecture">
  <br>
  <i>Figure 3: Freshio High-Level Architecture</i>
</p>

---

## 📂 Project Structure

```text
Freshio-Project/
├── app/                      # Flutter Mobile Application source code
│   ├── assets/               # ML Models (.tflite) and UI assets
│   ├── lib/
│   │   ├── services/         # SyncService (Cloudinary + Firebase) & MLService
│   │   ├── utils/            # ToastUtils & ImageUtils
│   │   ├── widgets/          # FeedbackSheet & Camera Overlay
│   │   └── main.dart         # App Entry Point
├── Doc res/                  # Documentation resources and diagrams
├── notebooks/                # Python scripts for training
└── MATLAB/                   # Digital Image Processing validation scripts

```

## 🔧 Installation & Setup

1. **Clone the Repository:**
```bash
git clone https://github.com/Akila-Jayasinghe/Freshio-Project.git

```


2. **Get Packages:**
```bash
cd app
flutter pub get

```


3. **Run on Device (Release Mode recommended):**
```bash
flutter run --release

```


*Note: Internet permission is required for the initial sync feature.*

---

## 📈 Roadmap

* [x] **Phase 1:** MVP - Real-time camera classification for Apples, Bananas, and Oranges.
* [x] **Phase 2:** Implementation of **SQLite** local sync (Store-and-Forward) with Cloudinary & Firebase.
* [ ] **Phase 3:** Advanced texture analysis using **MATLAB** DIP toolboxes for internal spoilage detection.
* [ ] **Phase 4:** Data Visualization (Charts) & Dataset expansion for Sri Lankan specific vegetables.

---

## 👥 Contributors

* **V. P. A. Jayasinghe**
* **H. T. I. Geekiyanage**

---

Developed as a project in Digital Image Processing at the Faculty of Computing,
<br>General Sir John Kotelawala Defence University.