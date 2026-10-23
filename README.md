# CareWatch – iOS Application

CareWatch is an iPhone application designed to help older adults who live alone manage their daily routines and medication. It also allows them to record daily check-ins, view their activity information, and quickly contact a trusted person when they need help.

The main idea behind CareWatch is to bring these features together in one simple application. The interface is designed to be easy to understand, with clear sections for daily tasks, reminders, activity and care history.

**Student:** K H J S D Fernando  
**Student ID:** COBSCCOMP251P-068  
**Figma Design:** [View the CareWatch design](https://www.figma.com/design/EReDQWnIP1lksGaC3mNjKu/CareWatch-%E2%80%94-iOS-Mobile-App-Layout)

---

## Features and implementation status

The following table shows the main features planned for CareWatch and their current implementation status.

| No. | Feature | Status | Description |
|---|---|---|---|
| 1 | Authentication and onboarding | Completed | Welcome screen, sign-in, account creation and three-step onboarding |
| 2 | Settings and profile | Completed | Profile details, security options and app settings |
| 3 | Today dashboard | Completed | Daily status, upcoming reminder, step count and emergency shortcut |
| 4 | Account and messaging integration | Partially completed | Firebase Authentication is implemented, but cloud messaging is not |
| 5 | Notifications | Completed | Local notifications for medication and routine reminders |
| 6 | Face ID | Completed | Optional app lock with password fallback |
| 7 | Routine and contact management | Completed | Add, edit and delete routines, and update the emergency contact |
| 8 | Check-in and medication reminders | Completed | Record an “I'm okay” check-in and mark medication as taken or undo it |
| 9 | Activity and history | Completed | Activity information, daily history and weekly summary |
| 10 | Health activity summary | Completed | HealthKit steps, walking distance, active time and an hourly chart |
| 11 | Movement confirmation | completed | Done |
| 12 | Home Screen widget | completed | Done |
| 13 | Home location check-in | completed | Done |

## Technologies used

CareWatch was developed using Swift and SwiftUI in Xcode. Different Apple frameworks and supporting tools were used to implement the main features.

| Technology | How it is used |
|---|---|
| Swift and SwiftUI | Building the user interface and application logic |
| Xcode | Developing and testing the iOS application |
| Core Data | Saving profiles, routines, contacts, check-ins and history locally |
| Firebase Authentication | Account creation, sign-in, password reset and sign-out |
| UserNotifications | Scheduling medication and routine reminders |
| LocalAuthentication | Providing optional Face ID protection |
| HealthKit | Reading step count, walking distance and active time |
| Swift Charts | Displaying hourly activity information |
| Git and GitHub | Managing code changes, feature branches and merges |

## Application structure

CareWatch follows an MVVM-style structure to keep the code organised and make the different parts of the application easier to maintain.

The project is divided into a few main areas:

- **App:** Contains the main application entry point and root navigation.
- **Core:** Contains the app's colour theme and reusable interface components.
- **Features:** Contains the screens and related logic for authentication, onboarding, routines, activity, check-ins, history, emergency contacts and settings.
- **Persistence:** Handles the Core Data model and local data storage.
- **Services:** Contains the code responsible for authentication, notifications, HealthKit and Face ID.

The `RootView` controls which part of the app is displayed. For example, a signed-out user sees the welcome screen, while a user who has signed in but has not completed onboarding is taken to the onboarding screens. If Face ID protection is enabled and the app is locked, the lock screen is displayed. Otherwise, the main five-tab interface is shown.

The main tabs are Today, Routines, Activity, Check-in and History.

### Project folder structure

```text
CareWatch/
├── App/
│   ├── CareWatchApp
│   ├── RootView
│   └── MainTabView
├── Core/
│   ├── Theme
│   └── Reusable Components
├── Features/
│   ├── Authentication
│   ├── Onboarding
│   ├── Today
│   ├── Routines
│   ├── Activity
│   ├── CheckIn
│   ├── History
│   ├── Emergency
│   ├── Settings
│   └── Lock
├── Persistence/
│   ├── Core Data Model
│   ├── PersistenceController
│   ├── Helpers
│   └── Sample Data
└── Services/
    ├── AuthService
    ├── ReminderService
    ├── HealthService
    ├── BiometricService
    └── NotificationDelegate
```

## Core Data design

Core Data is used to store the main care-related information on the iPhone. This means the app can access saved routines and previous records without needing a cloud database.

The main entities are:

| Entity | Purpose |
|---|---|
| `UserProfile` | Stores the user's profile details and Firebase user ID |
| `Routine` | Stores routine details, categories, scheduled times and repeat days |
| `RoutineLog` | Records whether a routine or medication dose was completed |
| `CareContact` | Stores the emergency contact details |
| `CheckIn` | Records “I'm okay” check-ins |
| `CareEvent` | Stores events displayed in the care history |
| `HomeLocation` | Prepared for the planned home location feature |

Medication is managed as a routine with the category set to `medication`. The routine schedule is stored separately from its daily completion records. This helps the app keep previous records even when the user changes a routine later.

## Privacy and data storage

Privacy was an important consideration during the development of CareWatch, particularly because the app handles personal routines, medication records and emergency contact details.

- Personal care records are stored locally on the iPhone using Core Data.
- Firebase Authentication is used for account management. The project does not use Firestore or another cloud database for care records.
- HealthKit is used only to read activity information. The app does not upload this information to a cloud service.
- Permissions are requested when the relevant feature is first used, with an explanation of why access is needed.
- The emergency call feature asks the user for confirmation before starting a call. The app does not automatically contact anyone or declare an emergency.

## How to run the project

### Requirements

- Xcode 26 or later
- An iOS 26.5 Simulator, such as an iPhone 17 Pro simulator
- An internet connection for the initial Firebase package download and account authentication

### Setup steps

1. Clone the CareWatch repository from GitHub.
2. Open `CareWatch.xcodeproj` in Xcode.
3. Wait for Swift Package Manager to download the Firebase dependencies.
4. Select an iPhone simulator from the device menu.
5. Press **⌘R** to build and run the application.
6. Create an account from the welcome screen or use the configured demo account if it is available.

The project includes a `GoogleService-Info.plist` file containing Firebase project configuration. This file identifies the Firebase project, but it does not contain the user's account password.

**Demo account:** `test@carewatch.dev` / `123456`

Use the demo account only if it has been configured and remains available in the connected Firebase project.

### Testing in the iOS Simulator

Some features require additional setup before they can be tested.

- **Face ID:** Open the Simulator menu, select Features, then Face ID, and choose Enrolled. Use Matching Face or Non-matching Face to test the authentication flow.
- **HealthKit:** Add sample step data in the Health app under Browse → Activity → Steps. Then refresh the activity screen in CareWatch.
- **Notifications:** Create a reminder scheduled a few minutes ahead and check whether the notification appears. The app also handles notifications while it is open.
- **Emergency call:** The Simulator cannot place a normal phone call. The app displays an explanation instead. On a supported physical iPhone, the call can begin after the user confirms the action.

## Git and version control

Git and GitHub were used to manage the project during development. The work was divided into feature branches so that related changes could be developed and reviewed separately.

The main branches were used as follows:

- `main` holds the stable version intended for submission.
- `develop` is used to bring completed features together.
- Feature branches were created for areas such as the app foundation, Core Data, authentication, routines and reminders, check-ins and history, and activity and HealthKit.

The feature branches were merged into `develop` using pull requests and merge commits. This keeps the development history visible and makes it easier to follow how the application was built.

## Limitations and future improvements

Some of the proposed features could not be completed within the available development time. They remain possible improvements for a future version of CareWatch.

### 1. Firebase Cloud Messaging

Firebase Authentication is implemented, but remote push notifications are not. Setting up remote notifications requires additional Firebase and Apple Push Notification service configuration. The current development setup also has limitations related to the Apple Developer account and device provisioning.

For now, CareWatch uses local notifications for medication and routine reminders. These can be scheduled on the device without relying on a cloud messaging service.

### 2. Movement confirmation

The movement confirmation feature was not completed. It would require additional work with Core Motion and testing on a suitable physical device. This feature could be developed further to help confirm movement during daily activities.

### 3. Home Screen widget

The Home Screen widget was not implemented in the current version. Its design is included in the Figma file, and it could be added in a future update using WidgetKit.

### 4. Home location check-in

The home location check-in feature was not completed. The `HomeLocation` Core Data entity has been prepared, and the screen design is available in Figma. Further development would be required to implement and test the location functionality.

### 5. Physical device testing

The application was developed and tested using the iOS Simulator. Running it on a physical iPhone requires connecting the device to Xcode and completing the required signing and provisioning setup.

## Conclusion

CareWatch brings together daily routines, medication reminders, check-ins, activity information and care history in one iOS application. The current version includes local data storage, account authentication, Face ID protection, local notifications and HealthKit integration.

Although some proposed features remain unfinished, the implemented features provide the foundation for the application. Further work could focus on movement confirmation, the Home Screen widget and home location check-ins.

The project also provided practical experience with SwiftUI, Core Data, Firebase Authentication, Apple frameworks and Git-based development.
