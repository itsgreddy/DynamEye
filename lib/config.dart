class Config {
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'ws://localhost:8080',
  );

  static const String viewerUrl = String.fromEnvironment(
    'VIEWER_URL',
    defaultValue: 'http://localhost:8080',
  );
}
