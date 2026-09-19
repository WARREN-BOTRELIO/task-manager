import 'dart:async';

import 'package:flutter/material.dart';

import '../api/tasks_api.dart';
import '../main.dart';
import '../models/api_error.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import '../widgets/error_view.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Task>? _tasks;
  Object? _error;
  bool _loading = true;
  bool _deleting = false;

  TaskStatus? _statusFilter;

  TasksApi get _api => widget.dependencies.tasksApi;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _api.list(
        TaskListParams(status: _statusFilter, search: _searchController.text.trim()),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _tasks = page.content;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadTasks);
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<Task>(
      context: context,
      builder: (_) => TaskFormDialog(api: _api),
    );
    if (created != null) {
      await _loadTasks();
    }
  }

  Future<void> _confirmAndDelete(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task'),
        content: Text('Are you sure you want to delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await _api.delete(task.id);
      await _loadTasks();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(error, fallback: 'Unable to delete the task.'))),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(
        message: errorMessage(_error!, fallback: 'Failed to load your tasks.'),
        onRetry: _loadTasks,
      );
    }
    final tasks = _tasks ?? const <Task>[];
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('No tasks yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Create your first task to get started.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _openCreateDialog, child: const Text('Create a task')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: tasks.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: index == tasks.length - 1 ? 0 : 8),
          child: TaskCard(task: tasks[index], onDelete: _confirmAndDelete),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = widget.dependencies.authController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My tasks'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                auth.email,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateDialog,
        tooltip: 'New task',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search tasks…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadTasks();
                        },
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(null, 'All'),
                for (final status in TaskStatus.values) _filterChip(status, status.label),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
          if (_deleting)
            const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  Widget _filterChip(TaskStatus? value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _statusFilter = value);
          _loadTasks();
        },
      ),
    );
  }
}