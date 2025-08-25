import 'package:timezone/data/latest.dart';
import 'environment.dart' as env;
import 'ensure_webhook.dart';
import 'server.dart';
import 'events.dart';

Future<void> main() async {
  // Initialize timezone database
  initializeTimeZones();

  // Load environment variables
  env.loadEnvironmentVariables();

  // Create and start the server
  await createServer();

  // Ensure webhook exists
  await ensureWebhook(endpointUrl: '${env.publicBaseUrl}/webhooks/clickup');
}