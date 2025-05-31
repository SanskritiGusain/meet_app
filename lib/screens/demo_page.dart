import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/screens/batch_screen.dart';



class Demo {
  final String title;
  final String demoDate;
  final String startTime;
  final String endTime;
  final String createdOn;

  const Demo({
    required this.title,
    required this.demoDate,
    required this.startTime,
    required this.endTime,
    required this.createdOn,
  });
    static String _cleanTitle(dynamic title) {
  final t = (title ?? '').toString().trim();
  if (t.isEmpty || RegExp(r'^-+$').hasMatch(t)) {
    return "Untitled Batch";
  }
  return t;
}



  factory Demo.fromJson(Map<String, dynamic> json) {
    return Demo(
       title: _cleanTitle(json['title']),
      demoDate: json['demoDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      createdOn: json['createdAt'] ?? '',
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Demo> visibleBatches = [];
  List<Demo> allDemos = [];
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;



  @override
  
  void initState() {
    super.initState();
    fetchDemos();
  }
 


  Future<void> fetchDemos() async {
    const url =
        'https://meet-api.apt.shiksha/api/Demos?filter={"order": "createdAt DESC"}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final demos = jsonData.map((e) => Demo.fromJson(e)).toList();

        setState(() {
          allDemos = demos;
          visibleBatches = demos;
          _isLoading = false;
        });
      } else {
        print("Failed to fetch: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      if (_showSearch) {
        _searchController.clear();
        visibleBatches = allDemos;
      }
      _showSearch = !_showSearch;
    });
  }

  void _filterBatches(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered = allDemos.where((demo) {
      return demo.title.toLowerCase().contains(lowerQuery) ||
          demo.startTime.contains(query) ||
          demo.endTime.contains(query) ||
          demo.createdOn.toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() {
      visibleBatches = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
   drawer: Drawer(
  child: Container(
    color: Color.fromARGB(255, 239, 238, 238), // <-- Set your desired background color here
    child: ListView(
      padding: const EdgeInsets.fromLTRB(0, 50, 0, 10),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 241, 240, 240),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Batches'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BatchScreen()),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 234, 233, 233),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.play_circle_fill),
            title: const Text('Demo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DemoScreen()),
              );
            },
          ),
        ),
      ],
    ),
  ),
),



      backgroundColor: const Color.fromARGB(255, 245, 245, 240),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (context) {
            return NavBar(
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              onLogoutTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Demo',
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
                                  hintText: 'Search demo...',
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
                                  icon: const Icon(Icons.filter_list),
                                  tooltip: 'Search demo',
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
                    itemCount: visibleBatches.length,
                    itemBuilder: (context, index) {
                      final demo = visibleBatches[index];
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
  demo.title,
  style: TextStyle(
    fontSize: 18,
    fontWeight: demo.title == "Untitled Batch" ? FontWeight.w400 : FontWeight.bold,
  ),
  softWrap: true,
),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.edit, color: Color.fromARGB(255, 96, 97, 93)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                child: Text("Demo Date: ${demo.demoDate}",
                                    style: const TextStyle(color: Color.fromARGB(255, 96, 97, 93))),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                child: Text("Start Time: ${demo.startTime}",
                                    style: const TextStyle(color: Color.fromARGB(255, 96, 97, 93))),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                child: Text("End Time: ${demo.endTime}",
                                    style: const TextStyle(color: Color.fromARGB(255, 96, 97, 93))),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                child: Text("Created On: ${demo.createdOn}",
                                    style: const TextStyle(color: Color.fromARGB(255, 96, 97, 93))),
                              ),
                              const SizedBox(height: 25),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                       onPressed: () {
 
  },

                                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                                      label: const Text("Start Demo", style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(255, 32, 32, 31),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        elevation: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.link, color: Colors.white),
                                      label: const Text("Copy Link", style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(255, 32, 32, 31),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        onPressed: () {
          print("Create Batch button pressed");
        },
        tooltip: 'Create Batch',
        backgroundColor: const Color.fromARGB(255, 32, 32, 31),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
    );
  }
}
