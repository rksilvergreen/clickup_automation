import "dart:io";
import "package:yaml/yaml.dart";

// -------- Constants --------
const String _DEFAULT_ENV_PATH = "env.yaml";
const String CLICKUP_BASE_URL = "https://api.clickup.com/api/v2";

// -------- Configuration Classes --------

/// Environment Configuration Class
class ClickupWorkspace {
  final String teamId;
  final String token;
  final String webhookEndpointBaseUrl;
  final String webhookEndpointRoute;
  final String webhookSecret;
  final TaskTypeIds taskTypeIds;
  final ListIds listIds;
  final CustomFieldIds customFieldIds;
  final TagNames tagNames;

  ClickupWorkspace({
    required this.teamId,
    required this.token,
    required this.webhookEndpointBaseUrl,
    required this.webhookEndpointRoute,
    required this.webhookSecret,
    required this.taskTypeIds,
    required this.listIds,
    required this.customFieldIds,
    required this.tagNames,
  });

  factory ClickupWorkspace.fromMap(Map<String, dynamic> map) {
    return ClickupWorkspace(
      teamId: map["CLICKUP_TEAM_ID"] as String,
      token: map["CLICKUP_TOKEN"] as String,
      webhookEndpointBaseUrl: map["CLICKUP_WEBHOOK_ENDPOINT_BASE_URL"] as String,
      webhookEndpointRoute: map["CLICKUP_WEBHOOK_ENDPOINT_ROUTE"] as String,
      webhookSecret: map["CLICKUP_WEBHOOK_SECRET"] as String,
      taskTypeIds: TaskTypeIds.fromMap(map["task_type_ids"] as Map<String, dynamic>),
      listIds: ListIds.fromMap(map["list_ids"] as Map<String, dynamic>),
      customFieldIds: CustomFieldIds.fromMap(map["custom_field_ids"] as Map<String, dynamic>),
      tagNames: TagNames.fromMap(map["tag_names"] as Map<String, dynamic>),
    );
  }
}

/// Task Type IDs Configuration
class TaskTypeIds {
  final String event;

  TaskTypeIds({required this.event});

  factory TaskTypeIds.fromMap(Map<String, dynamic> map) {
    return TaskTypeIds(
      event: map["EVENT"] as String,
    );
  }
}

/// List IDs Configuration
class ListIds {
  final String shopping;

  ListIds({required this.shopping});

  factory ListIds.fromMap(Map<String, dynamic> map) {
    return ListIds(
      shopping: map["SHOPPING"] as String,
    );
  }
}

/// Custom Field IDs Configuration
class CustomFieldIds {
  final String startTime;
  final String endTime;
  final String relevanceNum;
  final String relevanceUnit;
  final String relevanceDate;

  CustomFieldIds({
    required this.startTime,
    required this.endTime,
    required this.relevanceNum,
    required this.relevanceUnit,
    required this.relevanceDate,
  });

  factory CustomFieldIds.fromMap(Map<String, dynamic> map) {
    return CustomFieldIds(
      startTime: map["START_TIME"] as String,
      endTime: map["END_TIME"] as String,
      relevanceNum: map["RELEVANCE_NUM"] as String,
      relevanceUnit: map["RELEVANCE_UNIT"] as String,
      relevanceDate: map["RELEVANCE_DATE"] as String,
    );
  }
}

/// Tag Names Configuration
class TagNames {
  final String purchase;

  TagNames({required this.purchase});

  factory TagNames.fromMap(Map<String, dynamic> map) {
    return TagNames(
      purchase: map["PURCHASE"] as String,
    );
  }
}

// -------- Global Configuration Instance --------
late final ClickupWorkspace clickup;

// -------- Configuration Loading --------
Map<String, dynamic>? _envMap;

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

Map<String, dynamic> _loadConfig(String filePath) {
  try {
    final file = File(filePath);
    if (!file.existsSync()) {
      stderr.writeln("Error: $filePath file not found. Please create it with your configuration.");
      exit(1);
    }

    final yamlString = file.readAsStringSync();
    final yamlMap = loadYaml(yamlString);
    final config = _convertYamlToMap(yamlMap);
    stdout.writeln("[Env] Successfully loaded environment");
    return config;
  } catch (e) {
    stderr.writeln("Error loading $filePath: $e");
    exit(1);
  }
}

void loadConfiguration() {
  // Get env path from environment variable or use default
  final envPath = Platform.environment['ENV_PATH'] ?? _DEFAULT_ENV_PATH;

  // Load environment configuration file
  _envMap = _loadConfig(envPath);

  // Create configuration object
  clickup = ClickupWorkspace.fromMap(_envMap!);

  stdout.writeln("[Env] Configuration loaded successfully");
}
