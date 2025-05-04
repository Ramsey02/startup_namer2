# Startup Name Generator

A Flutter application that generates random startup names, allows users to favorite names they like, and synchronizes these favorites across devices using Firebase.

## Features

### Authentication
- **User Login**: Users can log in with email and password
- **User Registration**: New users can sign up with email and password
- **User Status**: The app shows different UI based on authentication status
- **User Logout**: Users can log out with a single tap

### Favorites Management
- **Save Favorites**: Users can save startup names they like by tapping the heart icon
- **View Favorites**: Users can view all their saved favorites in a dedicated screen
- **Delete Favorites**: Users can delete favorites by swiping and confirming deletion
- **Cross-device Sync**: Favorites are synchronized across devices when logged in

### Cloud Integration
- **Firebase Authentication**: Secure user authentication
- **Cloud Firestore**: Store and sync user favorites
- **State Management**: Proper state management using Provider

## Implementation Details

### Authentication Flow
- When a user is logged out, they can browse and temporarily save favorites locally
- When a user logs in, their local favorites are merged with their cloud-stored favorites
- When a user logs out, favorites are cleared from local storage

### State Management
- Uses Provider package for efficient state management
- Separate notifiers for authentication and favorites management
- Real-time UI updates based on authentication and favorites state changes

### Data Structure
- Favorites are stored in Firestore in the following structure:
  ```
  users/{user_id}/favorites/{wordpair_id}
  ```
- Each favorite contains the first and second parts of the word pair and a timestamp

## Technical Architecture

The application uses:
- **Flutter**: For cross-platform UI development
- **Firebase Authentication**: For user management
- **Cloud Firestore**: For data storage and synchronization
- **Provider**: For state management across the application

## Getting Started

### Prerequisites
- Flutter SDK
- Firebase account
- Android Studio or VS Code with Flutter plugin

### Setup
1. Clone the repository
2. Create a Firebase project and add your Android app
3. Download the `google-services.json` file and place it in the `android/app` directory
4. Run `flutter pub get` to install dependencies
5. Run `flutter run` to launch the application

### Firebase Configuration
Ensure your Firestore security rules are properly configured:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Acknowledgments
- This project was created as part of Technion's Project in Android Development course
- Based on the Flutter codelab with extended functionality
