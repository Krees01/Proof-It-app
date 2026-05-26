import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static String get host => kIsWeb ? 'localhost' : '10.0.2.2';
  static String get baseUrl =>
      'https://gregarious-playfulness-production-e7df.up.railway.app/api';
}
