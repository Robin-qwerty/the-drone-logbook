import 'package:flutter/material.dart';
import '../database_helper.dart';

class AddResistanceScreen extends StatefulWidget {
  final int batteryId;
  final int cellCount;

  const AddResistanceScreen(
      {super.key, required this.batteryId, required this.cellCount});

  @override
  _AddResistanceScreenState createState() => _AddResistanceScreenState();
}

class _AddResistanceScreenState extends State<AddResistanceScreen> {
  late List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      widget.cellCount,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveResistance() async {
    final resistances = {
      for (int i = 0; i < controllers.length; i++)
        'resistance_c${i + 1}': double.tryParse(controllers[i].text) ?? 0.0,
    };

    await DatabaseHelper().addInternalResistance(
      batteryId: widget.batteryId,
      resistances: resistances,
    );

    Navigator.of(context).pop(); // Return to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Battery Resistance')),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < widget.cellCount; i++)
              TextField(
                controller: controllers[i],
                decoration: InputDecoration(
                  labelText: 'Resistance C${i + 1} (mΩ)',
                ),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveResistance,
              child: const Text('Save Resistance'),
            ),
          ],
        ),
      ),
    );
  }
}
