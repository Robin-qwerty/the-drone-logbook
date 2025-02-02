import 'package:flutter/material.dart';
import '../database_helper.dart';

class DroneFormScreen extends StatefulWidget {
  const DroneFormScreen({super.key});

  @override
  _DroneFormScreenState createState() => _DroneFormScreenState();
}

class _DroneFormScreenState extends State<DroneFormScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _frameController = TextEditingController();
  final TextEditingController _escController = TextEditingController();
  final TextEditingController _fcController = TextEditingController();
  final TextEditingController _vtxController = TextEditingController();
  final TextEditingController _antennaController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _motorsController = TextEditingController();
  final TextEditingController _cameraController = TextEditingController();
  final TextEditingController _propsController = TextEditingController();
  final TextEditingController _buzzerController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addDrone() async {
    if (_formKey.currentState!.validate()) {
      await _dbHelper.insertDrone({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'frame': _frameController.text,
        'esc': _escController.text,
        'fc': _fcController.text,
        'vtx': _vtxController.text,
        'antenna': _antennaController.text,
        'receiver': _receiverController.text,
        'motors': _motorsController.text,
        'camera': _cameraController.text,
        'props': _propsController.text,
        'buzzer': _buzzerController.text,
        'weight': _weightController.text,
      });

      _showSnackbar('Drone added successfully!');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Drone')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Drone Name*'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Name is required'
                      : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: _frameController,
                  decoration: const InputDecoration(labelText: 'Frame'),
                ),
                TextFormField(
                  controller: _escController,
                  decoration: const InputDecoration(labelText: 'ESC'),
                ),
                TextFormField(
                  controller: _fcController,
                  decoration: const InputDecoration(labelText: 'Flight Controller'),
                ),
                TextFormField(
                  controller: _vtxController,
                  decoration: const InputDecoration(labelText: 'VTX'),
                ),
                TextFormField(
                  controller: _antennaController,
                  decoration: const InputDecoration(labelText: 'Antenna'),
                ),
                TextFormField(
                  controller: _receiverController,
                  decoration: const InputDecoration(labelText: 'Receiver'),
                ),
                TextFormField(
                  controller: _motorsController,
                  decoration: const InputDecoration(labelText: 'Motors'),
                ),
                TextFormField(
                  controller: _cameraController,
                  decoration: const InputDecoration(labelText: 'Camera'),
                ),
                TextFormField(
                  controller: _propsController,
                  decoration: const InputDecoration(labelText: 'Props'),
                ),
                TextFormField(
                  controller: _buzzerController,
                  decoration: const InputDecoration(labelText: 'Buzzer'),
                ),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Weight (grams)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addDrone,
                  child: const Text('Add Drone'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
