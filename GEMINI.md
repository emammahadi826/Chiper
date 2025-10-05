# Project Overview

This is a Flutter-based mobile application named "Chiper". It is a multi-purpose tool that helps users with their daily tasks, notes, and calculations. The app uses Firebase for backend services, including authentication, Firestore database, and push notifications.

## Main Technologies

-   **Frontend:** Flutter
-   **Backend:** Firebase (Authentication, Firestore, Cloud Messaging)
-   **Local Storage:** Hive

## Architecture

The application follows a feature-based architecture. The code is organized into folders for each feature, such as `auth`, `calculator`, `memo`, `tasks`, etc. Each feature folder contains the UI (pages/screens) and the business logic (services) for that feature.

The UI is built using the Flutter framework, with the `flutter_screenutil` package for responsive UI design. The state management is done using `Provider`.

The backend is powered by Firebase. Firebase Authentication is used for user login and registration. Firestore is used as the database for storing user data, such as tasks, memos, and calculator history. Firebase Cloud Messaging is used for push notifications.

Hive is used for local storage to cache data and provide offline access.

## Building and Running

To build and run the project, follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/emammahadi826/Chiper.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run
    ```

### Testing

To run the tests, use the following command:
```bash
flutter test
```

## Development Conventions

-   **Code Style:** The project follows the standard Dart and Flutter coding styles.
-   **File Naming:** Files are named using `snake_case`.
-   **UI Design:** The UI is designed to be clean and modern, with a focus on user experience. The `flutter_screenutil` package is used to ensure that the UI is responsive across different screen sizes.
-   **State Management:** The `provider` package is used for state management.
-   **Services:** Business logic is separated from the UI by using service classes. Each feature has its own service class that handles the business logic for that feature.
