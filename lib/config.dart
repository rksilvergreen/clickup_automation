import 'dart:io';

import 'package:yaml/yaml.dart';

// -------- Constants --------
const String API_CONFIG_FILE = 'config/api.yaml';
const String SERVER_CONFIG_FILE = 'config/server.yaml';
const String RUNTIME_CONFIG_FILE = 'config/runtime.yaml';

// -------- Configuration Classes --------

/// API Configuration Class
class ApiConfig {
  final String baseUrl;
  final String teamId;
  final String token;
  final TaskTypes taskTypes;
  final Lists lists;
  final CustomFields customFields;
  final Tags tags;

  ApiConfig({
    required this.baseUrl,
    required this.teamId,
    required this.token,
    required this.taskTypes,
    required this.lists,
    required this.customFields,
    required this.tags,
  });

  factory ApiConfig.fromMap(Map<String, dynamic> map) {
    return ApiConfig(
      baseUrl: map['CLICKUP_BASE_URL'] as String,
      teamId: map['CLICKUP_TEAM_ID'] as String,
      token: map['CLICKUP_TOKEN'] as String,
      taskTypes: TaskTypes.fromMap(map['task_types'] as Map<String, dynamic>),
      lists: Lists.fromMap(map['lists'] as Map<String, dynamic>),
      customFields: CustomFields.fromMap(map['custom_fields'] as Map<String, dynamic>),
      tags: Tags.fromMap(map['tags'] as Map<String, dynamic>),
    );
  }
}

/// Task Types Configuration
class TaskTypes {
  final String eventTaskTypeId;

  TaskTypes({required this.eventTaskTypeId});

  factory TaskTypes.fromMap(Map<String, dynamic> map) {
    return TaskTypes(
      eventTaskTypeId: map['TASK_TYPE_ID_EVENT'] as String,
    );
  }
}

/// Lists Configuration
class Lists {
  final String shoppingListId;

  Lists({required this.shoppingListId});

  factory Lists.fromMap(Map<String, dynamic> map) {
    return Lists(
      shoppingListId: map['LIST_ID_SHOPPING'] as String,
    );
  }
}

/// Custom Fields Configuration
class CustomFields {
  final String startTimeCustomFieldId;
  final String endTimeCustomFieldId;
  final String relevanceNumCustomFieldId;
  final String relevanceUnitCustomFieldId;
  final String relevanceDateCustomFieldId;

  CustomFields({
    required this.startTimeCustomFieldId,
    required this.endTimeCustomFieldId,
    required this.relevanceNumCustomFieldId,
    required this.relevanceUnitCustomFieldId,
    required this.relevanceDateCustomFieldId,
  });

  factory CustomFields.fromMap(Map<String, dynamic> map) {
    return CustomFields(
      startTimeCustomFieldId: map['CUSTOM_FIELD_ID_START_TIME'] as String,
      endTimeCustomFieldId: map['CUSTOM_FIELD_ID_END_TIME'] as String,
      relevanceNumCustomFieldId: map['CUSTOM_FIELD_ID_RELEVANCE_NUM'] as String,
      relevanceUnitCustomFieldId: map['CUSTOM_FIELD_ID_RELEVANCE_UNIT'] as String,
      relevanceDateCustomFieldId: map['CUSTOM_FIELD_ID_RELEVANCE_DATE'] as String,
    );
  }
}

/// Tags Configuration
class Tags {
  final String purchaseTagName;

  Tags({required this.purchaseTagName});

  factory Tags.fromMap(Map<String, dynamic> map) {
    return Tags(
      purchaseTagName: map['TAG_NAME_PURCHASE'] as String,
    );
  }
}

/// Server Configuration Class
class ServerConfig {
  final String publicBaseUrl;
  final int port;
  final String webhookSecret;

  ServerConfig({
    required this.publicBaseUrl,
    required this.port,
    required this.webhookSecret,
  });

  factory ServerConfig.fromMap(Map<String, dynamic> map) {
    return ServerConfig(
      publicBaseUrl: map['PUBLIC_BASE_URL'] as String,
      port: int.parse(map['PORT'] as String),
      webhookSecret: map['CLICKUP_WEBHOOK_SECRET'] as String,
    );
  }
}

/// Runtime Configuration Class
class RuntimeConfig {
  final Automation automation;

  RuntimeConfig({required this.automation});

  factory RuntimeConfig.fromMap(Map<String, dynamic> map) {
    return RuntimeConfig(
      automation: Automation.fromMap(map['automation'] as Map<String, dynamic>),
    );
  }

  /// Factory constructor that loads runtime configuration from YAML file
  /// and updates the global runtime configuration
  factory RuntimeConfig.reload() {
    try {
      // Load the runtime configuration file
      final runtimeConfigMap = _loadConfig(RUNTIME_CONFIG_FILE, 'Runtime');

      // Create new runtime configuration
      final newRuntime = RuntimeConfig.fromMap(runtimeConfigMap);

      // Update the global runtime configuration
      _runtime = newRuntime;

      return newRuntime;
    } catch (e) {
      stderr.writeln('[Config] Error reloading runtime configuration: $e');
      rethrow;
    }
  }
}

/// Automation Configuration
class Automation {
  final bool events;
  final bool purchaseTags;
  final bool taskDates;

  Automation({
    required this.events,
    required this.purchaseTags,
    required this.taskDates,
  });

  factory Automation.fromMap(Map<String, dynamic> map) {
    return Automation(
      events: map['events'] as bool,
      purchaseTags: map['purchase_tags'] as bool,
      taskDates: map['task_dates'] as bool,
    );
  }
}

// -------- Global Configuration Instances --------
late final ApiConfig api;
late final ServerConfig server;
RuntimeConfig? _runtime;

/// Public getter for runtime configuration
RuntimeConfig get runtime {
  if (_runtime == null) {
    throw StateError('Runtime configuration not loaded. Call loadConfiguration() first.');
  }
  return _runtime!;
}

// -------- Configuration Loading --------
Map<String, dynamic>? _apiConfigMap;
Map<String, dynamic>? _serverConfigMap;
Map<String, dynamic>? _runtimeConfigMap;

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

Map<String, dynamic> _loadConfig(String filePath, String configName) {
  try {
    final file = File(filePath);
    if (!file.existsSync()) {
      stderr.writeln('Error: $filePath file not found. Please create it with your configuration.');
      exit(1);
    }

    final yamlString = file.readAsStringSync();
    final yamlMap = loadYaml(yamlString);
    final config = _convertYamlToMap(yamlMap);
    stdout.writeln('[Config] Successfully loaded $configName configuration');
    return config;
  } catch (e) {
    stderr.writeln('Error loading $filePath: $e');
    exit(1);
  }
}

void loadConfiguration() {
  // Load all configuration files
  _apiConfigMap = _loadConfig(API_CONFIG_FILE, 'API');
  _serverConfigMap = _loadConfig(SERVER_CONFIG_FILE, 'Server');
  _runtimeConfigMap = _loadConfig(RUNTIME_CONFIG_FILE, 'Runtime');

  // Create configuration objects
  api = ApiConfig.fromMap(_apiConfigMap!);
  server = ServerConfig.fromMap(_serverConfigMap!);
  _runtime = RuntimeConfig.fromMap(_runtimeConfigMap!);

  stdout.writeln('[Config] Configuration loaded successfully');
}
