import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:crypto/crypto.dart';
import 'environment.dart' as env;
import 'events.dart';

// -------- Server setup and routing --------

String prettyJsonString(String input) {
  final obj = jsonDecode(input); // throws FormatException if not valid JSON
  const encoder = JsonEncoder.withIndent('  '); // 2-space indent (use '\t' for tabs)
  return encoder.convert(obj);
}

Future<HttpServer> createServer() async {
  final app = Router();

  // Health endpoint
  app.get('/health', (Request req) => Response.ok('ok'));

  // Webhook receiver
  app.post('/webhooks/clickup', (Request req) async {
    final raw = await req.readAsString();

    // print(prettyJsonString(raw));

    // Verify webhook signature if secret is configured
    if (env.secret.isNotEmpty) {
      final signature = req.headers['x-signature'];
      if (signature == null || !_verifyWebhookSignature(raw, signature, env.secret)) {
        stderr.writeln('[ClickUp] Invalid webhook signature');
        return Response.forbidden('Invalid signature');
      }
    } else {
      stdout.writeln('[ClickUp] Warning: No webhook secret configured, skipping signature verification');
    }

    try {
      final body = json.decode(raw);
      // Pull a few helpful fields if present
      final event = (body is Map && body['event'] != null) ? body['event'] : 'unknown';
      final taskId =
          (body is Map && body['task_id'] != null) ? body['task_id'] : (body is Map ? (body['task']?['id']) : null);
      stdout.writeln('[ClickUp] event=$event task=$taskId payloadSize=${raw.length}');

      // Route to appropriate handler based on event type
      switch (event) {
        case 'taskCreated':
          await _onTaskCreated(body, taskId);
          break;
        case 'taskUpdated':
          await _onTaskUpdated(body, taskId);
          break;
        default:
          stdout.writeln('[ClickUp] Unhandled event type: $event');
      }
    } catch (_) {
      stdout.writeln('[ClickUp] non-JSON or unexpected payload, size=${raw.length}');
    }
    return Response.ok('ok');
  });

  // Start HTTP server
  final server = await serve(
    logRequests().addHandler(app),
    InternetAddress.anyIPv4,
    env.port,
  );

  stdout.writeln('Listening on http://${server.address.host}:${server.port}  (public: ${env.publicBaseUrl})');

  return server;
}

bool _verifyWebhookSignature(String payload, String signature, String secret) {
  try {
    // ClickUp uses HMAC-SHA256 for webhook signatures
    // The signature is the hex-encoded HMAC of the payload using the secret as key
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(payload));
    final expectedSignature = digest.toString();

    return signature == expectedSignature;
  } catch (e) {
    stderr.writeln('[ClickUp] Error verifying signature: $e');
    return false;
  }
}

// -------- Webhook event handlers --------

Future<Map<String, dynamic>?> fetchTaskDetails(String taskId) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.clickup.com/api/v2/task/$taskId'),
      headers: {
        'Authorization': env.token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // print(prettyJsonString(response.body));

      final taskData = jsonDecode(response.body);
      stdout.writeln('[ClickUp] Successfully fetched task details for: $taskId');
      return taskData;
    } else {
      stderr.writeln('[ClickUp] Failed to fetch task details: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    stderr.writeln('[ClickUp] Error fetching task details: $e');
    return null;
  }
}

Future<void> _onTaskCreated(Map<String, dynamic> body, String? taskId) async {
  stdout.writeln('[ClickUp] Handling task created: $taskId');

  if (taskId != null) {
    final taskDetails = await fetchTaskDetails(taskId);
    if (taskDetails != null) {
      stdout.writeln(
          '[ClickUp] Task created - Name: ${taskDetails['name']}, Status: ${taskDetails['status']?['status']}');
      // TODO: Implement your task creation logic here
      // Example: Send notifications, update external systems, etc.
    }
  }
}

Future<void> _onTaskUpdated(Map<String, dynamic> body, String? taskId) async {
  stdout.writeln('[ClickUp] Handling task updated: $taskId');

  if (taskId != null) {
    final taskDetails = await fetchTaskDetails(taskId);
    if (taskDetails != null) {
      stdout.writeln(
          '[ClickUp] Task updated - Name: ${taskDetails['name']}, Status: ${taskDetails['status']?['status']}');

      // Check if this is an event task and handle it accordingly
      if (isEventTask(taskDetails)) {
        stdout.writeln('[ClickUp] Detected event task, forwarding to events handler');
        await onEventUpdated(taskDetails, body);
      } else {
        stdout.writeln('[ClickUp] Regular task update - not an event');
        // TODO: Implement your regular task update logic here
        // Example: Sync changes to external systems, trigger workflows, etc.
      }
    }
  }
}
