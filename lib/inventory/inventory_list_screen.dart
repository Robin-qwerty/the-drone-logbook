import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import 'inventory_add_screen.dart';
import 'inventory_edit_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  _InventoryListScreenState createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _inventoryItems = [];

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    final inventoryItems = await _dbHelper.getAllInventoryItems();
    setState(() {
      _inventoryItems = inventoryItems;
    });
  }

  void _navigateToAddInventoryItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InventoryFormScreen()),
    );
    if (result == true) {
      _loadInventoryItems();
    }
  }

  void _navigateToEditInventoryItem(Map<String, dynamic> inventoryItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              InventoryEditScreen(inventoryItem: inventoryItem)),
    );
    if (result == true) {
      _loadInventoryItems();
    }
  }

  void _deleteInventoryItem(int inventoryId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteInventoryItem(inventoryId);
      _loadInventoryItems();
    }
  }

  void _showInventoryItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name']),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Description: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(item['description'] ?? 'No description'),
            const Text(
              'Link: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                final link = item['link'];
                if (link != null) {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard!')),
                  );
                }
              },
              child: Text(
                item['link'] ?? 'No link available',
                style: const TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const Text(
              'Price: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('\$${item['price']}'),
            const Text(
              'Count: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${item['count']}'),
            const Text(
              'Buy Date: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_formatDate(item['buy_date'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory List')),
      body: _inventoryItems.isEmpty
          ? const Center(child: Text('No inventory items found.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _inventoryItems.length,
                    itemBuilder: (context, index) {
                      final item = _inventoryItems[index];
                      return Slidable(
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) =>
                                  _navigateToEditInventoryItem(item),
                              backgroundColor: Colors.blue,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (context) =>
                                  _deleteInventoryItem(item['id']),
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) =>
                                  _navigateToEditInventoryItem(item),
                              backgroundColor: Colors.blue,
                              icon: Icons.edit,
                              label: 'Edit',
                            ),
                            SlidableAction(
                              onPressed: (context) =>
                                  _deleteInventoryItem(item['id']),
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            '(${item['id']}) - ${item['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Price: \$${item['price']} - Count: ${item['count']} - Buy Date: ${_formatDate(item['buy_date'])}', // Display formatted date
                          ),
                          onTap: () => _showInventoryItemDetails(item),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Swipe left or right to edit or delete an item.',
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddInventoryItem,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }
}
