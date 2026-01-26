# 🍎 Freshio: AI-Powered Fruit & Vegetable Quality Inspector

![Freshio Banner](https://img.shields.io/badge/Status-Progress%20Phase%201-green?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![TensorFlow](https://img.shields.io/badge/TensorFlow%20Lite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)

**Freshio** is an intelligent mobile solution developed to help consumers assess the freshness and edibility of produce objectively. Created for the **Digital Image Processing** course at **General Sir John Kotelawala Defence University**.

---

## 🚀 Project Vision

The primary goal of Freshio is to provide a seamless, AI-driven interface for fruit and vegetable inspection, as illustrated in our conceptual design:

<p align="center">
  <img src="Doc%20res/img_0001.jpg" width="600" alt="Freshio Conceptual Design">
  <br>
  <i>Figure 1: Conceptual UI/UX Design for the Freshio Scanner</i>
</p>

### ✨ Key Features
* **Real-time Detection:** Instant classification using the device camera.
* **Modern UI:** Sleek glassmorphic scanner interface.
* **Privacy & Offline-First:** All AI inference happens locally on the phone.

---

## 🛠️ The Problem & Technical Solution

### The Challenge
As shown in our research phase (**Figure 2**), manual fruit inspection is often unhygienic and highly subjective. Consumers frequently struggle to identify internal rot from external surface patterns.

<p align="center">
  <img src="Doc%20res/img_0002.jpg" width="500" alt="Problem Analysis">
  <br>
  <i>Figure 2: Analysis of manual produce inspection challenges</i>
</p>

### High-Level Architecture
The system follows a sophisticated pipeline from data acquisition to mobile deployment. Our architecture (shown in **Figure 3**) bridges the gap between Python-based AI training and Flutter-based mobile execution.

<p align="center">
  <img src="Doc%20res/img_0003.png" width="800" alt="System Architecture">
  <br>
  <i>Figure 3: Freshio High-Level System Architecture</i>
</p>

---

## 📂 Project Structure

```text
Freshio-Project/
├── app/                  # Flutter Mobile Application source code
│   ├── assets/           # ML Models (.tflite) and UI assets
│   ├── lib/              # Dart files (UI, Services, Logic)
├── Doc res/              # Documentation resources and diagrams
├── notebooks/            # Python scripts for training
└── MATLAB/               # Digital Image Processing validation scripts

```

---

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


3. **Run on Device:**
```bash
flutter run --release

```


---

## 📈 Roadmap

* [x] **Phase 1:** MVP - Real-time camera classification for Apples, Bananas, and Oranges.
* [ ] **Phase 2:** Implementation of **SQLite** local sync for the store-and-forward mechanism.
* [ ] **Phase 3:** Advanced texture analysis using **MATLAB** DIP toolboxes for internal spoilage detection.
* [ ] **Phase 4:** Dataset expansion for Sri Lankan specific vegetables (Carrots, Tomatoes).

---

## 👥 Contributors

* **H. T. I. Geekiyanage**
* **V. P. A. Jayasinghe**

---

Developed as a project in Digital Image Processing at the Faculty of Computing,
<br>General Sir John Kotelawala Defence University.