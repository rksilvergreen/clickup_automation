import 'package:timezone/data/latest.dart';
import 'env.dart' as env;
import 'server.dart';

Future<void> main() async {
  // Initialize timezone database
  initializeTimeZones();

  // Load configuration
  env.loadConfiguration();

  // Create and start the server
  await createServer();
}