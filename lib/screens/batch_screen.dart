import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_app/models/batch_model.dart';
import 'package:my_app/dialog_box/batch_dialog.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart';
import 'package:my_app/jitsi_meet/jitsi_service.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:my_app/screens/student_screen.dart';

class BatchScreen extends StatefulWidget {
  final String userRole;
  const BatchScreen({
    Key? key,
    required this.userRole
  }) : super(key: key);

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final JitsiService _jitsiService = JitsiService();
  
  List<Batch> allBatches = [];
  List<Batch> visibleBatches = [];
  bool _showSearch = false;
  bool isLoading = true;
  String? errorMessage;
  List<String> validationErrors = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _jitsiService.initialize();
    fetchBatches();
  }

  // Method to handle back button press
  Future<bool> _onWillPop() async {
    if (_showSearch) {
      // If search is active, close search instead of exiting
      _toggleSearch();
      return false;
    }
    
    // Show confirmation dialog for teachers
    if (widget.userRole.toLowerCase() == 'teacher') {
      return await _showExitConfirmationDialog();
    }
    
    // For admin, allow normal back navigation
    return true;
  }

  // Show exit confirmation dialog
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                SystemNavigator.pop(); // This will close the app
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Helper method to get batch display name
  String getBatchDisplayName(Batch batch) {
    if (batch.batchName.trim().isEmpty) {
      return 'Untitled Batch';
    }
    return batch.batchName;
  }

  // Helper method to get formatted batch date
  String getBatchDate(Batch batch) {
    if (batch.batchDate == null || batch.batchDate!.trim().isEmpty) {
      return 'Date not set';
    }
    try {
      final date = DateTime.parse(batch.batchDate!);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return batch.batchDate!;
    }
  }

  // Helper method to get start time
  String getStartTime(Batch batch) {
    if (batch.startTime.trim().isEmpty) {
      return 'Start time not set';
    }
    return batch.startTime;
  }

  // Helper method to get end time
  String getEndTime(Batch batch) {
    if (batch.endTime.trim().isEmpty) {
      return 'End time not set';
    }
    return batch.endTime;
  }

  // Helper method to get formatted creation date in IST
  String getCreatedOn(Batch batch) {
    if (batch.createdAt == null) {
      return 'Creation date unknown';
    }
    try {
      // Handle both String and DateTime types for createdAt
      DateTime createdDate;
      if (batch.createdAt is String) {
        createdDate = DateTime.parse(batch.createdAt as String);
      } else if (batch.createdAt is DateTime) {
        createdDate = batch.createdAt as DateTime;
      } else {
        return 'Creation date unknown';
      }
      
      // Convert UTC to IST (UTC+5:30)
      final istDate = createdDate.toUtc().add(const Duration(hours: 5, minutes: 30));
      
      return DateFormat('dd MMM yyyy - hh:mm a').format(istDate);
    } catch (e) {
      return batch.createdAt.toString();
    }
  }

  Future<void> startClassAndJoin(Batch batch) async {
    final success = await _jitsiService.startClassAndJoin(
      batchId: batch.id!,
      batchName: getBatchDisplayName(batch),
      context: context,
      eventListener: JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint("Joined batch: ${getBatchDisplayName(batch)}");
        },
        conferenceTerminated: (url, error) {
          debugPrint("Left batch: ${getBatchDisplayName(batch)}");
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Meeting ended with error',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            );
          }
        },
        participantJoined: (email, name, role, participantId) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$name joined the class',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        },
      ),
    );

    if (success) {
      debugPrint('Successfully started class for ${getBatchDisplayName(batch)}');
    }
  }

  void _navigateToStudentScreen(Batch batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentScreen(
          userRole: widget.userRole,
          batchId: batch.id!,
          batchName: getBatchDisplayName(batch),
        ),
      ),
    );
  }

  Future<void> fetchBatches() async {
    const url = 'https://meet-api.apt.shiksha/api/Batches?filter={"order": "createdAt DESC"}';
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        
        if (responseBody.isEmpty || responseBody == 'null') {
          setState(() {
            allBatches = [];
            visibleBatches = [];
            isLoading = false;
          });
          return;
        }

        final List<dynamic> data = json.decode(responseBody);
        final batches = data.map((json) => Batch.fromJson(json)).toList();

        setState(() {
          allBatches = batches;
          visibleBatches = batches;
          isLoading = false;
        });
      } else {
        throw http.ClientException('Failed to load batches: ${response.statusCode}');
      }
    } on TimeoutException {
      setState(() {
        isLoading = false;
        errorMessage = 'Connection timeout. Please check your internet connection.';
      });
    } on SocketException {
      setState(() {
        isLoading = false;
        errorMessage = 'No internet connection. Please check your network settings.';
      });
    } on FormatException {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid data format received from server.';
      });
    } on http.ClientException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Network error occurred. Please try again.';
      });
      debugPrint('HTTP Client error: $e');
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
      debugPrint('Unexpected error in fetchBatches: $e');
    }
  }

  void _toggleSearch() {
    setState(() {
      if (_showSearch) {
        _searchController.clear();
        visibleBatches = allBatches;
      }
      _showSearch = !_showSearch;
    });
  }

  void _filterBatches(String query) {
    if (query.isEmpty) {
      setState(() => visibleBatches = allBatches);
      return;
    }

    final filtered = allBatches.where((batch) {
      final q = query.toLowerCase();
      return getBatchDisplayName(batch).toLowerCase().contains(q) ||
          getStartTime(batch).toLowerCase().contains(q) ||
          getEndTime(batch).toLowerCase().contains(q) ||
          getCreatedOn(batch).toLowerCase().contains(q) ||
          getBatchDate(batch).toLowerCase().contains(q);
    }).toList();
    
    setState(() => visibleBatches = filtered);
  }

  // Updated validation method to match BatchDialog fields only
  List<String> _validateBatch(Batch batch, bool isEditing) {
    List<String> errors = [];

    if (!isEditing) {
      // Validation for new batches - batch name, start time, and end time required
      if (batch.batchName.trim().isEmpty) {
        errors.add('Batch name is required');
      }
      if (batch.startTime.trim().isEmpty) {
        errors.add('Start time is required');
      }
      if (batch.endTime.trim().isEmpty) {
        errors.add('End time is required');
      }
    } else {
      // Validation for editing - only batch name required
      if (batch.batchName.trim().isEmpty) {
        errors.add('Batch name is required');
      }
    }

    // Time validation if both times are provided
    if (batch.startTime.isNotEmpty && batch.endTime.isNotEmpty) {
      try {
        final startTime = TimeOfDay.fromDateTime(
          DateFormat.jm().parse(batch.startTime)
        );
        final endTime = TimeOfDay.fromDateTime(
          DateFormat.jm().parse(batch.endTime)
        );
        
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;
        
        if (endMinutes <= startMinutes) {
          errors.add('End time must be after start time');
        }
      } catch (e) {
        // If time parsing fails, ignore time validation
      }
    }

    return errors;
  }

  void _openBatchDialog({Batch? batch}) async {
    // Clear previous validation errors
    setState(() {
      validationErrors.clear();
    });

    final result = await showDialog<Batch>(
      context: context,
      builder: (_) => BatchDialog(batch: batch),
    );
    
    if (result != null) {
      final isUpdate = batch != null && batch.id != null;
      
      // Validate the batch data
      final errors = _validateBatch(result, isUpdate);
      
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
          ? 'https://meet-api.apt.shiksha/api/Batches/${batch.id}'
          : 'https://meet-api.apt.shiksha/api/Batches';
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
          fetchBatches();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isUpdate ? 'Batch updated successfully' : 'Batch created successfully',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to save batch');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving batch: ${e.toString()}',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: NavBar(
          title: 'Batches',
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
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: fetchBatches,
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF20201F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : visibleBatches.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No batches found',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Batches',
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
                                                hintText: 'Search batches...',
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                suffixIcon: IconButton(
                                                  icon: const Icon(Icons.clear),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    _filterBatches('');
                                                    _toggleSearch();
                                                  },
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              onChanged: _filterBatches,
                                            )
                                          : Align(
                                              alignment: Alignment.centerRight,
                                              child: IconButton(
                                                icon: const Icon(Icons.search),
                                                tooltip: 'Search Batches',
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
                                  'Total batches: ${visibleBatches.length}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: visibleBatches.length,
                                  itemBuilder: (context, index) {
                                    final batch = visibleBatches[index];
                                    return Card(
                                      color: const Color(0xFFF5F5F5),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: InkWell(
                                        onTap: () => _navigateToStudentScreen(batch),
                                        borderRadius: BorderRadius.circular(12),
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
                                                      getBatchDisplayName(batch),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black,
                                                      ),
                                                      softWrap: true,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () => _openBatchDialog(batch: batch),
                                                    icon: const Icon(Icons.edit, color: Color(0xFF60615D)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              ...[
                                                "Start Time: ${getStartTime(batch)}",
                                                "End Time: ${getEndTime(batch)}",
                                                "Created On: ${getCreatedOn(batch)}",
                                              ].map(
                                                (text) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                                  child: Text(
                                                    text, 
                                                    style: TextStyle(
                                                      color: const Color(0xFF60615D),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w400,
                                                      fontStyle: (text.contains('not set') || text.contains('unknown')) 
                                                          ? FontStyle.italic 
                                                          : FontStyle.normal,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 25),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextButton.icon(
                                                      onPressed: () => startClassAndJoin(batch),
                                                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                                                      label: const Text(
                                                        "Start Class",
                                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                                      ),
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: const Color(0xFF20201F),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12)),
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            // Updated validation error overlay to show relevant errors
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
                              'Validation Error',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                validationErrors.clear();
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...validationErrors.map((error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• $error',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openBatchDialog(),
          tooltip: 'Create Batch',
          backgroundColor: const Color(0xFF20201F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(Icons.add, size: 35, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}