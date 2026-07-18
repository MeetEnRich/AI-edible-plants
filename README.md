# FloraID Nigeria 🌿

An offline-first, AI-powered mobile application designed to safely identify, catalog, and provide indigenous knowledge on Nigerian edible plants. Built with Flutter, Firebase, and Gemini Multimodal AI.

## 🌟 Key Features

- **Intelligent Identification**: Uses the **Gemini 2.5 Flash** multimodal AI to identify plants from camera or gallery images, prioritizing Nigerian and West African flora.
- **Explainable AI (XAI)**: Doesn't just give you a name—it provides detailed reasoning (analyzing leaf shape, venation, texture) to explain _why_ it made that identification.
- **Safety First**: Highlights toxic look-alikes, edibility status, and required traditional preparation methods to ensure safe foraging.
- **Indigenous Knowledge Base**: Integrates local names (Igbo, Hausa, Yoruba) and traditional recipes/preparation methods seeded directly into the app.
- **Offline-First Architecture**: Powered by a robust local **SQLite** database. You can scan plants deep in the forest without internet access; the app seamlessly queues them for verification.
- **Interactive OpenStreetMap Integration**: Automatically captures precise GPS coordinates when a plant is scanned and visualizes them on an interactive map using `flutter_map` (zero API keys required, perfect for offline/field scaling).
- **Cloud Synchronization**: Once back online, the app automatically verifies pending offline scans via Gemini, uploads images to **ImgBB**, and securely backs up your personal Herbarium to **Firebase Cloud Firestore**.
- **Premium UI/UX**: Designed with a sleek, emerald-gradient aesthetic, smooth micro-animations, seamless **Hero image transitions**, and glassmorphism cards for a truly modern feel.

## 🛠 Tech Stack

- **Frontend**: Flutter / Dart
- **Local Database**: `sqflite`
- **Cloud Database**: Firebase Cloud Firestore
- **Authentication**: Firebase Authentication (Email/Password)
- **AI Engine**: Google Generative AI (`google_generative_ai`)
- **Image Caching**: `cached_network_image` for robust offline image viewing
- **Image Hosting**: ImgBB API
- **State Management**: Provider (`ChangeNotifierProvider`, `ChangeNotifierProxyProvider`)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.10+)
- A Firebase Project with Firestore & Authentication (Email/Password) enabled.
- A [Google AI Studio](https://aistudio.google.com/) API Key (for Gemini).
- An [ImgBB](https://api.imgbb.com/) API Key.

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/MeetEnRich/AI-edible-plants.git
   cd AI-edible-plants
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   Ensure you have the Firebase CLI installed, then run:

   ```bash
   flutterfire configure
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## ⚙️ Configuration

Upon launching the app for the first time, navigate to the **Settings** page to input your **Gemini API Key** and **ImgBB API Key**. These are stored securely on the device using `shared_preferences` and are required for the AI identification and cloud image backup features to function.

## 🛡️ Disclaimer

_This application is an educational aid and does not replace professional botanical identification. Always exercise extreme caution and consult local experts before consuming wild plants._
