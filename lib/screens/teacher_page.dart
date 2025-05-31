import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/screens/batch_screen.dart';
import 'package:my_app/screens/demo_page.dart';
import 'package:my_app/screens/navBar.dart';

class Teacher {
  final String loginId;
  final String name;
  final String password;
  final String createdAt;

  Teacher({
    required this.loginId,
    required this.name,
    required this.password,
    required this.createdAt,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      loginId: json['loginId'] ?? '',
      name: json['name'] ?? '',
      password: json['password'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

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

  void _showAddTeacherDialog() {
    final nameController = TextEditingController();
    final loginIdController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Add Teacher"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: loginIdController,
                  decoration: const InputDecoration(labelText: "Login ID"),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final loginId = loginIdController.text.trim();
                final password = passwordController.text.trim();

                if (name.isNotEmpty && loginId.isNotEmpty && password.isNotEmpty) {
                  await _addTeacher(name, loginId, password);
                  Navigator.pop(context);
                }
              },
              child: const Text("ADD"),
            ),
          ],
        );
      },
    );
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
      drawer: Drawer(
        child: Container(
          color: const Color(0xFFEFEFEF),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 50, 0, 10),
            children: [
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Batches'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BatchScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: const Text('Demo'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DemoScreen()));
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 245, 245, 240),
      appBar: NavBar(
        onMenuTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onLogoutTap: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
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
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(teacher.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text("Login ID: ${teacher.loginId}", style: const TextStyle(color: Color(0xFF60615D))),
                              Text("Password: ${teacher.password}", style: const TextStyle(color: Color(0xFF60615D))),
                              Text("Created At: ${teacher.createdAt}", style: const TextStyle(color: Color(0xFF60615D))),
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
