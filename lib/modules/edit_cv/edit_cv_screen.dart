import 'package:flutter/material.dart';

class EditCVSectionScreen extends StatelessWidget {
  final String sectionKey;
  final String sectionValue;

  const EditCVSectionScreen({
    super.key,
    required this.sectionKey,
    required this.sectionValue,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: sectionValue);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit $sectionKey'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Edit $sectionKey',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
