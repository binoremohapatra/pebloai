# Peblo AI Story Buddy

Peblo AI Story Buddy is an accessible, animated, kid-friendly storytelling and quiz application built with Flutter. It combines a robust finite state machine (FSM) with premium micro-interactions, dynamic audio integrations, and 60fps-compliant UI layers.

## 🌟 Key Features

### Premium Interactive UI
- **Gyroscope Parallax**: The background and foreground respond to device tilt using `sensors_plus`, creating a faux-3D depth effect.
- **Dynamic Mascot**: The main character (Pip) is pinned at the top of the screen and animates contextually based on the story state.
- **Typewriter Text Effect**: The story and quiz questions type out dynamically on the screen in sync with the Text-to-Speech audio engine.
- **Responsive Layout**: A smart UI structure keeps the mascot permanently visible while allowing child content (Story Cards, Quizzes) to scroll gracefully underneath to prevent overflow on smaller devices.
- **Celebratory Confetti**: Correct answers trigger a custom-tuned, physics-based confetti blast that rains down from the top of the screen.

### Audio & Text-to-Speech (TTS)
- **ElevenLabs Integration**: The app uses a custom `ElevenLabsTtsService` powered by the `http` and `audioplayers` packages to stream ultra-realistic, human-like AI voices (e.g., "Teacher Ella") directly to the device.
- **Native Fallback Tuning**: A robust `FlutterTtsService` is maintained as a fallback, explicitly tuned with `setSpeechRate(0.4)` and `setPitch(1.6)` to sound like a cute character.
- **FSM Synchronisation**: Audio completion is strictly wired to the Riverpod FSM, ensuring the Quiz is only revealed *after* the TTS engine finishes reading the story.

### State Management (Riverpod)
The app is entirely driven by a single Finite State Machine (`StoryBuddyNotifier`), ensuring predictable transitions and flawless synchronization between the audio pipeline and UI events. The valid states include:
- `Initial`
- `LoadingAudio`
- `Playing`
- `QuizRevealed`
- `AnswerCorrect`
- `AnswerWrong`
- `AudioError`

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.19.0`
- Dart SDK `>=3.3.0`

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies (including `riverpod`, `confetti`, `audioplayers`, `sensors_plus`, `http`, etc.).
3. **Important**: To use the premium voice features, update the API key in `lib/infrastructure/tts/eleven_labs_tts_service.dart`:
   ```dart
   static const String _apiKey = 'YOUR_ELEVENLABS_API_KEY';
   ```
4. Run the app: `flutter run`

## 🛠️ Performance Architecture
This app is designed to run at a strict 60fps, even on low-end Android devices with 3GB RAM. 
- High-frequency animations (confetti, background pulsing blobs, UI state updates) are aggressively isolated using `RepaintBoundary`.
- Provider states use `select()` to only rebuild specific widget nodes when strictly necessary.
- Linter rules enforce `prefer_const_constructors` to optimize widget tree diffing.
