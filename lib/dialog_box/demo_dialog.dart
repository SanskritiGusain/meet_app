import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/demo_model.dart';

// Utility class for consistent timezone handling
class TimezoneUtils {
  static const Duration istOffset = Duration(hours: 5, minutes: 30);
  
  /// Converts UTC DateTime to IST DateTime
  static DateTime utcToIst(DateTime utcDateTime) {
    return utcDateTime.toUtc().add(istOffset);
  }
  
  /// Converts IST DateTime to UTC DateTime
  static DateTime istToUtc(DateTime istDateTime) {
    return istDateTime.subtract(istOffset).toUtc();
  }
  
  /// Formats UTC DateTime to IST string for display
  static String formatUtcToIstString(dynamic dateTime, {bool includeTime = true}) {
    try {
      DateTime utcDateTime;
      
      if (dateTime is String) {
        utcDateTime = DateTime.parse(dateTime).toUtc();
      } else if (dateTime is DateTime) {
        utcDateTime = dateTime.toUtc();
      } else {
        return includeTime ? 'Invalid date' : 'Invalid date';
      }
      
      final istDateTime = utcToIst(utcDateTime);
      
      if (includeTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(istDateTime);
      } else {
        return DateFormat('dd/MM/yyyy').format(istDateTime);
      }
    } catch (e) {
      debugPrint('DateTime formatting error: $e');
      return dateTime.toString();
    }
  }
  
  /// Parses date string handling multiple formats
  static DateTime? parseDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      if (dateString.contains('T')) {
        // ISO format with time - treat as UTC
        return DateTime.parse(dateString).toUtc();
      } else if (dateString.contains('/')) {
        // DD/MM/YYYY format - local date
        return DateFormat('dd/MM/yyyy').parse(dateString);
      } else if (dateString.contains('-') && dateString.length >= 10) {
        // YYYY-MM-DD format - local date
        return DateTime.parse(dateString.substring(0, 10));
      } else {
        return DateTime.parse(dateString);
      }
    } catch (e) {
      debugPrint('Date parsing error: $e');
      return null;
    }
  }
}

class _TimePickerItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontSize;

  const _TimePickerItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color.fromARGB(255, 39, 38, 38).withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected 
              ? const Color.fromARGB(255, 39, 38, 38)
              : const Color.fromARGB(255, 136, 134, 134),
          ),
        ),
      ),
    );
  }
}

// Custom Calendar Date Picker
class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDatePicker({
    Key? key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime currentMonth;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    currentMonth = widget.initialDate ?? DateTime.now();
    selectedDate = widget.initialDate;
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Make Sunday = 0
    final daysFromPreviousMonth = firstDayWeekday;
    
    List<DateTime> days = [];
    
    // Add days from previous month
    final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    final lastDayOfPreviousMonth = DateTime(previousMonth.year, previousMonth.month + 1, 0);
    
    for (int i = daysFromPreviousMonth - 1; i >= 0; i--) {
      days.add(DateTime(previousMonth.year, previousMonth.month, lastDayOfPreviousMonth.day - i));
    }
    
    // Add days from current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, day));
    }
    
    // Add days from next month to complete the grid
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    int nextMonthDays = 1;
    while (days.length < 42) { // 6 rows * 7 days
      days.add(DateTime(nextMonth.year, nextMonth.month, nextMonthDays));
      nextMonthDays++;
    }
    
    return days;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.month == currentMonth.month && date.year == currentMonth.year;
  }

  bool _isSelected(DateTime date) {
    if (selectedDate == null) return false;
    return date.year == selectedDate!.year &&
           date.month == selectedDate!.month &&
           date.day == selectedDate!.day;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
           date.month == today.month &&
           date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with month/year and navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM yyyy').format(currentMonth).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.chevron_left, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Days of week header
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return Expanded(
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 8),
            
            // Calendar grid
            SizedBox(
              height: 240, // 6 rows * 40 height
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isCurrentMonth = _isCurrentMonth(date);
                  final isSelected = _isSelected(date);
                  final isToday = _isToday(date);
                  
                  return GestureDetector(
                    onTap: () {
                      if (isCurrentMonth) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Colors.black87
                          : isToday 
                            ? Colors.grey.shade200
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.all(2),
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                            ? Colors.white
                            : isCurrentMonth
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: selectedDate != null 
                    ? () => Navigator.of(context).pop(selectedDate)
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Demo Dialog Widget
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
  late TextEditingController createdAtController;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? selectedDate;
 
  // Track which fields have been touched/interacted with
  bool _titleTouched = false;
  bool _dateTouched = false;
  bool _startTimeTouched = false;
  bool _endTimeTouched = false;
  
  bool get isEditing => widget.demo != null;

  // Add this method to handle cross-midnight validation
  bool _isValidTimeRange(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return true; // Allow if either is null
    
    // Convert times to minutes for easy comparison
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;
    
    // Allow any combination - including cross-midnight scenarios
    // This means 11:35 PM to 11:25 PM is valid (demo runs past midnight)
    return true; // Accept all time combinations
  }

  bool get isFormValid {
    if (isEditing) {
      // For editing: only title is required (can't be empty)
      return titleController.text.trim().isNotEmpty;
    } else {
      // For adding: all fields are required
      return titleController.text.trim().isNotEmpty &&
             selectedDate != null &&
             startTime != null &&
             endTime != null;
    }
  }

  // Error message getters
  String? get titleError {
    if (!isEditing && _titleTouched && titleController.text.trim().isEmpty) {
      return 'Demo title is required';
    }
    if (isEditing && _titleTouched && titleController.text.trim().isEmpty) {
      return 'Demo title is invalid';
    }
    return null;
  }

  String? get dateError {
    if (!isEditing && _dateTouched && selectedDate == null) {
      return 'Demo date is required';
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
    _initializeControllers();
    _loadDemoData();
    
    // Add listener to title controller to rebuild when text changes
    titleController.addListener(() {
      setState(() {
        // This will trigger a rebuild and update button state
      });
    });
  }

  void _initializeControllers() {
    titleController = TextEditingController(text: widget.demo?.title ?? '');
    linkController = TextEditingController(text: widget.demo?.link ?? '');
    
    // Fixed createdAt formatting
    String createdAtText = '';
    if (widget.demo?.createdAt != null) {
      createdAtText = TimezoneUtils.formatUtcToIstString(
        widget.demo!.createdAt, 
        includeTime: true
      );
    }
    createdAtController = TextEditingController(text: createdAtText);
  }

  void _loadDemoData() {
    if (widget.demo != null) {
      final demo = widget.demo!;
      
      // Load date - handle different formats
      if (demo.demoDate != null && demo.demoDate!.isNotEmpty) {
        try {
          final parsedDate = TimezoneUtils.parseDateString(demo.demoDate!);
          if (parsedDate != null) {
            selectedDate = parsedDate;
            dateController.text = DateFormat('dd/MM/yyyy').format(parsedDate);
          }
        } catch (e) {
          debugPrint('Error parsing existing date: $e');
        }
      }
      
      // Load times with debugging
      debugPrint('Loading start time: ${demo.startTime}');
      debugPrint('Loading end time: ${demo.endTime}');
      
      startTime = _parseTime(demo.startTime);
      endTime = _parseTime(demo.endTime);
      
      debugPrint('Parsed start time: $startTime');
      debugPrint('Parsed end time: $endTime');
    }
  }

  // Add the missing _parseTime method
  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    try {
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1].split(' ')[0]); // Handle AM/PM part
          
          // Handle 12-hour format with AM/PM
          if (timeString.toLowerCase().contains('pm') && hour != 12) {
            hour += 12;
          } else if (timeString.toLowerCase().contains('am') && hour == 12) {
            hour = 0;
          }
          
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      debugPrint('Time parsing error: $e');
    }
    
    return null;
  }

  /// Custom date selection method
  Future<void> _selectDate() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => CustomDatePicker(
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2016),
        lastDate: DateTime(2040),
      ),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  /// Custom list-style time picker with proper touch states
  Future<TimeOfDay?> _showCustomTimePicker(TimeOfDay? initialTime) async {
    TimeOfDay selectedTime = initialTime ?? TimeOfDay.now();
    int selectedHourIndex = selectedTime.hourOfPeriod == 0 ? 11 : selectedTime.hourOfPeriod - 1;
    int selectedMinuteIndex = selectedTime.minute;
    int selectedPeriodIndex = selectedTime.period == DayPeriod.am ? 0 : 1;
    
    // Create scroll controllers for each list
    final hourController = ScrollController(initialScrollOffset: selectedHourIndex * 50.0);
    final minuteController = ScrollController(initialScrollOffset: selectedMinuteIndex * 50.0);
    final periodController = ScrollController(initialScrollOffset: selectedPeriodIndex * 50.0);
    
    return await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 253, 250, 250),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Select Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                )),
              content: SizedBox(
                height: 220,
                width: 240,
                child: Row(
                  children: [
                    // Hours list
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color.fromARGB(255, 248, 247, 247)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          controller: hourController,
                          itemCount: 12,
                          itemExtent: 50,
                          itemBuilder: (context, index) {
                            final hour = (index % 12) + 1;
                            final isSelected = index == selectedHourIndex;
                            
                            return _TimePickerItem(
                              text: hour.toString().padLeft(2, '0'),
                              isSelected: isSelected,
                              onTap: () {
                                setDialogState(() {
                                  selectedHourIndex = index;
                                });
                                selectedTime = selectedTime.replacing(
                                  hour: selectedTime.period == DayPeriod.am 
                                    ? (hour == 12 ? 0 : hour)
                                    : (hour == 12 ? 12 : hour + 12),
                                );
                                // Scroll to selected item
                                hourController.animateTo(
                                  index * 50.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Minutes list
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color.fromARGB(255, 250, 248, 248)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          controller: minuteController,
                          itemCount: 60,
                          itemExtent: 50,
                          itemBuilder: (context, index) {
                            final isSelected = index == selectedMinuteIndex;
                            
                            return _TimePickerItem(
                              text: index.toString().padLeft(2, '0'),
                              isSelected: isSelected,
                              onTap: () {
                                setDialogState(() {
                                  selectedMinuteIndex = index;
                                });
                                selectedTime = selectedTime.replacing(minute: index);
                                // Scroll to selected item
                                minuteController.animateTo(
                                  index * 50.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // AM/PM list
                    Container(
                      width: 70,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromARGB(255, 253, 252, 252)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        controller: periodController,
                        itemCount: 2,
                        itemExtent: 50,
                        itemBuilder: (context, index) {
                          final isSelected = index == selectedPeriodIndex;
                          final text = index == 0 ? 'AM' : 'PM';
                          
                          return _TimePickerItem(
                            text: text,
                            isSelected: isSelected,
                            fontSize: 16,
                            onTap: () {
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
                              // Scroll to selected item
                              periodController.animateTo(
                                index * 50.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    hourController.dispose();
                    minuteController.dispose();
                    periodController.dispose();
                    Navigator.of(context).pop();
                  },
                  style: _cancelButtonStyle(),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    hourController.dispose();
                    minuteController.dispose();
                    periodController.dispose();
                    Navigator.of(context).pop(selectedTime);
                  },
                  style: _addEditButtonStyle(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Time selection method using custom picker
  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await _showCustomTimePicker(
      isStartTime 
        ? (startTime ?? TimeOfDay.now())
        : (endTime ?? TimeOfDay.now())
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  /// Fixed save method
  void _saveDemo() {
    String dateForAPI = '';
    
    if (selectedDate != null) {
      // For date-only fields, use YYYY-MM-DD format without timezone conversion
      dateForAPI = DateFormat('yyyy-MM-dd').format(selectedDate!);
    } else if (widget.demo?.demoDate != null && widget.demo!.demoDate!.isNotEmpty) {
      dateForAPI = widget.demo!.demoDate!;
    }
    
    // For createdAt, if it's a new demo, use current UTC time
    dynamic createdAtValue = widget.demo?.createdAt ?? DateTime.now().toUtc();
    
    final newDemo = Demo(
      id: widget.demo?.id,
      title: titleController.text.trim(),
      link: linkController.text.trim(),
      demoDate: dateForAPI,
      startTime: startTime?.format(context) ?? widget.demo?.startTime ?? '',
      endTime: endTime?.format(context) ?? widget.demo?.endTime ?? '',
      createdAt: createdAtValue,
    );

    Navigator.pop(context, newDemo);
  }

  @override
  void dispose() {
    titleController.dispose();
    linkController.dispose();
    dateController.dispose();
    createdAtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 253, 250, 250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        isEditing ? 'Edit Demo' : 'Add Demo',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 250, // Increased height to accommodate error messages
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(
                controller: titleController,
                label: 'Demo Title *',
                errorText: titleError,
                isTitleField: true,
              ),
              const SizedBox(height: 10),
              _buildDateField(),
              const SizedBox(height: 10),
              _buildTimeRow(),
              if (isEditing) ...[
                const SizedBox(height: 10),
              ],
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
          onPressed: isFormValid ? _saveDemo : null, // Disable button when form is invalid
          style: _addEditButtonStyle(isEnabled: isFormValid),
          child: Text(isEditing ? 'EDIT' : 'ADD'),
        ),
      ],
    );
  }

  // Update the _buildTextField method to handle validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool readOnly = false,
    VoidCallback? onTap,
    String? errorText,
    bool isTitleField = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(fontSize: 16),
          onChanged: isTitleField ? (value) {
            // Mark as touched when user starts typing
            if (!_titleTouched) {
              setState(() {
                _titleTouched = true;
              });
            }
          } : null,
          // Add this callback to handle focus loss for title field
          onTapOutside: isTitleField ? (event) {
            // Mark as touched when user taps outside the field
            if (!_titleTouched) {
              setState(() {
                _titleTouched = true;
              });
            }
            // Remove focus from the text field
            FocusScope.of(context).unfocus();
          } : null,
          // Alternative: You can also use onEditingComplete for title field
          onEditingComplete: isTitleField ? () {
            if (!_titleTouched) {
              setState(() {
                _titleTouched = true;
              });
            }
          } : null,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            labelStyle: const TextStyle(
              color: Color.fromARGB(255, 136, 134, 134),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color.fromARGB(255, 136, 134, 134),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
        ),
        // Error message
        SizedBox(
          height: 20, // Fixed height for error message space
          child: errorText != null 
            ? Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  errorText,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize:10,
                  ),
                ),
              )
            : null,
        ),
      ],
    );
  }

  // Update the _buildDateField method
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: dateController,
          label: 'Demo Date *',
          hintText: 'Select date',
          readOnly: true,
          onTap: () async {
            await _selectDate();
            // Mark as touched when user interacts with date picker
            if (!_dateTouched) {
              setState(() {
                _dateTouched = true;
              });
            }
          },
          errorText: dateError,
        ),
      ],
    );
  }
 // Update the _buildTimeRow method
  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: _buildTimeButton(
                  time: startTime,
                  label: 'Start Time${!isEditing ? ' *' : ''}',
                  onTap: () async {
                    await _selectTime(true);
                    // Mark as touched when user interacts with time picker
                    if (!_startTimeTouched) {
                      setState(() {
                        _startTimeTouched = true;
                      });
                    }
                  },
                  hasError: startTimeError != null,
                ),
              ),
              // Error message for start time
              SizedBox(
                height: 20, // Fixed height for error message space
                child: startTimeError != null 
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        startTimeError!,
                        style: const TextStyle(
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
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: _buildTimeButton(
                  time: endTime,
                  label: 'End Time${!isEditing ? ' *' : ''}',
                  onTap: () async {
                    await _selectTime(false);
                    // Mark as touched when user interacts with time picker
                    if (!_endTimeTouched) {
                      setState(() {
                        _endTimeTouched = true;
                      });
                    }
                  },
                  hasError: endTimeError != null,
                ),
              ),
              // Error message for end time
              SizedBox(
                height: 20, // Fixed height for error message space
                child: endTimeError != null 
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        endTimeError!,
                        style: const TextStyle(
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
    );
  }

   // Update the _buildTimeButton method to accept hasError parameter
  Widget _buildTimeButton({
    required TimeOfDay? time,
    required String label,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    return TextButton(
      onPressed: onTap,
      style: _timeButtonStyle(hasValue: time != null, hasError: hasError),
      child: Text(
        time?.format(context) ?? label,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          color: time != null
              ? Colors.black
              : const Color.fromARGB(255, 136, 134, 134),
        ),
      ),
    );
  }


// Update the _timeButtonStyle method to handle error state
  ButtonStyle _timeButtonStyle({bool hasValue = false, bool hasError = false}) {
    return TextButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      foregroundColor: hasValue
          ? Colors.black
          : const Color.fromARGB(255, 85, 84, 84),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: hasError ? Colors.red : Colors.black12,
        ),
      ),
    );
  }
  /// Styling for cancel button
  ButtonStyle _cancelButtonStyle() {
    return TextButton.styleFrom(
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
  }

  // Update the _saveButtonStyle method to handle enabled/disabled states
  ButtonStyle _addEditButtonStyle({bool isEnabled = true}) {
    return TextButton.styleFrom(
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
  }
}