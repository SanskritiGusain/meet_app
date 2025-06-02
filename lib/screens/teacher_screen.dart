import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:my_app/role_base_drawer/role_base_drawer.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/dialog_box/teacher_dialog.dart'; // <-- Add this
import 'package:my_app/models/teacher_model.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({Key? key}) : super(key: key);

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
  final String userRole = 'admin';

  @override
  void initState() {
    super.initState();
    fetchTeachers();
  }

  Future<void> fetchTeachers() async {
    const url = 'https://meet-api.apt.shiksha/api/Teachers?filter={"order":"createdAt DESC"}';
    try {
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
        throw Exception('Failed to load teachers');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
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
      } else {
        print('Failed to add teacher: ${response.body}');
      }
    } catch (e) {
      print('Error adding teacher: $e');
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
      ),
    );
  }

  void _filterTeachers(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered = allTeachers.where((teacher) {
      return teacher.name.toLowerCase().contains(lowerQuery) ||
          teacher.loginId.toLowerCase().contains(lowerQuery) ||
          teacher.password.toLowerCase().contains(lowerQuery) ||
          teacher.createdAt.toLowerCase().contains(lowerQuery);
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
        title: 'Teacher',
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onLogoutTap: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      drawer: RoleBasedDrawer(
        role: userRole,
        scaffoldKey: _scaffoldKey,
      ),
      backgroundColor: const Color.fromARGB(255, 245, 245, 240),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                  child: Row(
                    children: [
                      const Text('Teachers', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  icon: const Icon(Icons.filter_list),
                                  tooltip: 'Search Teachers',
                                  onPressed: _toggleSearch,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: visibleTeachers.length,
                    itemBuilder: (context, index) {
                      final teacher = visibleTeachers[index];
                     return Card(
  color: const Color.fromARGB(255, 245, 245, 245),
  margin: const EdgeInsets.only(bottom: 16),
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
          child: Text("Login ID: ${teacher.loginId}",
              style: const TextStyle(color: Color(0xFF60615D))),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
          child: Text("Password: ${teacher.password}",
              style: const TextStyle(color: Color(0xFF60615D))),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
          child: Text("Created At: ${teacher.createdAt}",
              style: const TextStyle(color: Color(0xFF60615D))),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        tooltip: 'Add Teacher',
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}
