import 'package:flutter/material.dart';
import 'package:my_app/models/teacher_model.dart';

class TeacherDialog extends StatefulWidget {
  final Teacher? teacher;
  final void Function(String name, String loginId, String password)? onSave;

  const TeacherDialog({Key? key, this.teacher, this.onSave}) : super(key: key);

  @override
  State<TeacherDialog> createState() => _TeacherDialogState();
}

class _TeacherDialogState extends State<TeacherDialog> {
  late TextEditingController nameController;
  late TextEditingController loginIdController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.teacher?.name ?? '');
    loginIdController = TextEditingController(text: widget.teacher?.loginId ?? '');
    passwordController = TextEditingController(text: widget.teacher?.password ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    loginIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 253, 250, 250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(widget.teacher == null ? 'Add Teacher' : 'Edit Teacher'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Teacher Name *',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: loginIdController,
                decoration: const InputDecoration(
                  labelText: 'Login ID *',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color.fromARGB(255, 36, 36, 36),
            side: const BorderSide(color: Color.fromARGB(255, 21, 21, 21), width: 2.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.onSave != null) {
              widget.onSave!(
                nameController.text.trim(),
                loginIdController.text.trim(),
                passwordController.text.trim(),
              );
            }
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 39, 38, 38),
            foregroundColor: const Color.fromARGB(255, 244, 244, 244),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
          child: Text(widget.teacher == null ? 'ADD' : 'EDIT'),
        ),
      ],
    );
  }
}
