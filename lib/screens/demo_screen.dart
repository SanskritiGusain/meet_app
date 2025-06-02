import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/models/demo_model.dart';
import 'package:my_app/dialog_box/demo_dialog.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Demo> allDemos = [];
  List<Demo> visibleDemos = [];
  bool _showSearch = false;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final String userRole = 'teacher';

  @override
  void initState() {
    super.initState();
    fetchDemos();
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
      return demo.title.toLowerCase().contains(q) ||
          demo.startTime.contains(q) ||
          demo.endTime.contains(q) ||
          demo.createdOn.toLowerCase().contains(q);
    }).toList();
    setState(() => visibleDemos = filtered);
  }

  void _copyDemoLink(Demo demo) {
    final demoLink = "https://example.com/demo/${Uri.encodeComponent(demo.title)}";
    Clipboard.setData(ClipboardData(text: demoLink)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo link copied to clipboard')),
      );
    });
  }

  void _startDemo(Demo demo) {
    final demoUrl = "https://example.com/start-demo/${Uri.encodeComponent(demo.title)}";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Starting demo: $demoUrl')));
  }

  void _openDemoDialog({Demo? demo}) async {
    final result = await showDialog<Demo>(
      context: context,
      builder: (_) => DemoDialog(demo: demo),
    );
    if (result != null) {
      final isUpdate = demo != null && demo.id != null;
      final url = isUpdate
          ? 'https://meet-api.apt.shiksha/api/Demos/${demo.id}'
          : 'https://meet-api.apt.shiksha/api/Demos';
      try {
     final response = isUpdate
    ? await http.put(  // <-- Use PUT here for update
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
            SnackBar(content: Text(isUpdate ? 'Demo updated' : 'Demo added')),
          );
        } else {
          throw Exception('Failed to save demo');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving demo')),
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
        onLogoutTap: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
      drawer: RoleBasedDrawer(role: userRole, scaffoldKey: _scaffoldKey),
      body: isLoading
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
                                  icon: const Icon(Icons.filter_list),
                                  tooltip: 'Search Demos',
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
                    itemCount: visibleDemos.length,
                    itemBuilder: (context, index) {
                      final demo = visibleDemos[index];
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
                                      demo.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: demo.title == "Untitled Demo"
                                            ? FontWeight.w400
                                            : FontWeight.bold,
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
                              ...[
                                "Demo Date: ${demo.demoDate}",
                                "Start Time: ${demo.startTime}",
                                "End Time: ${demo.endTime}",
                                "Created On: ${demo.createdOn}",
                              ].map((text) => Padding(
                                    padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                    child: Text(text,
                                        style: const TextStyle(color: Color(0xFF60615D))),
                                  )),
                              const SizedBox(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _startDemo(demo),
                                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                                      label: const Text("Start Demo",
                                          style: TextStyle(color: Colors.white, fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF20201F),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        elevation: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _copyDemoLink(demo),
                                      icon: const Icon(Icons.link, color: Colors.white),
                                      label: const Text("Copy Link",
                                          style: TextStyle(color: Colors.white, fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF20201F),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        elevation: 4,
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
