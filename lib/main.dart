import 'package:timezone/data/latest.dart';
import 'env.dart' as env;
import 'server.dart';
import 'webhook.dart';

Future<void> main() async {
  // Initialize timezone database
  initializeTimeZones();

  // Load configuration
  env.loadConfiguration();

  // Ensure webhook is created
  await ensureWebhook();

  // Create and start the server
  await createServer();
}