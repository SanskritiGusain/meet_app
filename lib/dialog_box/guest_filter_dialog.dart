import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/guest_model.dart';

// Custom Date Picker Widget
class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDatePicker({
    Key? key,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
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

// Custom Time Picker Item Widget
class _TimePickerItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final double fontSize;

  const _TimePickerItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF272626) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? null : Border.all(color: Colors.transparent),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class GuestFilterDialog extends StatefulWidget {
  final Function(List<Guest>) onFilterApplied;
  final List<Guest> allGuests;

  const GuestFilterDialog({
    Key? key,
    required this.onFilterApplied,
    required this.allGuests,
  }) : super(key: key);

  @override
  State<GuestFilterDialog> createState() => _GuestFilterDialogState();
}

class _GuestFilterDialogState extends State<GuestFilterDialog> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  bool uniqueOnly = false;

  @override
  void dispose() {
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFDFAFA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Filter Guests',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: 280,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildDateFilterField(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStartTimeField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEndTimeField()),
                ],
              ),
              const SizedBox(height: 16),
              _buildUniqueFilterCheckbox(),
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
          onPressed: _applyFilters,
          style: _filterButtonStyle(),
          child: const Text('FILTER'),
        ),
      ],
    );
  }

  Widget _buildDateFilterField() {
    return TextField(
      controller: dateController,
      readOnly: true,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Date Filter',
        labelStyle: const TextStyle(color: Color(0xFF888686), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1F000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF888686)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
      onTap: _selectDate,
    );
  }

  Widget _buildStartTimeField() {
    return TextField(
      controller: startTimeController,
      readOnly: true,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Start Time',
        labelStyle: const TextStyle(color: Color(0xFF888686), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1F000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF888686)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
      onTap: () => _selectTime(startTimeController),
    );
  }

  Widget _buildEndTimeField() {
    return TextField(
      controller: endTimeController,
      readOnly: true,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'End Time',
        labelStyle: const TextStyle(color: Color(0xFF888686), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1F000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF888686)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black12),
        ),
      ),
      onTap: () => _selectTime(endTimeController),
    );
  }

  Widget _buildUniqueFilterCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: uniqueOnly,
          onChanged: (value) => setState(() => uniqueOnly = value ?? false),
          activeColor: const Color(0xFF272626),
        ),
        const Text(
          'Unique',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  /// Custom date selection method
  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => CustomDatePicker(
        initialDate: DateTime.now(),
        firstDate: DateTime(2016),
        lastDate: DateTime(2040),
      ),
    );
    
    if (picked != null) {
      // Format date to match the new IST format (28 Jun 2025)
      String formattedDate = DateFormat('dd MMM yyyy').format(picked);
      dateController.text = formattedDate;
    }
  }

  /// Custom list-style time picker
  Future<void> _selectTime(TextEditingController controller) async {
    FocusScope.of(context).unfocus();
    
    final TimeOfDay? pickedTime = await _showCustomTimePicker(TimeOfDay.now());
    
    if (pickedTime != null) {
      // Format time to match 12-hour format with AM/PM
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
      String formattedTime = DateFormat('hh:mm a').format(dateTime);
      controller.text = formattedTime;
    }
  }

  /// Custom list-style time picker with proper touch states
  Future<TimeOfDay?> _showCustomTimePicker(TimeOfDay initialTime) async {
    TimeOfDay selectedTime = initialTime;
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
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFDFAFA),
                    foregroundColor: const Color(0xFF242424),
                    side: const BorderSide(color: Color(0xFF151515), width: 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    hourController.dispose();
                    minuteController.dispose();
                    periodController.dispose();
                    Navigator.of(context).pop(selectedTime);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF272626),
                    foregroundColor: const Color(0xFFF4F4F4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    List<Guest> filtered = List.from(widget.allGuests);
    
    // Filter by date - Updated to work with new format
    if (dateController.text.trim().isNotEmpty) {
      final filterDate = dateController.text.trim();
      filtered = filtered.where((guest) {
        return guest.createdOnWithTime.contains(filterDate);
      }).toList();
    }
    
    // Filter by start time - Updated to work with 12-hour format
    if (startTimeController.text.trim().isNotEmpty) {
      final startTime = startTimeController.text.trim();
      filtered = filtered.where((guest) {
        final guestTimeString = _extractTimeFromDateTime(guest.createdOnWithTime);
        if (guestTimeString != null) {
          return _compareTime12Hour(guestTimeString, startTime) >= 0;
        }
        return false;
      }).toList();
    }
    
    // Filter by end time - Updated to work with 12-hour format
    if (endTimeController.text.trim().isNotEmpty) {
      final endTime = endTimeController.text.trim();
      filtered = filtered.where((guest) {
        final guestTimeString = _extractTimeFromDateTime(guest.createdOnWithTime);
        if (guestTimeString != null) {
          return _compareTime12Hour(guestTimeString, endTime) <= 0;
        }
        return false;
      }).toList();
    }
    
    // Filter by unique names
    if (uniqueOnly) {
      final Map<String, Guest> uniqueGuests = {};
      for (final guest in filtered) {
        if (!uniqueGuests.containsKey(guest.name) || guest.name == "Untitled Guest") {
          uniqueGuests[guest.name] = guest;
        }
      }
      filtered = uniqueGuests.values.toList();
    }
    
    widget.onFilterApplied(filtered);
    Navigator.pop(context);
  }

  // Helper method to extract time from the new datetime format (28 Jun 2025 - 02:14 PM)
  String? _extractTimeFromDateTime(String dateTimeString) {
    try {
      // Split by ' - ' to get the time part
      final parts = dateTimeString.split(' - ');
      if (parts.length >= 2) {
        return parts[1]; // Return the time part (e.g., "02:14 PM")
      }
    } catch (e) {
      // Handle parsing errors silently
    }
    return null;
  }

  // Helper method to compare times in 12-hour format
  int _compareTime12Hour(String time1, String time2) {
    try {
      // Convert to 24-hour format for comparison
      int convertTo24Hour(String time12) {
        final parts = time12.split(' ');
        final timePart = parts[0];
        final ampm = parts[1].toUpperCase();
        
        final timeComponents = timePart.split(':');
        int hour = int.parse(timeComponents[0]);
        int minute = int.parse(timeComponents[1]);
        
        if (ampm == 'PM' && hour != 12) {
          hour += 12;
        } else if (ampm == 'AM' && hour == 12) {
          hour = 0;
        }
        
        return hour * 60 + minute;
      }
      
      final time1Minutes = convertTo24Hour(time1);
      final time2Minutes = convertTo24Hour(time2);
      
      return time1Minutes.compareTo(time2Minutes);
    } catch (e) {
      return 0;
    }
  }

  ButtonStyle _cancelButtonStyle() => TextButton.styleFrom(
        backgroundColor: const Color(0xFFFDFAFA),
        foregroundColor: const Color(0xFF242424),
        side: const BorderSide(color: Color(0xFF151515), width: 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  ButtonStyle _filterButtonStyle() => TextButton.styleFrom(
        backgroundColor: const Color(0xFF272626),
        foregroundColor: const Color(0xFFF4F4F4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      );
}