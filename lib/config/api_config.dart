class ApiConfig {
  // Base URL for API endpoints
  // Update this value to match your server configuration
  
  // For Android Emulator, use: http://10.0.2.2:8000/api
  // For iOS Simulator, use: http://localhost:8000/api
  // For Physical Device, use your computer's IP: http://192.168.x.x:8000/api
  // For Production, use your domain: https://yourdomain.com/api
  
  // Update this to your actual server URL
  static const String baseUrl = 'http://192.168.0.165:8000/api';
  
  // Google OAuth Configuration
  // Web Client ID: Used for server-side token verification (from Laravel config)
  static const String googleWebClientId = '945050509185-cptos9ssc86tm0a0e28ko7la6je9uakc.apps.googleusercontent.com';
  
  // Android Client ID: Configured in Google Cloud Console
  // Package name: com.example.mygooners
  // SHA-1: Must be added in Google Cloud Console
  // Note: Android Client ID is automatically used by Flutter, no need to set in code
  static const String googleAndroidClientId = '945050509185-e64tsa4gqjc6tctiaa07tqm5j8qj0pn9.apps.googleusercontent.com';
  
  // API Endpoints
  static const String login = '/mobile/login';
  static const String register = '/mobile/register';
  static const String loginGoogle = '/mobile/login/google';
  static const String logout = '/mobile/logout';
  static const String forgotPassword = '/mobile/password/email';
  
  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
  
  // Helper method to check if base URL is configured
  static bool isConfigured() {
    return baseUrl.isNotEmpty && baseUrl != 'http://localhost:8000/api';
  }
}

