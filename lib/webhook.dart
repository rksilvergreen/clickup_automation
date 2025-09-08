import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'env.dart' as env;

// -------- ClickUp API helpers --------

Future<void> ensureWebhook() async {
  final existing = await _listWebhooks(env.clickup.token, env.clickup.teamId);
  final endpointUrl = '${env.clickup.webhookEndpointBaseUrl}${env.clickup.webhookEndpointRoute}';
  // Find a webhook pointing to our endpoint that includes taskUpdated
  final match = existing.firstWhere(
    (w) => endpointUrl == w['endpoint']?.toString(),
    orElse: () => {},
  );

  if (match.isNotEmpty) {
    final webhookId = match['id'].toString();
    final status = match['status']?.toString();

    stdout.writeln('[Webhook] Endpoint: $endpointUrl');
    stdout.writeln('[Webhook] Workspace ID: ${env.clickup.teamId}');
    stdout.writeln('[Webhook] Webhook ID: $webhookId');

    // Check if webhook is active, if not activate it
    if (status != 'active') {
      stdout.writeln('[Webhook] Webhook is not active (status: $status), attempting to activate...');
      await _activateWebhook(webhookId);
    }
    stdout.writeln('[Webhook] Webhook is activated');

    // If we have a webhook but no secret, try to get the secret from the existing webhook
    if (env.clickup.webhookSecret.isEmpty && match['secret'] != null) {
      // Note: We can't modify the top-level secret variable from env.dart
      // The secret will be available in the webhook response for verification
      stdout.writeln('[Webhook] Webhook secret found in ClickUp response');
    }

    return;
  }

  // Webhook not found - throw an error
  throw Exception(
      'Required webhook not found for endpoint: $endpointUrl. Please create a webhook in ClickUp that points to this endpoint and includes the "taskUpdated" event.');
}

Future<List<Map<String, dynamic>>> _listWebhooks(String token, String teamId) async {
  final resp = await http.get(
    Uri.parse('${env.CLICKUP_BASE_URL}/team/$teamId/webhook'),
    headers: {
      'Authorization': token,
      'Content-Type': 'application/json',
    },
  );

  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    final data = jsonDecode(resp.body);
    final hooks = (data['webhooks'] as List?) ?? const [];
    return hooks.cast<Map<String, dynamic>>();
  } else {
    stderr.writeln('[Webhook] Failed to list webhooks (${resp.statusCode}): ${resp.body}');
    throw Exception('ClickUp webhook list failed: ${resp.statusCode}');
  }
}

/// Activates a webhook by setting its status to 'active'
///
/// [webhookId] - The ClickUp webhook ID to activate
Future<void> _activateWebhook(String webhookId) async {
  try {
    final resp = await http.put(
      Uri.parse('${env.CLICKUP_BASE_URL}/webhook/$webhookId'),
      headers: {
        'Authorization': env.clickup.token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': 'active'}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      stdout.writeln('[Webhook] Webhook $webhookId activated successfully');
    } else {
      stderr.writeln('[Webhook] Failed to activate webhook $webhookId (${resp.statusCode}): ${resp.body}');
      throw Exception('ClickUp webhook activation failed: ${resp.statusCode}');
    }
  } catch (e) {
    stderr.writeln('[Webhook] Error activating webhook $webhookId: $e');
    rethrow;
  }
}
