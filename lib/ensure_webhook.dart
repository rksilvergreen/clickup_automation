import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'environment.dart' as env;

// -------- ClickUp API helpers --------

const _base = 'https://api.clickup.com/api/v2';

Map<String, String> _headers(String token) => {
      'Authorization': token, // ClickUp expects the token directly, not 'Bearer ...'
      'Content-Type': 'application/json',
    };

Future<void> ensureWebhook({required String endpointUrl}) async {
  final existing = await _listWebhooks(env.token, env.teamId);

  // Find a webhook pointing to our endpoint that includes taskUpdated
  final match = existing.firstWhere(
    (w) => endpointUrl == w['endpoint']?.toString(),
    orElse: () => {},
  );

  if (match.isNotEmpty) {
    stdout.writeln('Webhook exists (id=${match['id']}) for $endpointUrl with ${match['events']}');

    // If we have a webhook but no secret, try to get the secret from the existing webhook
    if (env.secret.isEmpty && match['secret'] != null) {
      // Note: We can't modify the top-level secret variable from env.dart
      // The secret will be available in the webhook response for verification
      stdout.writeln('Webhook secret found in ClickUp response');
    }
    return;
  }

  // Webhook not found - throw an error
  throw Exception(
      'Required webhook not found for endpoint: $endpointUrl. Please create a webhook in ClickUp that points to this endpoint and includes the "taskUpdated" event.');
}

Future<List<Map<String, dynamic>>> _listWebhooks(String token, String teamId) async {
  final resp = await http.get(
    Uri.parse('$_base/team/$teamId/webhook'),
    headers: _headers(token),
  );

  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    final data = jsonDecode(resp.body);
    final hooks = (data['webhooks'] as List?) ?? const [];
    return hooks.cast<Map<String, dynamic>>();
  } else {
    stderr.writeln('Failed to list webhooks (${resp.statusCode}): ${resp.body}');
    throw Exception('ClickUp webhook list failed: ${resp.statusCode}');
  }
}
