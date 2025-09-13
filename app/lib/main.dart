import 'dart:io';
import 'package:timezone/data/latest.dart';
import 'env/env.dart' as env;
import 'server.dart';
import 'webhooks.dart';

Future<void> main() async {
  // Print environment variables
  print('GOGO environment variable: ${Platform.environment['GOGO']}');
  print('APP_MODE environment variable: ${Platform.environment['APP_MODE']}');

  // Initialize timezone database
  initializeTimeZones();

  // Set Environment
  env.set();

  // Ensure webhooks are alive and active
  await ensureWebhook();

  // Create and start the server
  await createServer();
}
