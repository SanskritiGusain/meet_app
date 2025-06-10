import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:my_app/role_base_drawer/role_base_drawer.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/dialog_box/teacher_dialog.dart';
import 'package:my_app/models/teacher_model.dart';

class TeacherScreen extends StatefulWidget {
  final String userRole;
  const TeacherScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Teacher> allTeachers = [];
  List<Teacher> visibleTeachers = [];
  bool _showSearch = false;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method to format date from ISO string to desired format
  String formatCreatedAt(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      final formatter = DateFormat('dd-MM-yyyy hh:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      return isoDate; // Return original if parsing fails
    }
  }

  Future<void> fetchTeachers() async {
    const url = 'https://meet-api.apt.shiksha/api/Teachers?filter={"order":"createdAt DESC"}';
    try {
      setState(() => isLoading = true);
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final teachers = data.map((json) => Teacher.fromJson(json)).toList();
        setState(() {
          allTeachers = teachers;
          visibleTeachers = teachers;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load teachers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load teachers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addTeacher(String name, String loginId, String password) async {
    const url = 'https://meet-api.apt.shiksha/api/Teachers';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'loginId': loginId,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTeachers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to add teacher: ${response.body}');
      }
    } catch (e) {
      print('Error adding teacher: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add teacher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addTeachersInBulk(List<Teacher> teachers) async {
    const url = 'https://meet-api.apt.shiksha/api/Teachers/bulk';
    try {
      final teachersJson = teachers.map((teacher) => {
        'name': teacher.name,
        'loginId': teacher.loginId,
        'password': teacher.password,
      }).toList();

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'teachers': teachersJson}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTeachers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${teachers.length} teachers added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // If bulk endpoint doesn't exist, fall back to individual additions
        await _addTeachersIndividually(teachers);
      }
    } catch (e) {
      print('Error adding teachers in bulk: $e');
      // Fall back to individual additions
      await _addTeachersIndividually(teachers);
    }
  }

  Future<void> _addTeachersIndividually(List<Teacher> teachers) async {
    int successCount = 0;
    int failCount = 0;

    for (final teacher in teachers) {
      try {
        await _addTeacher(teacher.name, teacher.loginId, teacher.password);
        successCount++;
      } catch (e) {
        failCount++;
        print('Failed to add teacher ${teacher.name}: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $successCount teachers. Failed: $failCount'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      if (_showSearch) {
        _searchController.clear();
        visibleTeachers = allTeachers;
      }
      _showSearch = !_showSearch;
    });
  }

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder: (context) => TeacherDialog(
        onSave: (name, loginId, password) {
          _addTeacher(name, loginId, password);
        },
        onBulkSave: (teachers) {
          _addTeachersInBulk(teachers);
        },
      ),
    );
  }

  void _filterTeachers(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered = allTeachers.where((teacher) {
      return teacher.name.toLowerCase().contains(lowerQuery) ||
          teacher.loginId.toLowerCase().contains(lowerQuery) ||
          formatCreatedAt(teacher.createdAt).toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() {
      visibleTeachers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavBar(
        title: 'Teachers',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: RoleBasedDrawer(
        role: widget.userRole,
        scaffoldKey: _scaffoldKey,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 245, 240),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchTeachers,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Teachers',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _showSearch
                              ? TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search teachers...',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _filterTeachers('');
                                        _toggleSearch();
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onChanged: _filterTeachers,
                                )
                              : Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.search),
                                    tooltip: 'Search Teachers',
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
                    child: Row(
                      children: [
                        Text(
                          'Total Teachers: ${visibleTeachers.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (allTeachers.length != visibleTeachers.length)
                          Text(
                            'Showing ${visibleTeachers.length} of ${allTeachers.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: visibleTeachers.isEmpty
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
                                  allTeachers.isEmpty
                                      ? 'No teachers found'
                                      : 'No teachers match your search',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (allTeachers.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first teacher using the + button',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: visibleTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = visibleTeachers[index];
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
                                              teacher.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 3.0,
                                          left: 3.0,
                                        ),
                                        child: Text(
                                          "Login ID: ${teacher.loginId}",
                                          style: const TextStyle(
                                            color: Color(0xFF60615D),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 3.0,
                                          left: 3.0,
                                        ),
                                        child: Text(
                                          "Password: ${teacher.password}",
                                          style: const TextStyle(
                                            color: Color(0xFF60615D),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        tooltip: 'Add Teacher',
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}