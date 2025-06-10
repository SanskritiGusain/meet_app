import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/models/student_model.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart';
import 'package:my_app/screens/attendance_screen.dart';
import 'package:my_app/jitsi_meet/jitsi_service.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class StudentScreen extends StatefulWidget {
  final String userRole;
  final String batchId;
  final String batchName;
  
  const StudentScreen({
    Key? key,
    required this.userRole,
    required this.batchId,
    required this.batchName,
  }) : super(key: key);

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final JitsiService _jitsiService = JitsiService();
  List<Student> allStudents = [];
  List<Student> visibleStudents = [];
  bool _showSearch = false;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _jitsiService.initialize();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final url = 'https://meet-api.apt.shiksha/api/Batches/${widget.batchId}/students';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final students = jsonData.map((e) => Student.fromJson(e)).toList();
        
        setState(() {
          allStudents = students;
          visibleStudents = students;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: $e')),
      );
    }
  }

  Future<void> deleteStudent(String studentId) async {
    final url = 'https://meet-api.apt.shiksha/api/Students/$studentId';
    
    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode == 204) {
        fetchStudents(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: Colors.black87,
          ),
        );
      } else {
        throw Exception('Failed to delete student');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting student: $e'),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            
            child: Column(
  mainAxisSize: MainAxisSize.min, 
    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                // Title
                const Text(
                  'Delete Student',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Content
                Text(
                  'Are you sure you want to delete ${student.name}?',
                 
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (student.id != null) {
                            deleteStudent(student.id!);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 8, 8, 8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
  }

  Future<void> startClassAndJoin() async {
    final success = await _jitsiService.startClassAndJoin(
      batchId: widget.batchId,
      batchName: widget.batchName,
      context: context,
      eventListener: JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint("Joined batch: ${widget.batchName}");
        },
        conferenceTerminated: (url, error) {
          debugPrint("Left batch: ${widget.batchName}");
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
      debugPrint('Successfully started class for ${widget.batchName}');
    }
  }

  
  void _navigateToAttendanceScreen() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AttendanceScreen(
        userRole: widget.userRole,
        batchId: widget.batchId,
        batchName: widget.batchName,
      ),
    ),
  );

  }
void _navigateToBatchScreen() {
  Navigator.of(context).pop();
  }
  void _toggleSearch() {
    setState(() {
      if (_showSearch) {
        _searchController.clear();
        visibleStudents = allStudents;
      }
      _showSearch = !_showSearch;
    });
  }

  void _filterStudents(String query) {
    final filtered = allStudents.where((student) {
      final q = query.toLowerCase();
      return student.name.toLowerCase().contains(q) ||
          student.loginId.toLowerCase().contains(q) ||
          student.password.toLowerCase().contains(q);
    }).toList();
    setState(() => visibleStudents = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavBar(
        title: 'Students - ${widget.batchName}',
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
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: _navigateToBatchScreen,
        icon: const Icon(
          Icons.arrow_back, // or Icons.class_ or Icons.group_work
          color: Colors.black87,
          size: 24,
        ),
        tooltip: 'Back to Batches',
        padding: const EdgeInsets.all(2),
      ),
    ),
    const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Students',
                                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
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
                                      hintText: 'Search students...',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterStudents('');
                                          _toggleSearch();
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onChanged: _filterStudents,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  tooltip: 'Search Students',
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
                 
                     child: Text(
                        'Total Students: ${visibleStudents.length}',
                       
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      ), 
                    const SizedBox(height: 12),
                    
                  
               
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: startClassAndJoin,
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          label: const Text(
                            'Start Class',
                            style: TextStyle(color: Colors.white),
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
                          onPressed: _navigateToAttendanceScreen,
                          icon: const Icon(Icons.assignment, color: Color.fromARGB(255, 15, 15, 15)),
                          label: const Text(
                            'Attendance',
                            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 253, 252, 252),
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
                  child: visibleStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No students found in this batch',
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
                          itemCount: visibleStudents.length,
                          itemBuilder: (context, index) {
                            final student = visibleStudents[index];
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
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            student.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            softWrap: true,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _showDeleteConfirmation(student),
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Color.fromARGB(255, 108, 107, 107),
                                          ),
                                          tooltip: 'Delete Student',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Student details
                                    ...[
                                      "Login ID: ${student.loginId}",
                                      "Password: ${student.password}",
                                      
                                    ].map((text) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0, left: 3.0),
                                          child: Row(
                                            children: [
                                              Icon(
                                                text.startsWith('Login ID') 
                                                    ? Icons.person 
                                                    : text.startsWith('Password') 
                                                        ? Icons.lock 
                                                        : Icons.info,
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