class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator
  );
}
