# MyGooners - Flutter Mobile App

Flutter mobile application for MyGooners ecommerce platform.

## Features Implemented

### ✅ Login Page
- Email and password authentication
- Remember me functionality
- Forgot password link
- Google login button (UI ready, needs backend integration)
- Form validation
- Error handling and display
- Matches web design with red color scheme

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   ├── login_page.dart      # Login screen
│   ├── register_page.dart   # Register screen (placeholder)
│   └── forgot_password_page.dart # Forgot password screen (placeholder)
├── services/
│   └── auth_service.dart    # Authentication API service
└── models/
    └── user.dart            # User model
```

## Setup Instructions

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Configure API Base URL**
   - Open `lib/services/auth_service.dart`
   - Update the `baseUrl` constant with your actual API endpoint:
   ```dart
   static const String baseUrl = 'https://your-api-domain.com/api';
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

## Next Steps

- [ ] Update API base URL in `auth_service.dart`
- [ ] Implement Google Sign-In integration
- [ ] Create home page after successful login
- [ ] Implement register page
- [ ] Implement forgot password page
- [ ] Add navigation guards/authentication state management
- [ ] Add loading states and better error handling

## Dependencies

- `http`: For API calls
- `shared_preferences`: For storing user credentials and tokens
- `flutter_form_builder`: For form validation (optional, can be removed if not needed)
- `form_builder_validators`: For form validation (optional)

## Notes

- The login page matches the web design with red (#DC2626) as the primary color
- All text is in Bahasa Malaysia (Malay) to match the web version
- Remember me functionality saves email to SharedPreferences
- Authentication token is stored in SharedPreferences after successful login
