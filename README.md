# Book Management App

A responsive Flutter book management application for mobile and web. The app supports user and admin roles, stores app data in Firebase Firestore, and adapts layouts for small mobile screens as well as wider browser windows.

## Features

- User login and registration with role selection
- Admin dashboard with book, user, and report management
- Browse, search, filter, sort, borrow, and return books
- User profile with borrowed book summary
- Firestore-backed `users` and `books` collections
- Responsive UI for Android, iOS, and web
- Riverpod state management and GoRouter navigation

## Tech Stack

- Flutter
- Firebase Core
- Cloud Firestore
- Flutter Riverpod
- GoRouter
- Flutter ScreenUtil
- Google Fonts

## Demo Accounts

The app seeds default users into Firestore when the `users` collection is empty.

| Role | Username | Password |
| --- | --- | --- |
| Admin | `admin` | `admin123` |
| User | `user` | `user123` |

## Firestore Data

The app uses these Firestore collections:

- `users`: user accounts, roles, and borrowed book IDs
- `books`: book records, availability, borrower ID, and borrow date

Make sure your Firebase project has Cloud Firestore enabled. For development, your Firestore security rules must allow the app to read and write the required collections.

## Getting Started

Install dependencies:

```bash
flutter pub get
```

Run on a connected device or emulator:

```bash
flutter run
```

Run on web:

```bash
flutter run -d chrome
```

Build for web:

```bash
flutter build web
```

## Firebase Setup

Firebase is initialized in `lib/main.dart` using `lib/firebase_options.dart`.

If you create a new Firebase project, regenerate the options file with FlutterFire CLI:

```bash
flutterfire configure
```

Then enable Cloud Firestore in the Firebase console.

## Verification

Run static analysis:

```bash
flutter analyze
```

Build web to verify browser support:

```bash
flutter build web
```

## Project Structure

```text
lib/
  models/        Book and user models
  providers/     Auth, books, and users state with Firestore access
  screens/       Auth, user, and admin screens
  utils/         App routes, constants, theme, Firebase options
  widgets/       Shared UI widgets
```
