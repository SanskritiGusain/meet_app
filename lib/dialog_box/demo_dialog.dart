import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/demo_model.dart';

class DemoDialog extends StatefulWidget {
  final Demo? demo;

  const DemoDialog({Key? key, this.demo}) : super(key: key);

  @override
  State<DemoDialog> createState() => _DemoDialogState();
}

class _DemoDialogState extends State<DemoDialog> {
  late TextEditingController titleController;
  late TextEditingController linkController;
  final TextEditingController dateController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.demo?.title ?? '');
    linkController = TextEditingController(text: widget.demo?.link ?? '');

    if (widget.demo != null) {
      dateController.text = widget.demo!.demoDate;
      startTime = _parseTime(widget.demo!.startTime);
      endTime = _parseTime(widget.demo!.endTime);
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final format = DateFormat.jm(); // e.g. 8:27 PM
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      debugPrint('Time parsing failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    linkController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 253, 250, 250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(widget.demo == null ? 'Add Demo' : 'Edit Demo'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Demo Title *',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link *',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Demo Date *',
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    dateController.text =
                        '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            startTime = picked;
                          });
                        }
                      },
                      style: _timeButtonStyle(),
                      child: Text(
                        startTime == null
                            ? 'Start Time *'
                            : startTime!.format(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            endTime = picked;
                          });
                        }
                      },
                      style: _timeButtonStyle(),
                      child: Text(
                        endTime == null
                            ? 'End Time *'
                            : endTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: _cancelButtonStyle(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            final newDemo = Demo(
              title: titleController.text,
              link: linkController.text,
              demoDate: dateController.text,
              startTime: startTime?.format(context) ?? '',
              endTime: endTime?.format(context) ?? '',
              createdOn: widget.demo?.createdOn ?? DateTime.now().toString(),
            );
            Navigator.pop(context, newDemo);
          },
          style: _addEditButtonStyle(),
          child: Text(widget.demo == null ? 'ADD' : 'EDIT'),
        ),
      ],
    );
  }

  ButtonStyle _timeButtonStyle() => TextButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 253, 250, 250),
        foregroundColor: const Color.fromARGB(255, 85, 84, 84),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black12),
        ),
      );

  ButtonStyle _cancelButtonStyle() => TextButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 253, 250, 250),
        foregroundColor: const Color.fromARGB(255, 36, 36, 36),
        side: const BorderSide(
          color: Color.fromARGB(255, 21, 21, 21),
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  ButtonStyle _addEditButtonStyle() => TextButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 39, 38, 38),
        foregroundColor: const Color.fromARGB(255, 244, 244, 244),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      );
}
