import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

class InventoryFormScreen extends StatefulWidget {
  const InventoryFormScreen({super.key});

  @override
  _InventoryFormScreenState createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _buyDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _buyDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addInventoryItem() async {
    if (_formKey.currentState!.validate()) {
      final buyDate = DateFormat('yyyy-MM-dd').parse(_buyDateController.text);

      await _dbHelper.insertInventory(
        _nameController.text,
        _descriptionController.text,
        _linkController.text,
        double.tryParse(_priceController.text) ?? 0.0,
        int.tryParse(_countController.text) ?? 1,
        buyDate,
      );

      _showSnackbar('Inventory item added successfully!');
      Navigator.pop(context, true);
    }
  }

  Future<void> _selectBuyDate(BuildContext context) async {
    DateTime? selectedDate = DateTime.parse(_buyDateController.text);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        _buyDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Inventory Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Item Name*'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Name is required'
                      : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(labelText: 'Link'),
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price*'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Price is required'
                      : null,
                ),
                TextFormField(
                  controller: _countController,
                  decoration: const InputDecoration(labelText: 'Count'),
                  keyboardType: TextInputType.number,
                ),
                GestureDetector(
                  onTap: () => _selectBuyDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _buyDateController,
                      decoration: const InputDecoration(labelText: 'Buy Date*'),
                      keyboardType: TextInputType.datetime,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Buy date is required'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addInventoryItem,
                  child: const Text('Add Inventory Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
