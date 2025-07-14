# Carbonize App

A mobile application designed to help users calculate, track, and reduce their carbon footprint. Carbonize App empowers users to make environmentally conscious decisions by providing detailed insights into their daily carbon emissions from food consumption and transportation.

![Carbonize App Logo](assets/images/carbonize_logo.png)

## Features

- **User Authentication**: Secure login and registration system
- **Daily Carbon Footprint Tracking**: Monitor your daily emissions
- **Multiple Emission Categories**:
  - Food & Packaging Consumption
  - Fuel Consumption (private vehicles and public transport)
- **Visual Analytics**: View your emissions through interactive charts and graphs
- **Monthly & Yearly Statistics**: Track your progress over time
- **Personalized Recommendations**: Get tailored tips to reduce your carbon footprint
- **Image Documentation**: Upload photos to document your consumption activities
- **Customizable Settings**: Set your daily carbon emission limits

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Firebase account
- Climatiq API key

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/daffaabdillahsyah/CarbonizeApp.git
   ```

2. Navigate to the project directory:
   ```
   cd carbonize_app
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Configure Firebase:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Enable Storage
   - Download and replace the `google-services.json` file in the `android/app` directory
   - Update the API key in `android/app/google-services.json`

5. Configure Climatiq API:
   - Register for an API key at [Climatiq](https://www.climatiq.io/)
   - Replace the placeholder in `lib/services/emission_service.dart`:
     ```dart
     static const String _apiKey = 'YOUR_API_KEY';
     ```

6. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                  # Application entry point
├── screens/                   # UI screens
│   ├── calculator_screen.dart # Carbon calculation screen
│   ├── home_screen.dart       # Dashboard
│   ├── login_screen.dart      # Authentication
│   └── ...
├── services/                  # Business logic
│   ├── auth_service.dart      # Authentication service
│   ├── emission_service.dart  # Carbon emission calculations
│   └── user_service.dart      # User data management
├── utils/                     # Utilities
│   └── constants.dart         # App constants
└── widgets/                   # Reusable UI components
    └── ...
```

## Firebase Collections

The app uses the following Firestore collections:

- `users`: User profiles and settings
- `consumption_entries`: User's carbon footprint entries
- `emission_factors`: Reference data for emission calculations

## Usage

1. **Registration/Login**: Create an account or log in with existing credentials
2. **Home Screen**: View your current carbon footprint status
3. **Calculator**: Log new consumption activities
   - Select category (Food & Packaging or Fuel Consumption)
   - Enter required details
   - Upload a photo for documentation
   - Calculate emissions
4. **View Statistics**: Track your progress on monthly and yearly basis
5. **Profile**: Manage your account settings

## Data Privacy

The application stores:
- User authentication data
- Carbon footprint entries
- Images uploaded by users

All data is securely stored in Firebase and is only accessible to the respective user.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [Climatiq API](https://www.climatiq.io/)
