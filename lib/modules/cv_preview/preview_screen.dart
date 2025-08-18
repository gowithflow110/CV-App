// lib/modules/cv_preview/cv_preview_screen.dart

import 'package:flutter/material.dart';
import '../../models/cv_model.dart'; // ✅ Make sure this is correct

class CVPreviewScreen extends StatelessWidget {
  final CVModel cvData;

  const CVPreviewScreen({super.key, required this.cvData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("CV Preview"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cvData.name ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(cvData.title ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87)),
            const SizedBox(height: 10),
            Text(cvData.summary ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 20),

            /// Contact Info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.blue.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  contactItem(Icons.email, cvData.email ?? ''),
                  contactItem(Icons.phone, cvData.phone ?? ''),
                  contactItem(Icons.location_on, cvData.location ?? ''),
                  contactItem(Icons.link, cvData.linkedin ?? ''),
                ],
              ),
            ),
            const SizedBox(height: 25),

            /// Skills
            sectionHeader("SKILLS"),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: (cvData.skills ?? [])
                  .map((skill) => Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(skill, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ))
                  .toList(),
            ),
            const SizedBox(height: 30),

            /// Work Experience
            sectionHeader("WORK EXPERIENCE"),
            const SizedBox(height: 12),
            Column(
              children: (cvData.experiences ?? [])
                  .map((exp) => workExperience(exp))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget contactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  Widget sectionHeader(String text) {
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget workExperience(CVExperience exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exp.position ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(exp.company ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(exp.location ?? '', style: const TextStyle(color: Colors.grey)),
              Text("${exp.startDate ?? ''} - ${exp.endDate ?? ''}", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: (exp.responsibilities ?? [])
                .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontSize: 14)),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ))
                .toList(),
          )
        ],
      ),
    );
  }
}
