import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/student_model.dart';

class AttendanceFilterDialog extends StatefulWidget {
  const AttendanceFilterDialog({Key? key}) : super(key: key);

  @override
  State<AttendanceFilterDialog> createState() => _AttendanceFilterDialogState();
}

class _AttendanceFilterDialogState extends State<AttendanceFilterDialog> {
  final TextEditingController dateController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool uniqueOnly = false;

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 253, 250, 250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Filter Attendance',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 220,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Date Filter TextField
              TextField(
                controller: dateController,
                readOnly: true,
                enableInteractiveSelection: false,
                showCursor: false,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Date Filter',
                  labelStyle: TextStyle(color: const Color.fromARGB(255, 136, 134, 134), fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color.fromRGBO(0, 0, 0, 0.122)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color.fromARGB(255, 136, 134, 134)),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black12),
                  ),
                ),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2016),
                    lastDate: DateTime(2040),
                    // Solution 2: If you need custom sizing, use this safer approach
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          // Disable text scaling to prevent layout issues
                          textScaleFactor: 1.0,
                        ),
                        child: Container(
                          // Use container constraints instead of Transform.scale
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                            maxWidth: MediaQuery.of(context).size.width * 0.9,
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dialogTheme: DialogTheme(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            child: child!,
                          ),
                        ),
                      );
                    },
                  );
                  
                  if (pickedDate != null) {
                    dateController.text =
                       '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                  }
                },
              ),
              SizedBox(height: 12),

              // Start and End Time Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? TimeOfDay.now(),
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                // Disable text scaling to prevent layout issues
                                textScaleFactor: 1.0,
                              ),
                              child: Container(
                                // Use container constraints instead of Transform.scale
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dialogTheme: DialogTheme(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                ),
                              ),
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            startTime = picked;
                          });
                        }
                      },
                      style: _timeButtonStyle(hasValue: startTime != null),
                      child: Text(
                        startTime == null
                            ? 'Start Time'
                            : startTime!.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: startTime != null 
                            ? Colors.black
                            : Color.fromARGB(255, 136, 134, 134),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? TimeOfDay.now(),
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                // Disable text scaling to prevent layout issues
                                textScaleFactor: 1.0,
                              ),
                              child: Container(
                                // Use container constraints instead of Transform.scale
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dialogTheme: DialogTheme(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                ),
                              ),
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            endTime = picked;
                          });
                        }
                      },
                      style: _timeButtonStyle(hasValue: endTime != null),
                      child: Text(
                        endTime == null 
                            ? 'End Time'
                            : endTime!.format(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: endTime != null 
                            ? Colors.black
                            : Color.fromARGB(255, 136, 134, 134),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Unique Checkbox
              Row(
                children: [
                  Checkbox(
                    value: uniqueOnly,
                    onChanged: (value) {
                      setState(() {
                        uniqueOnly = value ?? false;
                      });
                    },
                    activeColor: const Color.fromARGB(255, 39, 38, 38),
                  ),
                  Text(
                    'Unique',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
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
          child: const Text('CLOSE'),
        ),
        ElevatedButton(
          onPressed: () {
            final filterData = {
              'date': dateController.text.trim(),
              'startTime': startTime?.format(context),
              'endTime': endTime?.format(context),
              'uniqueOnly': uniqueOnly,
            };
            Navigator.pop(context, filterData);
          },
          style: _filterButtonStyle(),
          child: Text('FILTER'),
        ),
      ],
    );
  }

  ButtonStyle _timeButtonStyle({bool hasValue = false}) => TextButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: hasValue 
          ? Colors.black
          : const Color.fromARGB(255, 85, 84, 84),
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
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  ButtonStyle _filterButtonStyle() => TextButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 39, 38, 38),
        foregroundColor: const Color.fromARGB(255, 244, 244, 244),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      );
}