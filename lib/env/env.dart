import "dart:io";
import "package:yaml/yaml.dart";
import 'clickup.dart' as clickup;

// -------- Environment Loading Functions --------

/// Converts YAML data to Dart Map recursively
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

/// Loads configuration from a YAML file
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
    stdout.writeln("[Env] Successfully loaded configuration from $filePath");
    return config;
  } catch (e) {
    stderr.writeln("Error loading $filePath: $e");
    exit(1);
  }
}

/// Gets the environment path from ENV_PATH environment variable
/// Falls back to "env" if not set
String _getEnvFolderPath() {
  final envPath = Platform.environment['ENV_PATH'] ?? "env";
  stdout.writeln("[Env] Using environment path: $envPath");
  return envPath;
}

/// Constructs the full path to clickup.yaml file
String _getEnvFilePath(String fileName) {
  final envFolderPath = _getEnvFolderPath();
  final envFilePath = "$envFolderPath/$fileName";
  return envFilePath;
}

/// Loads the ClickUp configuration from env/clickup.yaml
void _setClickupEnv() {
  final envPath = _getEnvFilePath(clickup.ENV_FILE_NAME);
  final envMap = _loadConfig(envPath);
  clickup.set(envMap);
}

void set() {
  _setClickupEnv();
}
