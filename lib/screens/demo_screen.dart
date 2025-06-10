import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/models/demo_model.dart';
import 'package:my_app/dialog_box/demo_dialog.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart';
import 'package:my_app/jitsi_meet/jitsi_service.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:my_app/screens/guest_screen.dart';

class DemoScreen extends StatefulWidget {
  final String userRole;
  const DemoScreen({ Key? key, 
    required this.userRole}) : super(key: key);

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final JitsiService _jitsiService = JitsiService();
  List<Demo> allDemos = [];
  List<Demo> visibleDemos = [];
  bool _showSearch = false;
  bool isLoading = true;
  List<String> validationErrors = [];
  final TextEditingController _searchController = TextEditingController();
  final String userRole = 'teacher';

  @override
  void initState() {
    super.initState();
    _jitsiService.initialize();
    fetchDemos();
  }

  // Helper method to convert UTC DateTime to IST string with custom format
  String _convertUTCToISTWithCustomFormat(DateTime utcDateTime) {
    // Add 5 hours 30 minutes to convert UTC to IST
    final istDateTime = utcDateTime.add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd MMM yyyy - hh:mm a').format(istDateTime);
  }

 // Fixed helper method to convert UTC date string to IST display format (dd MMM yyyy)
String _formatDateToIST(String? dateString) {
  if (dateString == null || dateString.isEmpty) return 'Date not set';
  
  try {
    DateTime dateToFormat;
    
    // Handle different date formats
    if (dateString.contains('T')) {
      // ISO format with time - convert from UTC to IST only if it's explicitly UTC
      if (dateString.endsWith('Z') || dateString.contains('+') || 
          (dateString.contains('-') && dateString.lastIndexOf('-') > 10)) {
        // This is a UTC timestamp, convert to IST
        final utcDate = DateTime.parse(dateString).toUtc();
        dateToFormat = utcDate.add(const Duration(hours: 5, minutes: 30));
      } else {
        // This is a local datetime, don't convert timezone
        dateToFormat = DateTime.parse(dateString);
      }
    } else if (dateString.contains('-') && dateString.length >= 10) {
      // YYYY-MM-DD format - treat as local date, no timezone conversion needed
      // Extract only the date part to avoid any time zone issues
      final dateOnly = dateString.substring(0, 10);
      dateToFormat = DateTime.parse(dateOnly);
    } else if (dateString.contains('/')) {
      // DD/MM/YYYY format - treat as local date
      try {
        dateToFormat = DateFormat('dd/MM/yyyy').parse(dateString);
      } catch (e) {
        // If parsing fails, return original
        return dateString;
      }
    } else {
      // For other formats, only convert timezone if it's explicitly a UTC timestamp
      final parsedDate = DateTime.parse(dateString);
      if (dateString.endsWith('Z') || 
          (dateString.contains('+') && dateString.lastIndexOf('+') > 10) || 
          (dateString.contains('-') && dateString.lastIndexOf('-') > 10)) {
        // This looks like a timezone-aware timestamp, convert from UTC to IST
        dateToFormat = parsedDate.toUtc().add(const Duration(hours: 5, minutes: 30));
      } else {
        // Treat as local date - no timezone conversion
        dateToFormat = parsedDate;
      }
    }
    
    return DateFormat('dd MMM yyyy').format(dateToFormat);
  } catch (e) {
    debugPrint('Date parsing error: $e for date: $dateString');
    return dateString; // Return original if parsing fails
  }
}

  // Helper method to get demo title with fallback
  String getDemoTitle(Demo demo) {
    return demo.title.trim().isEmpty ? "Untitled Demo" : demo.title;
  }

  // Helper method to get formatted demo date in IST (without +1 day)
  String getDemoDate(Demo demo) {
    return _formatDateToIST(demo.demoDate);
  }

  // Helper method to get start time
  String getStartTime(Demo demo) {
    return demo.startTime.trim().isEmpty ? "Start time not set" : demo.startTime;
  }

  // Helper method to get end time  
  String getEndTime(Demo demo) {
    return demo.endTime.trim().isEmpty ? "End time not set" : demo.endTime;
  }

  // Helper method to get created date in IST format with time (dd MMM yyyy - hh:mm AM/PM)
  String getCreatedOnWithTime(Demo demo) {
    if (demo.createdAt == null) return 'Created date not available';
    
    try {
      // Assuming createdAt is stored as UTC in the database
      final utcCreatedAt = demo.createdAt is String 
          ? DateTime.parse(demo.createdAt as String).toUtc()
          : (demo.createdAt as DateTime).toUtc();
      
      return _convertUTCToISTWithCustomFormat(utcCreatedAt);
    } catch (e) {
      debugPrint('Created date parsing error: $e');
      return 'Created date not available';
    }
  }

  // Updated validation method for demos - removed time comparison validation
  List<String> _validateDemo(Demo demo, bool isEditing) {
    List<String> errors = [];

    // Basic validation - only demo title is required for both new and editing
    if (demo.title.trim().isEmpty) {
      errors.add('Demo title is required');
    }

    // Optional: You can add back other field validations if needed, but without time comparison
    // For now, only title is required

    return errors;
  }

  // Method to start demo using Jitsi service
  Future<void> _startDemo(Demo demo) async {
    final success = await _jitsiService.startClassAndJoin(
      batchId: demo.id!,
      batchName: getDemoTitle(demo),
      context: context,
      eventListener: JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint("Joined demo: ${getDemoTitle(demo)}");
        },
        conferenceTerminated: (url, error) {
          debugPrint("Left demo: ${getDemoTitle(demo)}");
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Demo ended with error: $error')),
            );
          }
        },
        participantJoined: (email, name, role, participantId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name joined the demo')),
          );
        },
      ),
    );

    if (success) {
      debugPrint('Successfully started demo for ${getDemoTitle(demo)}');
    }
  }

  // Method to navigate to Guest screen with demo ID
  void _navigateToGuestScreen(Demo demo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestScreen(
          userRole: widget.userRole,
          demoId: demo.id!,
          demoTitle: getDemoTitle(demo),
        ),
      ),
    );
  }

  Future<void> fetchDemos() async {
    const url = 'https://meet-api.apt.shiksha/api/Demos?filter={"order": "createdAt DESC"}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final demos = jsonData.map((e) => Demo.fromJson(e)).toList();
        setState(() {
          allDemos = demos;
          visibleDemos = demos;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load demos');
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      if (_showSearch) {
        _searchController.clear();
        visibleDemos = allDemos;
      }
      _showSearch = !_showSearch;
    });
  }

  void _filterDemos(String query) {
    final filtered = allDemos.where((demo) {
      final q = query.toLowerCase();
      return getDemoTitle(demo).toLowerCase().contains(q) ||
          getStartTime(demo).toLowerCase().contains(q) ||
          getEndTime(demo).toLowerCase().contains(q) ||
          getCreatedOnWithTime(demo).toLowerCase().contains(q) ||
          getDemoDate(demo).toLowerCase().contains(q);
    }).toList();
    setState(() => visibleDemos = filtered);
  }

  void _copyDemoLink(Demo demo) {
    final demoLink = "https://meet.apt.shiksha/#/demo/${demo.id}";
    Clipboard.setData(ClipboardData(text: demoLink)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo link copied to clipboard')),
      );
    });
  }

  void _openDemoDialog({Demo? demo}) async {
    // Clear previous validation errors
    setState(() {
      validationErrors.clear();
    });

    final result = await showDialog<Demo>(
      context: context,
      builder: (_) => DemoDialog(demo: demo),
    );
    
    if (result != null) {
      final isUpdate = demo != null && demo.id != null;
      
      // Validate the demo data
      final errors = _validateDemo(result, isUpdate);
      
      if (errors.isNotEmpty) {
        // Show validation errors
        setState(() {
          validationErrors = errors;
        });
        
        // Auto-hide the errors after 8 seconds
        Timer(const Duration(seconds: 8), () {
          if (mounted) {
            setState(() {
              validationErrors.clear();
            });
          }
        });
        return;
      }

      // If validation passes, proceed with API call
      final url = isUpdate
          ? 'https://meet-api.apt.shiksha/api/Demos/${demo.id}'
          : 'https://meet-api.apt.shiksha/api/Demos';
      try {
        final response = isUpdate
            ? await http.put(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(result.toJson()),
              )
            : await http.post(
                Uri.parse(url),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(result.toJson()),
              );

        if (response.statusCode == 200 || response.statusCode == 201) {
          fetchDemos();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isUpdate ? 'Demo updated successfully' : 'Demo created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to save demo');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving demo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavBar(
        title: 'Demo',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RoleBasedDrawer(
        role: widget.userRole,
        scaffoldKey: _scaffoldKey,
      ),
      body: Stack(
        children: [
          // Main content
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Demos',
                            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _showSearch
                                ? TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: 'Search demos...',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterDemos('');
                                          _toggleSearch();
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onChanged: _filterDemos,
                                  )
                                : Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(Icons.search),
                                      tooltip: 'Search Demos',
                                      onPressed: _toggleSearch,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Total Demos: ${visibleDemos.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleDemos.length,
                        itemBuilder: (context, index) {
                          final demo = visibleDemos[index];
                          return GestureDetector(
                            onTap: () => _navigateToGuestScreen(demo),
                            child: Card(
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
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            getDemoTitle(demo),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight:  FontWeight.bold,
                                              
                                             
                                            ),
                                            softWrap: true,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _openDemoDialog(demo: demo),
                                          icon: const Icon(Icons.edit, color: Color(0xFF60615D)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    // Demo details with IST formatting (no +1 day for demo date)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                      child: Text(
                                        "Demo Date: ${getDemoDate(demo)}",
                                        style: TextStyle(
                                          color: const Color(0xFF60615D),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                      child: Text(
                                        "Start Time: ${getStartTime(demo)}",
                                        style: TextStyle(
                                          color: const Color(0xFF60615D),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                      child: Text(
                                        "End Time: ${getEndTime(demo)}",
                                        style: TextStyle(
                                          color: const Color(0xFF60615D),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                         
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                      child: Text(
                                        "Created On: ${getCreatedOnWithTime(demo)}",
                                        style: const TextStyle(
                                          color: Color(0xFF60615D),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () => _startDemo(demo),
                                            icon: const Icon(Icons.play_arrow, color: Colors.white),
                                            label: const Text("Start Demo",
                                                style: TextStyle(color: Colors.white, fontSize: 15)),
                                            style: TextButton.styleFrom(
                                              backgroundColor: const Color(0xFF20201F),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _copyDemoLink(demo),
                                            icon: const Icon(Icons.link, color: Colors.black),
                                            label: const Text("Copy Link",
                                                style: TextStyle(color: Colors.black, fontSize: 15)),
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: const Color.fromARGB(255, 236, 236, 236),
                                              side: const BorderSide(color: Colors.grey, width: 1),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          // Validation error overlay
          if (validationErrors.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'All fields are required',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDemoDialog(),
        tooltip: 'Create Demo',
        backgroundColor: const Color(0xFF20201F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}