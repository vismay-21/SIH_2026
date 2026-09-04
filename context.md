# SIH 2026 Project Context

## Current State

The repository is the SIH 2026 Cooperative Gig Services Platform project. The Flutter application is inside `mobile_app/`. The repository also contains the root-level project areas `backend/` and `docs/`; both are currently empty apart from `.gitkeep` files used to keep the directories visible in Git.

The current implementation is an initial frontend structure and navigation skeleton. It uses only Flutter's existing dependencies. No additional dependencies were added for this work.

## Repository Structure

```text
SIH_2026/
├── backend/
│   └── .gitkeep
├── docs/
│   └── .gitkeep
└── mobile_app/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   │   ├── common/
    │   │   │   ├── .gitkeep
    │   │   │   ├── role_selection_screen.dart
    │   │   │   └── splash_screen.dart
    │   │   ├── customer/
    │   │   │   ├── .gitkeep
    │   │   │   ├── customer_login_screen.dart
    │   │   │   ├── customer_main_screen.dart
    │   │   │   ├── customer_register_screen.dart
    │   │   │   ├── home/
    │   │   │   │   └── customer_home_screen.dart
    │   │   │   ├── navigation_2/
    │   │   │   │   └── customer_navigation_2_screen.dart
    │   │   │   ├── navigation_3/
    │   │   │   │   └── customer_navigation_3_screen.dart
    │   │   │   └── navigation_4/
    │   │   │       └── customer_navigation_4_screen.dart
    │   │   └── worker/
    │   │       ├── .gitkeep
    │   │       ├── worker_login_screen.dart
    │   │       ├── worker_main_screen.dart
    │   │       ├── worker_register_screen.dart
    │   │       ├── home/
    │   │       │   └── worker_home_screen.dart
    │   │       ├── navigation_2/
    │   │       │   └── worker_navigation_2_screen.dart
    │   │       ├── navigation_3/
    │   │       │   └── worker_navigation_3_screen.dart
    │   │       └── navigation_4/
    │   │           └── worker_navigation_4_screen.dart
    │   ├── widgets/
    │   │   └── common/
    │   │       └── .gitkeep
    │   ├── theme/
    │   │   └── .gitkeep
    │   ├── localization/
    │   │   └── .gitkeep
    │   ├── models/
    │   │   └── .gitkeep
    │   ├── services/
    │   │   └── .gitkeep
    │   ├── repositories/
    │   │   └── .gitkeep
    │   └── providers/
    │       └── .gitkeep
    └── test/
        └── widget_test.dart
```

## Frontend Folders and Files

`mobile_app/lib/main.dart` remains at its original location. It contains the Flutter app entry point and starts the application at `SplashScreen`. It does not contain product feature logic.

The common screens are shared entry screens:

- `splash_screen.dart` displays a minimal placeholder and continues to role selection.
- `role_selection_screen.dart` lets the user select Customer or Worker.

The customer screens are separated under `screens/customer/`:

- `customer_login_screen.dart` provides placeholder login navigation to the Customer main screen and a link to registration.
- `customer_register_screen.dart` provides placeholder registration completion and returns to Customer Login.
- `customer_main_screen.dart` owns the four-item Customer bottom navigation.
- `home/` contains `customer_home_screen.dart`, the default Customer destination.
- `navigation_2/`, `navigation_3/`, and `navigation_4/` each contain their corresponding placeholder destination screen.

The worker screens are separated under `screens/worker/`:

- `worker_login_screen.dart` provides placeholder login navigation to the Worker main screen and a link to registration.
- `worker_register_screen.dart` provides placeholder registration completion and returns to Worker Login.
- `worker_main_screen.dart` owns the four-item Worker bottom navigation.
- `home/` contains `worker_home_screen.dart`, the default Worker destination.
- `navigation_2/`, `navigation_3/`, and `navigation_4/` each contain their corresponding placeholder destination screen.

Each Customer and Worker bottom-navigation destination has its own folder. This is the current folder convention for keeping each destination separate as it grows. Only one placeholder screen file exists in each destination folder at present.

The remaining frontend folders are structural areas only:

- `widgets/common/` is reserved for shared widgets; it currently contains only `.gitkeep`.
- `theme/` is reserved for theme code; no application theme implementation has been added.
- `localization/` is reserved for localization code; no localization implementation has been added.
- `models/` is reserved for data models; no models have been added.
- `services/` is reserved for service implementations; no services have been added.
- `repositories/` is reserved for repository implementations; no repositories have been added.
- `providers/` is reserved for state/provider code; no provider framework or implementation has been added.

The `test/` folder contains `widget_test.dart`. It currently verifies the placeholder Customer flow, Customer registration return, Worker registration return, Worker flow, and access to the bottom-navigation destinations. There is no backend test or implementation.

## Current Navigation Flow

The application currently follows this placeholder flow:

```text
Splash
  ↓
Role Selection
  ├── Customer
  │     ↓
  │   Customer Login
  │     ├── Register → Customer Login
  │     └── Login → Customer Main
  │                    ├── Home
  │                    ├── Navigation 2
  │                    ├── Navigation 3
  │                    └── Navigation 4
  │
  └── Worker
        ↓
      Worker Login
        ├── Register → Worker Login
        └── Login → Worker Main
                       ├── Home
                       ├── Navigation 2
                       ├── Navigation 3
                       └── Navigation 4
```

Home is selected by default when either role's main screen opens. Registration returns to the respective login screen. Login is only a placeholder action that demonstrates navigation; it is not real authentication.

## Scope Boundaries

The current UI is only a simple navigation and structure skeleton. Real backend functionality, authentication, database functionality, algorithms, API integration, Riverpod, Dio, localization, themes, and product features have not been implemented. No mock data or additional dependencies were added for this work. The root-level `backend/` and `docs/` areas remain empty project areas, and no backend or unrelated functionality was modified during the navigation implementation.

The documented state describes the current implementation only. It does not define future architecture or features.