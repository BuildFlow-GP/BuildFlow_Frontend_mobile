import 'package:buildflow_frontend/models/Basic/project_model.dart';
import 'package:buildflow_frontend/screens/map/parcel_viewer_screen.dart';
import 'package:flutter/material.dart';
// ⭐️⭐️⭐️ استيراد الشاشة الجديدة ⭐️⭐️⭐️

class LicenseFormScreen extends StatefulWidget {
  const LicenseFormScreen({super.key});

  @override
  State<LicenseFormScreen> createState() => _LicenseFormScreenState();
}

class _LicenseFormScreenState extends State<LicenseFormScreen> {
  // يمكنك الاحتفاظ بكل Controllers الخاصة ببيانات المشروع هنا
  final TextEditingController _projectNameController = TextEditingController(
    text: 'My Project',
  );
  final TextEditingController _landAreaController = TextEditingController(
    text: '1000',
  );
  // ... أي Controllers أخرى لبيانات الترخيص/المشروع

  ProjectModel _currentProject = ProjectModel(
    id: 1, // مثال ID
    name: 'Default Project',
    createdAt: DateTime.now(),
    // هنا لن يكون هناك RegionName, BasinNumber, PlotNumber, Coordinates مباشرة
    // هذه البيانات تدار الآن بواسطة شاشة ParcelViewerScreen بشكل منفصل للعرض
  );

  @override
  void dispose() {
    _projectNameController.dispose();
    _landAreaController.dispose();
    // ... dispose other controllers
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('License Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // حقول نموذج الترخيص الخاصة بكِ
            TextField(
              controller: _projectNameController,
              decoration: const InputDecoration(labelText: 'Project Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _landAreaController,
              decoration: const InputDecoration(labelText: 'Land Area (sqm)'),
              keyboardType: TextInputType.number,
            ),
            // ... أي حقول أخرى لنموذج الترخيص
            const SizedBox(height: 30),
            // ⭐️⭐️⭐️ زر لفتح شاشة عرض القطعة الجديدة ⭐️⭐️⭐️
            ElevatedButton.icon(
              onPressed: () {
                // ببساطة ننتقل إلى شاشة عرض القطعة
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParcelViewerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('View Land on Map & Route'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // هنا ستقومين بحفظ جميع بيانات مشروعك
                print('Saving License Data:');
                print('Project Name: ${_projectNameController.text}');
                print('Land Area: ${_landAreaController.text}');
                // ... طباعة/حفظ أي بيانات مشروع أخرى

                _showSnackBar('License data saved.');
              },
              child: const Text('Save License Data'),
            ),
          ],
        ),
      ),
    );
  }
}
