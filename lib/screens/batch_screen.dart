import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/screens/demo_page.dart';



class Batch {
  
  final String title;
  final String startTime;
  final String endTime;
  final String createdOn;

  Batch({
    
    required this.title,
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


  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
     title: _cleanTitle(json['title']),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      createdOn: json['createdAt'] ?? '', // using createdAt from API
    );
  }
}

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();


}

class _BatchScreenState extends State<BatchScreen> {
    






  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Batch> allBatches = [];
  List<Batch> visibleBatches = [];
  bool _showSearch = false;
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBatches();
  }

  void showDemoDialog({Batch? batch}) {
  final TextEditingController titleController =
      TextEditingController(text: batch?.title ?? '');
  final TextEditingController dateController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;
showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      backgroundColor: Color.fromARGB(255, 253, 250, 250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(batch == null ? 'Add Demo' : 'Edit Demo'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95, // 80% of screen width
        height: 200, // Fixed height
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Demo Title *',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Demo Date *',
                ),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    dateController.text =
                        '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            startTime = picked;
                          });
                        }
                      },
                        style: TextButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 253, 250, 250), // 👈 Background color
      foregroundColor: const Color.fromARGB(255, 85, 84, 84), // 👈 Text color
      padding: const EdgeInsets.symmetric(vertical: 16), // 👈 Padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 👈 Rounded corners
        side: const BorderSide(color: Colors.black12), // Optional border
      ),
    ),
                      child: Text(
                        startTime == null
                            ? 'Start Time *'
                            : startTime!.format(context),
                      ),

                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            endTime = picked;
                          });
                        }
                        
                      },
                   style: TextButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 253, 250, 250), // 👈 Background color
      foregroundColor: const Color.fromARGB(255, 85, 84, 84), // 👈 Text color
      padding: const EdgeInsets.symmetric(vertical: 16), // 👈 Padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 👈 Rounded corners
        side: const BorderSide(color: Colors.black12), // Optional border
      ),
    ),
                      child: Text(
                        endTime == null
                            ? 'End Time *'
                            : endTime!.format(context),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
    backgroundColor: Color.fromARGB(255, 253, 250, 250), // 👈 background color
    foregroundColor: const Color.fromARGB(255, 36, 36, 36), 
       side: const BorderSide(            // Border color and width
      color: Color.fromARGB(255, 21, 21, 21),
      width: 2.0,
    ),      // 👈 text color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // Optional: rounded corners
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
          child: const Text('CANCEL'),
          
        ),
        ElevatedButton(
          onPressed: () {
            print('Title: ${titleController.text}');
            print('Date: ${dateController.text}');
            print('Start: ${startTime?.format(context)}');
            print('End: ${endTime?.format(context)}');
            Navigator.pop(context);
          },
            style: TextButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 39, 38, 38), // 👈 background color
    foregroundColor: const Color.fromARGB(255, 244, 244, 244),       // 👈 text color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // Optional: rounded corners
    ),
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
  ),
          child: Text(batch == null ? 'ADD' : 'EDIT'),
        ),
      ],
    );
  },
);

}


  

  Future<void> fetchBatches() async {
    const url = 'https://meet-api.apt.shiksha/api/Batches?filter={"order":"createdAt DESC"}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final batches = data.map((json) => Batch.fromJson(json)).toList();
        setState(() {
          allBatches = batches;
          visibleBatches = batches;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load batches');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
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
    final filtered = allBatches.where((batch) {
      final lowerQuery = query.toLowerCase();
      return batch.title.toLowerCase().contains(lowerQuery) ||
          batch.startTime.contains(query) ||
          batch.endTime.contains(query) ||
          batch.createdOn.toLowerCase().contains(lowerQuery);
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
    color: Color(0xFFEFEFEF), // <-- Set your desired background color here
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
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  tooltip: 'Search Batches',
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
                      final batch = visibleBatches[index];
                      return Card(
                        color: const Color.fromARGB(255, 245, 245, 245),
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  batch.title,
  style: TextStyle(
    fontSize: 18,
    fontWeight: batch.title == "Untitled Batch" ? FontWeight.w400 : FontWeight.bold,
  ),
  softWrap: true,
),

                                  ),
                                  IconButton(
                                    onPressed: () {
    showDemoDialog(batch: batch); // open as edit mode
  },
                                    icon: const Icon(Icons.edit,
                                        color: Color.fromARGB(255, 96, 97, 93)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                child: Text("Start Time: ${batch.startTime}",
                                    style: const TextStyle(
                                        color: Color.fromARGB(255, 96, 97, 93))),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                child: Text("End Time: ${batch.endTime}",
                                    style: const TextStyle(
                                        color: Color.fromARGB(255, 96, 97, 93))),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                child: Text("Created On: ${batch.createdOn}",
                                    style: const TextStyle(
                                        color: Color.fromARGB(255, 96, 97, 93))),
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
             
            
                                  },

                                  icon: const Icon(Icons.play_arrow,
                                      color: Colors.white, size: 25),
                                  label: const Text("Start Class",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 32, 32, 31),
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
    showDemoDialog(); // open as add mode
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