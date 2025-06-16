import 'package:flutter/material.dart';
import 'dart:io';

class ProjectProfileScreen extends StatefulWidget {
  final bool isOfficeOwner;
  const ProjectProfileScreen({required this.isOfficeOwner, super.key});

  @override
  State<ProjectProfileScreen> createState() => _ProjectProfileScreenState();
}

class _ProjectProfileScreenState extends State<ProjectProfileScreen> {
  bool isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  File? licenseFile;
  File? agreementFile;

  final Map<String, dynamic> formData = {
    "name": "Smart Tower",
    "description": "Smart eco-friendly building project",
    "status": "Pending",
    "budget": "1500000.00",
    "start_date": "2024-06-01",
    "end_date": "2025-06-01",
    "location": "Downtown, Cairo",
  };

  void _toggleEdit() {
    if (isEditMode && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: send PUT/PATCH to backend
    }
    setState(() => isEditMode = !isEditMode);
  }

  Widget _buildField(String label, String field, {bool editable = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (isEditMode && editable)
          TextFormField(
            initialValue: formData[field],
            onSaved: (val) => formData[field] = val,
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(formData[field]),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField("Project Name", "name"),
              _buildField("Description", "description"),
              _buildField("Budget", "budget"),
              _buildField("Start Date", "start_date"),
              _buildField("End Date", "end_date"),
              _buildField("Location", "location"),
              _buildField("Status", "status", editable: widget.isOfficeOwner),
              const SizedBox(height: 10),
              if (widget.isOfficeOwner)
                ElevatedButton(
                  onPressed: _toggleEdit,
                  child: Text(isEditMode ? "Save" : "Edit"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
