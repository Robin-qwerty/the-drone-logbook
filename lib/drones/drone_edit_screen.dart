import 'package:flutter/material.dart';
import '../database_helper.dart';

class DroneEditScreen extends StatefulWidget {
  final Map<String, dynamic> drone;

  const DroneEditScreen({super.key, required this.drone});

  @override
  _DroneEditScreenState createState() => _DroneEditScreenState();
}

class _DroneEditScreenState extends State<DroneEditScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _frameController;
  late TextEditingController _escController;
  late TextEditingController _fcController;
  late TextEditingController _vtxController;
  late TextEditingController _antennaController;
  late TextEditingController _receiverController;
  late TextEditingController _motorsController;
  late TextEditingController _cameraController;
  late TextEditingController _propsController;
  late TextEditingController _buzzerController;
  late TextEditingController _weightController;

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.drone['name']);
    _descriptionController =
        TextEditingController(text: widget.drone['description']);
    _frameController = TextEditingController(text: widget.drone['frame']);
    _escController = TextEditingController(text: widget.drone['esc']);
    _fcController = TextEditingController(text: widget.drone['fc']);
    _vtxController = TextEditingController(text: widget.drone['vtx']);
    _antennaController = TextEditingController(text: widget.drone['antenna']);
    _receiverController = TextEditingController(text: widget.drone['receiver']);
    _motorsController = TextEditingController(text: widget.drone['motors']);
    _cameraController = TextEditingController(text: widget.drone['camera']);
    _propsController = TextEditingController(text: widget.drone['props']);
    _buzzerController = TextEditingController(text: widget.drone['buzzer']);
    _weightController = TextEditingController(text: widget.drone['weight']);
  }

  void _saveDrone() async {
    if (_formKey.currentState!.validate()) {
      await _dbHelper.updateDrone(
        widget.drone['id'],
        _nameController.text,
        _descriptionController.text,
        _frameController.text,
        _escController.text,
        _fcController.text,
        _vtxController.text,
        _antennaController.text,
        _receiverController.text,
        _motorsController.text,
        _cameraController.text,
        _propsController.text,
        _buzzerController.text,
        _weightController.text,
      );
      _showSnackbar('Drone edited successfully!');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drone Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Drone Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required field' : null,
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
                decoration:
                    const InputDecoration(labelText: 'Flight Controller'),
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
                decoration: const InputDecoration(labelText: 'Weight (g)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveDrone,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
