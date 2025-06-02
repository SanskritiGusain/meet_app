import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/batch_model.dart';


class BatchDialog extends StatefulWidget {
  final Batch? batch;

  const BatchDialog({Key? key, this.batch}) : super(key: key);

  @override
  State<BatchDialog> createState() => _BatchDialogState();
}

class _BatchDialogState extends State<BatchDialog> {
  late TextEditingController batchNameController;
  late TextEditingController batchLinkController;
  final TextEditingController dateController = TextEditingController();
  late TextEditingController createdOnController;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void initState() {
    super.initState();
    batchNameController = TextEditingController(text: widget.batch?.batchName ?? '#Untitled');
    batchLinkController = TextEditingController(text: widget.batch?.batchLink ?? '');

    createdOnController = TextEditingController(text: widget.batch?.createdOn ?? '');

    if (widget.batch != null) {
       dateController.text = widget.batch!.batchDate;
      startTime = _parseTime(widget.batch!.startTime);
      endTime = _parseTime(widget.batch!.endTime);
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
    batchNameController.dispose();
    batchLinkController.dispose();
    dateController.dispose();
    createdOnController.dispose();
    super.dispose();
  }


 


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 253, 250, 250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(widget.batch == null ? 'Add Batch' : 'Edit Batch'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              TextField(
                controller: batchNameController,
                decoration: const InputDecoration(
                  labelText: 'Batch Title *',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),

              // Batch Link
              TextField(
                controller: batchLinkController,
                decoration: const InputDecoration(
                  labelText: 'Batch Link',
                ),
              ),
              const SizedBox(height: 8),

              // Batch Date (date for batch, different from createdOn)
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Batch Date *',
                ),
                onTap: () async {
          
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate:  DateTime.now(),
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
              const SizedBox(height: 8),

              // Start and End Time Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? TimeOfDay.now(),
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
                          initialTime: endTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            endTime = picked;
                          });
                        }
                      },
                      style: _timeButtonStyle(),
                      child: Text(
                        endTime == null ? 'End Time *' : endTime!.format(context),
                      ),
                    ),
                  ),
                ],
              )
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
          
            final newBatch = Batch(
              id: widget.batch?.id,
              batchName: batchNameController.text.trim(),
              batchLink: batchLinkController.text.trim(),
              batchDate: dateController.text.trim(),
              startTime: startTime!.format(context),
              endTime: endTime!.format(context),
              createdOn: createdOnController.text.trim(),
            );

            Navigator.pop(context, newBatch);
          },
          style: _addEditButtonStyle(),
          child: Text(widget.batch == null ? 'ADD' : 'EDIT'),
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