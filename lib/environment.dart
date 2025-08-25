import 'dart:io';

import 'package:yaml/yaml.dart';

// -------- Constants --------
const String ENV_FILE = 'env.yaml';

// -------- Top-level environment variables --------
late final String token;
late final String teamId;
late final String publicBaseUrl;
late final String secret;
late final String spaceId;
late final String folderId;
late final String listId;
late final String eventTaskTypeId;
late final String startTimeCustomFieldId;
late final String endTimeCustomFieldId;
late final String relevanceNumCustomFieldId;
late final String relevanceUnitCustomFieldId;
late final String relevanceDateCustomFieldId;
late final int port;

// -------- Config from $ENV_FILE file --------
Map<String, dynamic>? _config;

dynamic _convertYamlToMap(dynamic yamlData) {
  if (yamlData is YamlMap) {
    final Map<String, dynamic> result = {};
    for (final key in yamlData.keys) {
      final value = yamlData[key];
      if (value is YamlMap) {
        result[key.toString()] = _convertYamlToMap(value);
      } else if (value is YamlList) {
        result[key.toString()] = value.map((item) => _convertYamlToMap(item)).toList();
      } else {
        result[key.toString()] = value;
      }
    }
    return result;
  } else if (yamlData is YamlList) {
    return yamlData.map((item) => _convertYamlToMap(item)).toList();
  } else {
    return yamlData;
  }
}

Map<String, dynamic> _loadConfig() {
  if (_config != null) return _config!;

  try {
    final file = File(ENV_FILE);
    if (!file.existsSync()) {
      stderr.writeln('Error: $ENV_FILE file not found. Please create it with your configuration.');
      exit(1);
    }

    final yamlString = file.readAsStringSync();
    final yamlMap = loadYaml(yamlString);
    _config = _convertYamlToMap(yamlMap);
    return _config!;
  } catch (e) {
    stderr.writeln('Error loading $ENV_FILE: $e');
    exit(1);
  }
}

String _env(String key, {String? def}) {
  final config = _loadConfig();
  final v = config[key]?.toString();
  if (v == null || v.isEmpty) {
    if (def != null) return def;
    stderr.writeln('Missing required env: $key');
    exit(1);
  }
  return v;
}

void loadEnvironmentVariables() {
  token = _env('CLICKUP_TOKEN'); // e.g. 'pk_...'
  teamId = _env('CLICKUP_TEAM_ID'); // numeric id
  publicBaseUrl = _env('PUBLIC_BASE_URL'); // e.g. 'https://my.domain.tld'
  secret = _env('CLICKUP_WEBHOOK_SECRET', def: ''); // optional, will be populated after webhook creation
  spaceId = _env('CLICKUP_SPACE_ID', def: ''); // optional
  folderId = _env('CLICKUP_FOLDER_ID', def: ''); // optional
  listId = _env('CLICKUP_LIST_ID', def: ''); // optional
  eventTaskTypeId = _env('TASK_TYPE_EVENT_ID', def: ''); // optional
  startTimeCustomFieldId = _env('START_TIME_CUSTOM_FIELD_ID', def: ''); // optional
  endTimeCustomFieldId = _env('END_TIME_CUSTOM_FIELD_ID', def: ''); // optional
  relevanceNumCustomFieldId = _env('RELEVANCE_NUM_CUSTOM_FIELD_ID', def: ''); // optional
  relevanceUnitCustomFieldId = _env('RELEVANCE_UNIT_CUSTOM_FIELD_ID', def: ''); // optional
  relevanceDateCustomFieldId = _env('RELEVANCE_DATE_CUSTOM_FIELD_ID', def: ''); // optional
  port = int.parse(_env('PORT', def: '8080'));
}
