import 'package:timezone/data/latest.dart';
import 'config.dart' as config;
import 'ensure_webhook.dart';
import 'server.dart';

Future<void> main() async {
  // Initialize timezone database
  initializeTimeZones();

  // Load configuration
  config.loadConfiguration();

  // Create and start the server
  await createServer();

  // Ensure webhook exists
  await ensureWebhook(endpointUrl: '${config.server.publicBaseUrl}/webhooks/clickup');
}
