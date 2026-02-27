import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../../data/services/local_cache_service.dart';
import 'list_detail_screen.dart';
import '../widgets/list_dialog.dart';
import '../../data/models/todo_list.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final _cache = LocalCacheService();
  bool _didCheckCache = false;
  bool _isCheckingCache = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didCheckCache) {
      _didCheckCache = true;
      _restoreLastList();
    }
  }

  void _restoreLastList() {
    final lastListId = _cache.getLastOpenListIdSync();
    if (lastListId != null) {
      final provider = context.read<TodoProvider>();
      final lists = provider.lists;
      final match = lists.cast<dynamic>().firstWhere(
        (l) => l.id == lastListId,
        orElse: () => null,
      );
      if (match != null) {
        // Defer push to after the build frame — Navigator is locked during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _openListFromCache(context, match);
          }
        });
        return;
      }
    }
    // No cached list or not found — reveal lists screen immediately
    setState(() => _isCheckingCache = false);
  }

  void _openListFromCache(BuildContext context, dynamic list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(list: list),
      ),
    ).then((_) {
      _cache.setLastOpenListId(null);
      if (mounted) {
        setState(() => _isCheckingCache = false);
        context.read<TodoProvider>().setSelectedListId(null);
      }
    });
  }

  void _openList(BuildContext context, dynamic list) {
    _cache.setLastOpenListId(list.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(list: list),
      ),
    ).then((_) {
      _cache.setLastOpenListId(null);
      if (context.mounted) {
        context.read<TodoProvider>().setSelectedListId(null);
      }
    });
  }

  // _showAddListDialog removed as it's now handled by the global FAB.

  @override
  Widget build(BuildContext context) {
    // Don't show the lists screen while checking if we need to auto-open a cached list
    if (_isCheckingCache) {
      return const SizedBox.shrink();
    }

    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.lists.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () => provider.fetchTodos(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Lists',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        final inboxList = TodoList(id: null, title: 'Inbox', color: '#BB86FC');
                        _openList(context, inboxList);
                      },
                      icon: const Icon(Icons.inbox),
                      tooltip: 'Inbox',
                    ),
                  ],
                ),
              ),
              
              // Lists Directory
              Expanded(
                child: provider.lists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No lists created yet',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create a list',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ).copyWith(bottom: 100),
                        itemCount: provider.lists.length,
                        onReorder: (oldIndex, newIndex) {
                          provider.reorderLists(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final list = provider.lists[index];
                          final taskCount = provider.todos
                              .where((t) => t.listId == list.id && !t.isCompleted)
                              .length;
                          
                          Color listColor = Theme.of(context).colorScheme.primary;
                          if (list.color != null) {
                            try {
                              listColor = Color(int.parse(list.color!.replaceFirst('#', '0xFF')));
                            } catch (_) {}
                          }

                          // ReorderableListView requires unique keys for items
                          return Dismissible(
                            key: Key('list_${list.id}'),
                            direction: DismissDirection.horizontal,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                // Swipe Left - Delete
                                _showDeleteListDialog(context, list);
                                return false; // Don't dismiss immediately, let dialog handle it via provider update
                              } else {
                                // Swipe Right - Edit
                                showDialog(
                                  context: context,
                                  builder: (context) => ListDialog(list: list),
                                );
                                return false;
                              }
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 30),
                            ),
                            secondaryBackground: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white, size: 30),
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: listColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              color: const Color(0xFF1E1E1E),
                              child: InkWell(
                                onTap: () {
                                  _openList(context, list);
                                },
                                onLongPress: () => _showDeleteListDialog(context, list),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      // Drag Handle
                                      Icon(
                                        Icons.drag_indicator,
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: listColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: listColor.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          list.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: listColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$taskCount',
                                          style: TextStyle(
                                            color: listColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.white.withValues(alpha: 0.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // _showEditListDialog replaced by standard ListDialog

  void _showDeleteListDialog(BuildContext context, dynamic list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${list.title}"?\nAll tasks in this list will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TodoProvider>().deleteList(list.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

