import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io'; 
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';// Add this import for File class
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/models/student_model.dart';
import 'package:my_app/models/attendance_model.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart';
import 'package:my_app/dialog_box/attendance_dialog.dart';
import 'package:file_picker/file_picker.dart';

class AttendanceScreen extends StatefulWidget {
  final String userRole;
  final String batchId;
  final String batchName;
  
  const AttendanceScreen({
    Key? key,
    required this.userRole,
    required this.batchId,
    required this.batchName,
  }) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Attendance> allAttendance = [];
  List<Attendance> visibleAttendance = [];
  bool _showSearch = false;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? currentFilter;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    final url = 'https://meet-api.apt.shiksha/api/Attendances/getAttendance';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'batchId': widget.batchId}),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> attendanceData = jsonData['data'] ?? [];
        final attendance = attendanceData.map((e) => Attendance.fromJson(e)).toList();
        
        setState(() {
          allAttendance = attendance;
          visibleAttendance = attendance;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load attendance');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendance: $e')),
      );
    }
  }

  void _showFilterDialog() async {
    final filterData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AttendanceFilterDialog();
      },
    );

    if (filterData != null) {
      _applyFilter(filterData);
    }
  }

  void _applyFilter(Map<String, dynamic> filterData) {
    setState(() {
      currentFilter = filterData;
      List<Attendance> filtered = List.from(allAttendance);

      // Apply date filter
      if (filterData['date'] != null && filterData['date'].isNotEmpty) {
        try {
          final filterDate = DateFormat('dd/MM/yyyy').parse(filterData['date']);
          filtered = filtered.where((attendance) {
            return DateUtils.isSameDay(attendance.createdAt, filterDate);
          }).toList();
        } catch (e) {
          debugPrint('Date filter error: $e');
        }
      }

      // Apply time filters
      if (filterData['startTime'] != null || filterData['endTime'] != null) {
        filtered = filtered.where((attendance) {
          final attendanceTime = TimeOfDay.fromDateTime(attendance.createdAt);
          
          if (filterData['startTime'] != null) {
            final startTime = _parseTimeOfDay(filterData['startTime']);
            if (startTime != null && !_isTimeAfterOrEqual(attendanceTime, startTime)) {
              return false;
            }
          }
          
          if (filterData['endTime'] != null) {
            final endTime = _parseTimeOfDay(filterData['endTime']);
            if (endTime != null && !_isTimeBeforeOrEqual(attendanceTime, endTime)) {
              return false;
            }
          }
          
          return true;
        }).toList();
      }

      // Apply unique filter
      if (filterData['uniqueOnly'] == true) {
        final uniqueStudents = <String, Attendance>{};
        for (final attendance in filtered) {
          if (!uniqueStudents.containsKey(attendance.studentId)) {
            uniqueStudents[attendance.studentId] = attendance;
          }
        }
        filtered = uniqueStudents.values.toList();
      }

      visibleAttendance = filtered;
    });
  }

  TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final format = DateFormat.jm();
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      return null;
    }
  }

  bool _isTimeAfterOrEqual(TimeOfDay time1, TimeOfDay time2) {
    final time1Minutes = time1.hour * 60 + time1.minute;
    final time2Minutes = time2.hour * 60 + time2.minute;
    return time1Minutes >= time2Minutes;
  }

  bool _isTimeBeforeOrEqual(TimeOfDay time1, TimeOfDay time2) {
    final time1Minutes = time1.hour * 60 + time1.minute;
    final time2Minutes = time2.hour * 60 + time2.minute;
    return time1Minutes <= time2Minutes;
  }

  void _clearFilter() {
    setState(() {
      currentFilter = null;
      visibleAttendance = allAttendance;
    });
  }

void _exportToCsv() async {
  try {
    // Request storage permission first
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to export files'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Prepare CSV content
    final csvContent = StringBuffer();
    csvContent.writeln('Student ID,Student Name,Login Time');
    
    for (final attendance in visibleAttendance) {
      final loginTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(attendance.createdAt);
      final studentId = attendance.loginId ?? attendance.studentId;
      final studentName = attendance.studentName.replaceAll(',', ';');
      
      csvContent.writeln('$studentId,"$studentName",$loginTime');
    }
    
    // Create filename with timestamp
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    final fileName = 'attendance_${widget.batchName.replaceAll(' ', '_')}_$dateStr.csv';
    
    // Try to get Downloads directory, fallback to external storage
    Directory? directory;
    
    if (Platform.isAndroid) {
      // For Android, try to get Downloads directory
      try {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage directory
          directory = await getExternalStorageDirectory();
        }
      } catch (e) {
        directory = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      // For iOS, use app documents directory (iOS doesn't allow direct Downloads access)
      directory = await getApplicationDocumentsDirectory();
    }
    
    if (directory == null) {
      throw Exception('Could not access storage directory');
    }
    
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvContent.toString());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Platform.isAndroid 
            ? 'CSV exported successfully!\nSaved to Downloads: $fileName'
            : 'CSV exported successfully!\nSaved to: ${file.path}',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Copy Path',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: file.path));
          },
        ),
      ),
    );
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error exporting CSV: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
 
  void _navigateToStudentScreen() {
    Navigator.of(context).pop();
  }

  void _toggleSearch() {
    setState(() {
      if (_showSearch) {
        _searchController.clear();
        if (currentFilter != null) {
          _applyFilter(currentFilter!);
        } else {
          visibleAttendance = allAttendance;
        }
      }
      _showSearch = !_showSearch;
    });
  }

  void _filterAttendance(String query) {
    List<Attendance> baseList = currentFilter != null ? 
        _getFilteredList(currentFilter!) : allAttendance;
    
    final filtered = baseList.where((attendance) {
      final q = query.toLowerCase();
      return attendance.studentName.toLowerCase().contains(q) ||
          (attendance.loginId?.toLowerCase().contains(q) ?? false);
    }).toList();
    setState(() => visibleAttendance = filtered);
  }

  List<Attendance> _getFilteredList(Map<String, dynamic> filterData) {
    List<Attendance> filtered = List.from(allAttendance);
    
    // Apply the same filtering logic as in _applyFilter
    if (filterData['date'] != null && filterData['date'].isNotEmpty) {
      try {
        final filterDate = DateFormat('dd/MM/yyyy').parse(filterData['date']);
        filtered = filtered.where((attendance) {
          return DateUtils.isSameDay(attendance.createdAt, filterDate);
        }).toList();
      } catch (e) {
        debugPrint('Date filter error: $e');
      }
    }

    if (filterData['startTime'] != null || filterData['endTime'] != null) {
      filtered = filtered.where((attendance) {
        final attendanceTime = TimeOfDay.fromDateTime(attendance.createdAt);
        
        if (filterData['startTime'] != null) {
          final startTime = _parseTimeOfDay(filterData['startTime']);
          if (startTime != null && !_isTimeAfterOrEqual(attendanceTime, startTime)) {
            return false;
          }
        }
        
        if (filterData['endTime'] != null) {
          final endTime = _parseTimeOfDay(filterData['endTime']);
          if (endTime != null && !_isTimeBeforeOrEqual(attendanceTime, endTime)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    }

    if (filterData['uniqueOnly'] == true) {
      final uniqueStudents = <String, Attendance>{};
      for (final attendance in filtered) {
        if (!uniqueStudents.containsKey(attendance.studentId)) {
          uniqueStudents[attendance.studentId] = attendance;
        }
      }
      filtered = uniqueStudents.values.toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavBar(
        title: 'Attendance - ${widget.batchName}',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RoleBasedDrawer(
        role: widget.userRole,
        scaffoldKey: _scaffoldKey,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                              margin: const EdgeInsets.only(left: 0), 
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              
                            ),
                            child: IconButton(
                              onPressed: _navigateToStudentScreen,
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black87,
                                size: 24,
                              ),
                              tooltip: 'Back to Students',
                              padding: const EdgeInsets.all(0),
                    
                              
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Attendance',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _showSearch
                              ? Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Search attendance...',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterAttendance('');
                                          _toggleSearch();
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onChanged: _filterAttendance,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  tooltip: 'Search Attendance',
                                  onPressed: _toggleSearch,
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Records: ${visibleAttendance.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action Buttons - Updated UI
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: currentFilter != null
                            ? ElevatedButton.icon(
                                onPressed: _clearFilter,
                                icon: const Icon(Icons.clear, color: Colors.red),
                                label: const Text(
                                  'CLEAR FILTER',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(color: Colors.red, width: 1),
                                  ),
                                  elevation: 0,
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _showFilterDialog,
                                icon: const Icon(Icons.filter_alt, color: Colors.white),
                                label: const Text(
                                  'FILTER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF20201F),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportToCsv,
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text(
                            'EXPORT CSV',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20201F),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: visibleAttendance.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No attendance records found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: visibleAttendance.length,
                          itemBuilder: (context, index) {
                            final attendance = visibleAttendance[index];
                            final loginTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(attendance.createdAt);
                            
                            return Card(
                              color: const Color.fromARGB(255, 245, 245, 245),
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attendance.studentName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 12),
                                    // Attendance details
                                    ...[
                                      "Student ID: ${attendance.loginId }",
                                      "Login Time: $loginTime",
                                    ].map((text) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0, left: 3.0),
                                          child: Row(
                                            children: [
                                              Icon(
                                                text.startsWith('Student ID') 
                                                    ? Icons.badge
                                                    : Icons.schedule,
                                                size: 16,
                                                color: const Color(0xFF60615D),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  text,
                                                  style: const TextStyle(
                                                    color: Color(0xFF60615D),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}