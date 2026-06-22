<div align="center">
  <h1>🌟 Peblo AI Story Buddy 🌟</h1>
  <p><strong>An accessible, animated, kid-friendly storytelling and quiz application built with Flutter.</strong></p>
  
  <p>
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
    <a href="https://riverpod.dev/"><img src="https://img.shields.io/badge/Riverpod-000000?style=for-the-badge&logo=dart&logoColor=white" alt="Riverpod" /></a>
    <img src="https://img.shields.io/badge/ElevenLabs-Integration-blueviolet?style=for-the-badge" alt="ElevenLabs" />
  </p>

  <h3>🔗 <a href="https://github.com/binoremohapatra/pebloai">Direct Link to GitHub Repository</a></h3>
</div>

---

## 🎯 Overview

**Peblo AI Story Buddy** is a sophisticated, production-ready Flutter application designed to provide interactive storytelling and educational quizzes for children. 

It demonstrates **advanced Flutter development practices**, seamlessly blending a robust **finite state machine (FSM)** architecture with premium micro-interactions, dynamic AI audio integrations, and strictly enforced **60fps-compliant UI layers**. 

> **Note for Recruiters & Hiring Managers:** 
> This project was built to demonstrate architectural maturity, performance optimization, and the ability to integrate complex third-party APIs into a fluid, user-centric mobile experience. It highlights strong proficiencies in **State Management (Riverpod)**, **Hardware Sensors (Gyroscope)**, **Audio streaming**, and **Custom Animations**.

---

## 🧠 Technical Architecture & State Management

The application is entirely driven by a single, highly predictable **Finite State Machine (FSM)** managed via `StoryBuddyNotifier` (using Riverpod). This ensures flawless synchronization between the asynchronous audio pipeline and the UI events.

**State Flow:**
`Initial` ➔ `LoadingAudio` ➔ `Playing` ➔ `QuizRevealed` ➔ `AnswerCorrect` / `AnswerWrong` ➔ `AudioError` (Fallback)

### ⚡ Performance Optimization
The app is engineered to maintain a strict **60fps** rendering pipeline, even on low-end Android devices (e.g., 3GB RAM):
- **Repaint Boundaries:** High-frequency animations (like custom physics-based confetti, background pulsing blobs, and UI state updates) are aggressively isolated using `RepaintBoundary` to prevent unnecessary widget tree repaints.
- **Selective Rebuilds:** Riverpod Provider states utilize `.select()` to surgically rebuild only the specific widget nodes that require updates, keeping the UI thread unblocked.
- **Const Constructors:** Strict linter rules enforce `prefer_const_constructors` to optimize widget tree diffing and minimize garbage collection overhead.

---

## 🌟 Key Features

### 🎨 Premium Interactive UI
- **Gyroscope Parallax (Faux-3D):** The background and foreground respond dynamically to device tilt using the `sensors_plus` package, creating an immersive, faux-3D depth effect.
- **Contextual Dynamic Mascot:** The main character ("Pip") is pinned securely at the top of the screen and animates contextually based on the active state of the story (e.g., talking, happy, sad).
- **Typewriter Text Effect:** Story text and quiz questions type out dynamically on the screen, mathematically synced with the Text-to-Speech (TTS) audio engine.
- **Responsive & Safe Layouts:** A smart, adaptive UI structure ensures the mascot remains permanently visible while allowing child content (Story Cards, Quizzes) to scroll gracefully underneath, preventing overflow exceptions across various screen dimensions.
- **Custom Physics-based Confetti:** Correct answers trigger a custom-tuned, hardware-accelerated confetti blast that rains down from the top of the screen to celebrate user success.

### 🔊 Audio & AI Text-to-Speech (TTS)
- **ElevenLabs AI Voice Integration:** The app implements a custom `ElevenLabsTtsService` powered by the `http` and `audioplayers` packages. It streams ultra-realistic, human-like AI voices (e.g., "Teacher Ella") directly to the device with minimal latency.
- **Resilient Native Fallback System:** A robust `FlutterTtsService` is maintained as a fallback mechanism to ensure offline or API-limit resiliency. It is explicitly tuned with `setSpeechRate(0.4)` and `setPitch(1.6)` to mimic a cute, engaging character voice.
- **Strict FSM Audio Sync:** Audio completion events are strictly wired to the Riverpod FSM, guaranteeing that the Quiz UI is only revealed *after* the TTS engine completely finishes narrating the story.

---

## 🛠️ Tech Stack

- **Framework:** Flutter (`>=3.19.0`)
- **Language:** Dart (`>=3.3.0`)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Hardware Integration:** `sensors_plus` (Gyroscope/Accelerometer)
- **Audio Processing:** `audioplayers`, `flutter_tts`
- **Networking:** `http` (REST API integration)
- **Animation:** `confetti`, Implicit/Explicit Flutter Animations

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (`>=3.19.0`)
- Dart SDK (`>=3.3.0`)

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/binoremohapatra/pebloai.git
   cd pebloai
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys (Important):**
   To utilize the premium ElevenLabs AI voice features, you must provide a valid API key. Navigate to `lib/infrastructure/tts/eleven_labs_tts_service.dart` and update the key:
   ```dart
   static const String _apiKey = 'YOUR_ELEVENLABS_API_KEY';
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

---
<div align="center">
  <i>Built with ❤️ using Flutter.</i>
</div>
