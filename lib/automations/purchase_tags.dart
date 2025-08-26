import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart' as config;

/// Checks if the added tag is a relevant purchase tag
///
/// [tagDetails] - Details of the tag that was added
/// Returns true if the tag name matches the purchase tag name
bool isRelevantPurchaseTagAdded(Map<String, dynamic> tagDetails) {
  final tagName = tagDetails['name'] as String?;
  return tagName != null && tagName == config.api.tags.purchaseTagName;
}

/// Checks if the removed tag is a relevant purchase tag
///
/// [tagDetails] - Details of the tag that was removed
/// Returns true if the tag name matches the purchase tag name
bool isRelevantPurchaseTagRemoved(Map<String, dynamic> tagDetails) {
  final tagName = tagDetails['name'] as String?;
  return tagName != null && tagName == config.api.tags.purchaseTagName;
}

/// Handles when a purchase tag is added to a task
///
/// [taskDetails] - Complete task details from ClickUp API
/// [tagDetails] - Details of the tag that was added
Future<void> onPurchaseTagAdded(Map<String, dynamic> taskDetails, Map<String, dynamic> tagDetails) async {
  final taskId = taskDetails['id'];
  final tagName = tagDetails['name'];
  stdout.writeln('[Tags] Purchase tag "$tagName" added to task: $taskId');

  // Check if task is already in shopping list
  if (!isTaskInShoppingList(taskDetails)) {
    // Add task to shopping list
    await addTaskToShoppingList(taskId);
    stdout.writeln('[Tags] Added task $taskId to shopping list');
  } else {
    stdout.writeln('[Tags] Task $taskId is already in shopping list');
  }
}

/// Handles when a purchase tag is removed from a task
///
/// [taskDetails] - Complete task details from ClickUp API
/// [tagDetails] - Details of the tag that was removed
Future<void> onPurchaseTagRemoved(Map<String, dynamic> taskDetails, Map<String, dynamic> tagDetails) async {
  final taskId = taskDetails['id'];
  final tagName = tagDetails['name'];
  stdout.writeln('[Tags] Purchase tag "$tagName" removed from task: $taskId');

  // Check if task is in shopping list
  if (isTaskInShoppingList(taskDetails)) {
    // Remove task from shopping list
    await removeTaskFromShoppingList(taskId);
    stdout.writeln('[Tags] Removed task $taskId from shopping list');
  } else {
    stdout.writeln('[Tags] Task $taskId is not in shopping list');
  }
}

/// Checks if a task is already in the shopping list
///
/// [taskDetails] - Complete task details from ClickUp API
/// Returns true if the task is in the shopping list, false otherwise
bool isTaskInShoppingList(Map<String, dynamic> taskDetails) {
  // Check if the task's list ID matches the shopping list ID
  final taskListId = taskDetails['list']?['id']?.toString();
  if (taskListId == config.api.lists.shoppingListId) {
    return true;
  }

  // Check if the shopping list ID is in the task's locations
  final locations = taskDetails['locations'] as List? ?? [];
  for (final location in locations) {
    final locationId = location['id']?.toString();
    if (locationId == config.api.lists.shoppingListId) {
      return true;
    }
  }

  return false;
}

/// Adds a task to the shopping list
///
/// [taskId] - The ClickUp task ID to add
Future<void> addTaskToShoppingList(String taskId) async {
  try {
    final response = await http.post(
      Uri.parse('${config.api.baseUrl}/list/${config.api.lists.shoppingListId}/task/$taskId'),
      headers: {
        'Authorization': config.api.token,
        'accept': 'application/json',
      },
      // body: jsonEncode({
      //   'name': 'Task from $taskId', // You might want to fetch the actual task name
      //   'description': 'Added automatically when purchase tag was added',
      //   'status': 'to do',
      // }),
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
    // Delete the task directly using the taskId
    final deleteResponse = await http.delete(
      Uri.parse('${config.api.baseUrl}/list/${config.api.lists.shoppingListId}/task/$taskId'),
      headers: {
        'Authorization': config.api.token,
        'accept': 'application/json',
      },
    );

    if (deleteResponse.statusCode == 200) {
      stdout.writeln('[Tags] Successfully removed task from shopping list');
    } else {
      stderr.writeln(
          '[Tags] Failed to remove task from shopping list: ${deleteResponse.statusCode} - ${deleteResponse.body}');
    }
  } catch (e) {
    stderr.writeln('[Tags] Error removing task from shopping list: $e');
  }
}
