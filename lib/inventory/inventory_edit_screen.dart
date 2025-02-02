import 'package:flutter/material.dart';
import '../database_helper.dart';

class InventoryEditScreen extends StatefulWidget {
  final Map<String, dynamic> inventoryItem;

  const InventoryEditScreen({super.key, required this.inventoryItem});

  @override
  _InventoryEditScreenState createState() => _InventoryEditScreenState();
}

class _InventoryEditScreenState extends State<InventoryEditScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  late TextEditingController _priceController;
  late TextEditingController _countController;
  DateTime? _buyDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.inventoryItem['name']);
    _descriptionController =
        TextEditingController(text: widget.inventoryItem['description']);
    _linkController = TextEditingController(text: widget.inventoryItem['link']);
    _priceController =
        TextEditingController(text: widget.inventoryItem['price'].toString());
    _countController =
        TextEditingController(text: widget.inventoryItem['count'].toString());
    _buyDate = DateTime.tryParse(widget.inventoryItem['buy_date']);
  }

  void _saveInventoryItem() async {
    if (_formKey.currentState!.validate()) {
      final priceValue = double.tryParse(_priceController.text) ?? 0.0;
      final countValue = int.tryParse(_countController.text) ?? 1;
      final formattedBuyDate = _buyDate?.toIso8601String() ?? '';

      await _dbHelper.updateInventory(
        widget.inventoryItem['id'],
        _nameController.text,
        _descriptionController.text,
        _linkController.text,
        priceValue,
        countValue,
        formattedBuyDate,
      );

      const SnackBar(
        content: Text('Inventory item updated successfully!'),
        duration: Duration(seconds: 2),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Inventory Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required field' : null,
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
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null
                    ? 'Enter a valid number'
                    : null,
              ),
              TextFormField(
                controller: _countController,
                decoration: const InputDecoration(labelText: 'Count'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null ||
                        value.isEmpty ||
                        int.tryParse(value) == null
                    ? 'Enter a valid number'
                    : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _buyDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            _buyDate = selectedDate;
                          });
                        }
                      },
                      child: Text(_buyDate == null
                          ? 'Select Buy Date'
                          : 'Buy Date: ${_buyDate.toString().split(' ')[0]}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveInventoryItem,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
