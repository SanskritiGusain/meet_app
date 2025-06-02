import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/models/batch_model.dart';
import 'package:my_app/dialog_box/batch_dialog.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart';

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
  final String userRole = 'teacher';



  @override
  void initState() {
    super.initState();
    fetchBatches();
  }

  Future<void> fetchBatches() async {
   const url = 'https://meet-api.apt.shiksha/api/Batches?filter={"order": "createdAt DESC"}';
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
      final q = query.toLowerCase();
      return batch.batchName.toLowerCase().contains(q) ||
          batch.startTime.contains(q) ||
          batch.endTime.contains(q) ||
          batch.createdOn.toLowerCase().contains(q);
    }).toList();
    setState(() => visibleBatches = filtered);
  }

  void _openBatchDialog({Batch? batch}) async {
    final result = await showDialog<Batch>(
      context: context,
      builder: (_) => BatchDialog(batch: batch),
    );
    if (result != null) {
      final isUpdate = batch != null && batch.id != null;
      final url = isUpdate
          ? 'https://meet-api.apt.shiksha/api/Batches/${batch.id}'
          : 'https://meet-api.apt.shiksha/api/Batches';
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
          fetchBatches();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isUpdate ? 'Batch updated' : 'Batch added')),
          );
        } else {
          throw Exception('Failed to save batch');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving batch')),
        );
      }
    }
  }

  
  

  

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavBar(
        title: 'Batches',
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
                              color: const Color(0xFFF5F5F5),
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
                                            batch.batchName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
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
                                      "Batch Date: ${batch.batchDate}",
                                      "Start Time: ${batch.startTime}",
                                      "End Time: ${batch.endTime}",
                                      "Created On: ${batch.createdOn}",
                                    ].map(
                                      (text) => Padding(
                                        padding: const EdgeInsets.only(bottom: 5.0, left: 3.0),
                                        child: Text(text, style: const TextStyle(color: Color(0xFF60615D))),
                                      ),
                                    ),
                                    const SizedBox(height: 25),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => {},
                                            icon: const Icon(Icons.play_arrow, color: Colors.white),
                                            label: const Text(
                                              "Start Class",
                                              style: TextStyle(color: Colors.white, fontSize: 16),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF20201F),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12)),
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
              onPressed: () =>  _openBatchDialog(),
              tooltip: 'Create Batch',
              backgroundColor: const Color(0xFF20201F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.add, size: 35, color: Colors.white),
            )
          
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
