import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'environment.dart' as env;

/// Handles when a purchase tag is added to a task
///
/// [taskId] - The ClickUp task ID
/// [tagName] - The name of the tag that was added
Future<void> onPurchaseTagAdded(String taskId, String tagName) async {
  stdout.writeln('[Tags] Purchase tag "$tagName" added to task: $taskId');

  // Check if task is already in shopping list
  if (!await isTaskInShoppingList(taskId)) {
    // Add task to shopping list
    await addTaskToShoppingList(taskId);
    stdout.writeln('[Tags] Added task $taskId to shopping list');
  } else {
    stdout.writeln('[Tags] Task $taskId is already in shopping list');
  }
}

/// Handles when a purchase tag is removed from a task
///
/// [taskId] - The ClickUp task ID
/// [tagName] - The name of the tag that was removed
Future<void> onPurchaseTagRemoved(String taskId, String tagName) async {
  stdout.writeln('[Tags] Purchase tag "$tagName" removed from task: $taskId');

  // Check if task is in shopping list
  if (await isTaskInShoppingList(taskId)) {
    // Remove task from shopping list
    await removeTaskFromShoppingList(taskId);
    stdout.writeln('[Tags] Removed task $taskId from shopping list');
  } else {
    stdout.writeln('[Tags] Task $taskId is not in shopping list');
  }
}

/// Checks if a task is already in the shopping list
///
/// [taskId] - The ClickUp task ID to check
/// Returns true if the task is in the shopping list, false otherwise
Future<bool> isTaskInShoppingList(String taskId) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.clickup.com/api/v2/list/${env.shoppingListId}/task'),
      headers: {
        'Authorization': env.token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final tasks = jsonDecode(response.body)['tasks'] as List? ?? [];
      return tasks.any((task) => task['id'] == taskId);
    } else {
      stderr.writeln('[Tags] Failed to fetch shopping list tasks: ${response.statusCode} - ${response.body}');
      return false;
    }
  } catch (e) {
    stderr.writeln('[Tags] Error checking if task is in shopping list: $e');
    return false;
  }
}

/// Adds a task to the shopping list
///
/// [taskId] - The ClickUp task ID to add
Future<void> addTaskToShoppingList(String taskId) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.clickup.com/api/v2/list/${env.shoppingListId}/task'),
      headers: {
        'Authorization': env.token,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': 'Task from $taskId', // You might want to fetch the actual task name
        'description': 'Added automatically when purchase tag was added',
        'status': 'to do',
      }),
    );

    if (response.statusCode == 200) {
      stdout.writeln('[Tags] Successfully added task to shopping list');
    } else {
      stderr.writeln('[Tags] Failed to add task to shopping list: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    stderr.writeln('[Tags] Error adding task to shopping list: $e');
  }
}

/// Removes a task from the shopping list
///
/// [taskId] - The ClickUp task ID to remove
Future<void> removeTaskFromShoppingList(String taskId) async {
  try {
    // First, find the task in the shopping list to get its ID
    final response = await http.get(
      Uri.parse('https://api.clickup.com/api/v2/list/${env.shoppingListId}/task'),
      headers: {
        'Authorization': env.token,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final tasks = jsonDecode(response.body)['tasks'] as List? ?? [];
      final shoppingListTask = tasks.firstWhere(
        (task) => task['name']?.contains(taskId) == true,
        orElse: () => null,
      );

      if (shoppingListTask != null) {
        final shoppingListTaskId = shoppingListTask['id'];

        // Delete the task from the shopping list
        final deleteResponse = await http.delete(
          Uri.parse('https://api.clickup.com/api/v2/task/$shoppingListTaskId'),
          headers: {
            'Authorization': env.token,
            'Content-Type': 'application/json',
          },
        );

        if (deleteResponse.statusCode == 200) {
          stdout.writeln('[Tags] Successfully removed task from shopping list');
        } else {
          stderr.writeln(
              '[Tags] Failed to remove task from shopping list: ${deleteResponse.statusCode} - ${deleteResponse.body}');
        }
      } else {
        stdout.writeln('[Tags] Task not found in shopping list');
      }
    } else {
      stderr
          .writeln('[Tags] Failed to fetch shopping list tasks for removal: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    stderr.writeln('[Tags] Error removing task from shopping list: $e');
  }
}
