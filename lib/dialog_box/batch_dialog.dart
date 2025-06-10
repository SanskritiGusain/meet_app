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
  final _formKey = GlobalKey<FormState>();

  late TextEditingController batchNameController;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  // Track which fields have been touched/interacted with
  bool _batchTitleTouched = false;
  bool _startTimeTouched = false;
  bool _endTimeTouched = false;

  bool get isEditing => widget.batch != null;

  // Validation logic
  bool get isFormValid {
    if (isEditing) {
      // For editing: only batch title is required (can't be empty)
      return batchNameController.text.trim().isNotEmpty;
    } else {
      // For adding: all fields are required
      return batchNameController.text.trim().isNotEmpty &&
             startTime != null &&
             endTime != null;
    }
  }

  // Error message getters - only show errors after user interaction
  String? get batchTitleError {
    if (_batchTitleTouched && batchNameController.text.trim().isEmpty) {
      return isEditing ? 'Batch title is invalid' : 'Batch title is required';
    }
    return null;
  }

  String? get startTimeError {
    if (!isEditing && _startTimeTouched && startTime == null) {
      return 'Start time is required';
    }
    return null;
  }

  String? get endTimeError {
    if (!isEditing && _endTimeTouched && endTime == null) {
      return 'End time is required';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    batchNameController =
        TextEditingController(text: widget.batch?.batchName ?? '');

    if (widget.batch != null) {
      debugPrint('Parsing start time: "${widget.batch!.startTime}"');
      debugPrint('Parsing end time: "${widget.batch!.endTime}"');
      
      startTime = _parseTime(widget.batch!.startTime);
      endTime = _parseTime(widget.batch!.endTime);
      
      debugPrint('Parsed start time: $startTime');
      debugPrint('Parsed end time: $endTime');
    }

    // Add listener to batch name controller to rebuild when text changes
    batchNameController.addListener(() {
      setState(() {
        // This will trigger a rebuild and update button state
      });
    });
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    try {
      // Try multiple formats to handle different time string formats
      List<DateFormat> formats = [
        DateFormat.jm(),     // 12-hour format like "3:30 PM"
        DateFormat('h:mm a'), // Alternative 12-hour format
        DateFormat('hh:mm a'), // Alternative with leading zero
        DateFormat('H:mm'),   // 24-hour format like "15:30"
        DateFormat('HH:mm'),  // 24-hour format with leading zero
      ];
      
      for (DateFormat format in formats) {
        try {
          final dateTime = format.parse(timeString);
          return TimeOfDay.fromDateTime(dateTime);
        } catch (e) {
          // Try next format
          continue;
        }
      }
      
      // If all DateFormat parsing fails, try manual parsing
      // Handle formats like "3:30 PM", "15:30", etc.
      String cleanTime = timeString.trim();
      
      // Check for AM/PM
      bool isPM = cleanTime.toUpperCase().contains('PM');
      bool isAM = cleanTime.toUpperCase().contains('AM');
      
      // Remove AM/PM and clean up
      cleanTime = cleanTime.replaceAll(RegExp(r'[APMapm\s]'), '');
      
      // Split by colon
      final parts = cleanTime.split(':');
      if (parts.length >= 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;
        
        // Convert 12-hour to 24-hour if needed
        if (isPM && hour != 12) {
          hour += 12;
        } else if (isAM && hour == 12) {
          hour = 0;
        }
        
        return TimeOfDay(hour: hour, minute: minute);
      }
      
    } catch (e) {
      debugPrint('Time parsing failed for "$timeString": $e');
    }
    
    return null;
  }

  // Demo-style time picker matching your screenshot
  Future<TimeOfDay?> _showDemoStyleTimePicker(TimeOfDay? initialTime) async {
    TimeOfDay selectedTime = initialTime ?? TimeOfDay.now();
    int selectedHourIndex = selectedTime.hourOfPeriod == 0 ? 11 : selectedTime.hourOfPeriod - 1;
    int selectedMinuteIndex = selectedTime.minute;
    int selectedPeriodIndex = selectedTime.period == DayPeriod.am ? 0 : 1;
    
    // Create scroll controllers for each list
    final hourController = ScrollController(initialScrollOffset: selectedHourIndex * 56.0);
    final minuteController = ScrollController(initialScrollOffset: selectedMinuteIndex * 56.0);
    final periodController = ScrollController(initialScrollOffset: selectedPeriodIndex * 56.0);
    
    return await showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 280,
              
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text(
                      'Select Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Time picker content
                    Container(
                      height: 240,
                       width: 240,
                      child: Row(
                        children: [
                          // Hours list
                          Expanded(
                            child: _buildTimeColumn(
                              controller: hourController,
                              itemCount: 12,
                              selectedIndex: selectedHourIndex,
                              itemBuilder: (index) {
                                final hour = (index % 12) + 1;
                                return hour.toString().padLeft(2, '0');
                              },
                              onItemSelected: (index) {
                                setDialogState(() {
                                  selectedHourIndex = index;
                                });
                                final hour = (index % 12) + 1;
                                selectedTime = selectedTime.replacing(
                                  hour: selectedTime.period == DayPeriod.am 
                                    ? (hour == 12 ? 0 : hour)
                                    : (hour == 12 ? 12 : hour + 12),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Minutes list
                          Expanded(
                            child: _buildTimeColumn(
                              controller: minuteController,
                              itemCount: 60,
                              selectedIndex: selectedMinuteIndex,
                              itemBuilder: (index) => index.toString().padLeft(2, '0'),
                              onItemSelected: (index) {
                                setDialogState(() {
                                  selectedMinuteIndex = index;
                                });
                                selectedTime = selectedTime.replacing(minute: index);
                              },
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // AM/PM list
                          Container(
                            width: 60,
                            child: _buildTimeColumn(
                              controller: periodController,
                              itemCount: 2,
                              selectedIndex: selectedPeriodIndex,
                              itemBuilder: (index) => index == 0 ? 'AM' : 'PM',
                              onItemSelected: (index) {
                                setDialogState(() {
                                  selectedPeriodIndex = index;
                                });
                                final period = index == 0 ? DayPeriod.am : DayPeriod.pm;
                                final currentHour = selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod;
                                selectedTime = selectedTime.replacing(
                                  hour: period == DayPeriod.am 
                                    ? (currentHour == 12 ? 0 : currentHour)
                                    : (currentHour == 12 ? 12 : currentHour + 12),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            hourController.dispose();
                            minuteController.dispose();
                            periodController.dispose();
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {
                              hourController.dispose();
                              minuteController.dispose();
                              periodController.dispose();
                              Navigator.of(context).pop(selectedTime);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            ),
                            child: const Text('OK'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeColumn({
    required ScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required String Function(int) itemBuilder,
    required void Function(int) onItemSelected,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemExtent: 56,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        
        return GestureDetector(
          onTap: () {
            onItemSelected(index);
            // Scroll to selected item
            controller.animateTo(
              index * 56.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            height: 50,
            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[300] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              itemBuilder(index),
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 253, 250, 250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        isEditing ? 'Edit Batch' : 'Add Batch',
        style: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.w600
        ),
      ),
      content: Form(
        key: _formKey,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: 200,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Batch Title TextField
                TextField(
                  controller: batchNameController,
                  style: TextStyle(fontSize: 16),
                  onChanged: (value) {
                    // Mark as touched when user starts typing
                    if (!_batchTitleTouched) {
                      setState(() {
                        _batchTitleTouched = true;
                      });
                    }
                  },
                  onSubmitted: (value) {
                    if (!_batchTitleTouched) {
                      setState(() {
                        _batchTitleTouched = true;
                      });
                    }
                  },
                  onTapOutside: (event) {
                    FocusScope.of(context).unfocus();
                    if (!_batchTitleTouched) {
                      setState(() {
                        _batchTitleTouched = true;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Batch Title *',
                    labelStyle: TextStyle(color: const Color.fromARGB(255, 136, 134, 134), fontSize: 14),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: batchTitleError != null ? Colors.red : Colors.black12,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: batchTitleError != null ? Colors.red : const Color.fromARGB(255, 136, 134, 134),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black12),
                    ),
                  ),
                ),
                
                // Error message for batch title
                if (batchTitleError != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      batchTitleError!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Time Buttons Row - Side by Side with Full Width
                Row(
                  children: [
                    // Start Time Button - Takes full width of available space
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () async {
                                // Mark as touched when button is pressed
                                if (!_startTimeTouched) {
                                  setState(() {
                                    _startTimeTouched = true;
                                  });
                                }
                                
                                final time = await _showDemoStyleTimePicker(startTime);
                                if (time != null) {
                                  setState(() {
                                    startTime = time;
                                  });
                                }
                              },
                              style: _timeButtonStyle(
                                hasValue: startTime != null,
                                hasError: startTimeError != null,
                              ),
                              child: Text(
                                startTime?.format(context) ?? 'Start Time${!isEditing ? ' *' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: startTime != null 
                                    ? Colors.black
                                    : Color.fromARGB(255, 136, 134, 134),
                                ),
                              ),
                            ),
                          ),
                          // Error message for start time
                          SizedBox(
                            height: 24, // Fixed height for error message space
                            child: startTimeError != null 
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8, top: 4),
                                  child: Text(
                                    startTimeError!,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8), // Small space between buttons
                    
                    // End Time Button - Takes full width of available space
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () async {
                                // Mark as touched when button is pressed
                                if (!_endTimeTouched) {
                                  setState(() {
                                    _endTimeTouched = true;
                                  });
                                }
                                
                                final time = await _showDemoStyleTimePicker(endTime);
                                if (time != null) {
                                  setState(() {
                                    endTime = time;
                                  });
                                }
                              },
                              style: _timeButtonStyle(
                                hasValue: endTime != null,
                                hasError: endTimeError != null,
                              ),
                              child: Text(
                                endTime?.format(context) ?? 'End Time${!isEditing ? ' *' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: endTime != null 
                                    ? Colors.black
                                    : Color.fromARGB(255, 136, 134, 134),
                                ),
                              ),
                            ),
                          ),
                          // Error message for end time
                          SizedBox(
                            height: 24, // Fixed height for error message space
                            child: endTimeError != null 
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8, top: 4),
                                  child: Text(
                                    endTimeError!,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
              ],
            ),
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
          onPressed: isFormValid ? () {
            final newBatch = Batch(
              id: widget.batch?.id,
              batchName: batchNameController.text.trim(),
              batchDate: '',
              startTime: startTime?.format(context) ??
                  widget.batch?.startTime ??
                  '',
              endTime: endTime?.format(context) ??
                  widget.batch?.endTime ??
                  '',
              createdAt: widget.batch?.createdAt ?? DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            debugPrint('Returning batch: $newBatch');
            Navigator.pop(context, newBatch);
          } : null, // Disable button when form is invalid
          style: _addEditButtonStyle(isEnabled: isFormValid),
          child: Text(isEditing ? 'EDIT' : 'ADD'),
        ),
      ],
    );
  }

  ButtonStyle _timeButtonStyle({bool hasValue = false, bool hasError = false}) => TextButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor:
            hasValue ? Colors.black : const Color.fromARGB(255, 85, 84, 84),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: hasError ? Colors.red : Colors.black12,
          ),
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

  ButtonStyle _addEditButtonStyle({bool isEnabled = true}) => TextButton.styleFrom(
        backgroundColor: isEnabled 
            ? const Color.fromARGB(255, 39, 38, 38)
            : const Color.fromARGB(255, 158, 158, 158), // Disabled color
        foregroundColor: isEnabled
            ? const Color.fromARGB(255, 244, 244, 244)
            : const Color.fromARGB(255, 189, 189, 189), // Disabled text color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      );

  @override
  void dispose() {
    batchNameController.dispose();
    super.dispose();
  }
}