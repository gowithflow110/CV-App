// lib/modules/cv_preview/widgets/cv_section_card.dart
import 'package:flutter/material.dart';
import 'package:cvapp/routes/app_routes.dart';


class CVSectionCard extends StatelessWidget {
  final String sectionId;
  final String title;
  final String content;
  final Function(String)? onSave;

  const CVSectionCard({
    super.key,
    required this.sectionId,
    required this.title,
    required this.content,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final updatedContent =
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.editCVSection,
                      arguments: {
                        'sectionId': sectionId,
                        'title': title,
                        'content': content,
                      },
                    ) as String?;

                    if (updatedContent != null && onSave != null) {
                      onSave!(updatedContent);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
