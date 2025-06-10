import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/models/demo_model.dart';
import 'package:my_app/models/guest_model.dart';
import 'package:my_app/dialog_box/demo_dialog.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart';
import 'package:my_app/jitsi_meet/jitsi_service.dart';
import 'package:my_app/dialog_box/guest_filter_dialog.dart'; // Add this import
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // Add this dependency to pubspec.yaml

class GuestScreen extends StatefulWidget {
  final String userRole;
  final String? demoId;
  final String? demoTitle;
  
  const GuestScreen({ 
    Key? key, 
    required this.userRole,
    this.demoId,
    this.demoTitle,
  }) : super(key: key);

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final JitsiService _jitsiService = JitsiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Guest> allGuests = [];
  List<Guest> visibleGuests = [];
  bool _showSearch = false;
  bool isLoading = true;
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _jitsiService.initialize();
    fetchGuests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to format UTC date to IST with desired format
  String formatDateToIST(String utcDateString) {
    try {
      // Parse the UTC date string
      DateTime utcDate = DateTime.parse(utcDateString);
      
      // Convert to IST (UTC + 5:30)
      DateTime istDate = utcDate.add(const Duration(hours: 5, minutes: 30));
      
      // Format as "28 Jun 2025 - 02:14 PM"
      String formattedDate = DateFormat('dd MMM yyyy - hh:mm a').format(istDate);
      
      return formattedDate;
    } catch (e) {
      // Return original string if parsing fails
      return utcDateString;
    }
  }

  // Fetch guests from API
  Future<void> fetchGuests() async {
    String url;
    
    if (widget.demoId != null) {
      url = 'https://meet-api.apt.shiksha/api/Demos/${widget.demoId}?filter={"include":{"relation":"guests","scope":{"order":"createdAt DESC"}}}';
    } else {
      url = 'https://meet-api.apt.shiksha/api/Guests?filter={"order": "createdAt DESC"}';
    }
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<Guest> guests = [];
        
        if (widget.demoId != null) {
          final Map<String, dynamic> demoData = json.decode(response.body);
          if (demoData['guests'] != null) {
            final List<dynamic> guestsJson = demoData['guests'];
            guests = guestsJson.map((e) => Guest.fromJson(e)).toList();
          }
        } else {
          final List<dynamic> jsonData = json.decode(response.body);
          guests = jsonData.map((e) => Guest.fromJson(e)).toList();
        }
        
        setState(() {
          allGuests = guests;
          visibleGuests = guests;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load guests');
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading guests: $e')),
        );
      }
    }
  }

  // Toggle search functionality
  void _toggleSearch() {
    setState(() {
      if (_showSearch) {
        _searchController.clear();
        visibleGuests = allGuests;
        _hasActiveFilters = false;
      }
      _showSearch = !_showSearch;
    });
  }

  // Filter guests based on search query
  void _filterGuests(String query) {
    final filtered = allGuests.where((guest) {
      final q = query.toLowerCase();
      return guest.name.toLowerCase().contains(q) ||
          guest.mobile.contains(q) ||
          guest.createdOnWithTime.toLowerCase().contains(q) ||
          guest.email.toLowerCase().contains(q);
    }).toList();
    setState(() {
      visibleGuests = filtered;
      _hasActiveFilters = query.isNotEmpty;
    });
  }

  // Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GuestFilterDialog(
          onFilterApplied: (filtered) {
            setState(() {
              visibleGuests = filtered;
              _hasActiveFilters = filtered.length != allGuests.length;
            });
          },
          allGuests: allGuests,
        );
      },
    );
  }

  // Clear all filters
void _clearFilters() {
  setState(() {
    visibleGuests = allGuests;
    _hasActiveFilters = false;
    _searchController.clear(); // Also clear search if active
    _showSearch = false; // Hide search bar
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('All filters and search cleared'),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
    ),
  );
}

  // Export guests to CSV
  Future<void> _exportToCsv() async {
    try {
      String csvContent = 'Name,Mobile,Email,Created At\n';
      
      for (final guest in visibleGuests) {
        String escapeCsvField(String field) {
          if (field.contains(',') || field.contains('"') || field.contains('\n')) {
            return '"${field.replaceAll('"', '""')}"';
          }
          return field;
        }
        
        csvContent += '${escapeCsvField(guest.name)},'
                     '${escapeCsvField(guest.mobile)},'
                     '${escapeCsvField(guest.email)},'
                     '${escapeCsvField(guest.createdOnWithTime)}\n';
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = widget.demoId != null 
          ? 'demo_${widget.demoId}_guests_${DateTime.now().millisecondsSinceEpoch}.csv'
          : 'all_guests_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvContent);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.demoId != null 
            ? 'Demo Guests Export'
            : 'All Guests Export',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully! ${visibleGuests.length} guests exported.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open demo dialog
  void _openDemoDialog({Demo? demo}) async {
    final result = await showDialog<Demo>(
      context: context,
      builder: (_) => DemoDialog(demo: demo),
    );
    if (result != null) {
      // Handle demo dialog result if needed
    }
  }

  // Navigate back to demo screen
  void _navigateToDemoScreen() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: NavBar(
        title: widget.demoId != null ? 'Demo Guests' : 'Guests',
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
                _buildHeader(),
                _buildGuestCountText(),
                _buildActionButtons(),
                const SizedBox(height: 8),
                _buildGuestsList(),
              ],
            ),
      floatingActionButton: widget.demoId == null
          ? FloatingActionButton(
              onPressed: () => _openDemoDialog(),
              tooltip: 'Create Demo',
              backgroundColor: const Color(0xFF20201F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.add, size: 35, color: Colors.white),
            )
          : null,
    );
  }

  // Build header with back button, title, and search
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Row(
        children: [
          if (widget.demoId != null) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _navigateToDemoScreen,
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 24,
                ),
                tooltip: 'Back to Demos',
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.demoId != null ? 'Demo Guests' : 'Guests',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSearchWidget(),
        ],
      ),
    );
  }

  // Build search widget
  Widget _buildSearchWidget() {
    return _showSearch
        ? Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search guests...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterGuests('');
                    _toggleSearch();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterGuests,
            ),
          )
        : IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Guests',
            onPressed: _toggleSearch,
          );
  }

  // Build guest count text
  Widget _buildGuestCountText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Total Guests: ${visibleGuests.length}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

 
// Updated _buildActionButtons method with icons
Widget _buildActionButtons() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        // Filter/Clear Filter Button with Icons
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _hasActiveFilters ? _clearFilters : _showFilterDialog,
            icon: Icon(
              _hasActiveFilters ? Icons.clear : Icons.filter_alt,
              size: 18,
              color: _hasActiveFilters ? Colors.red : Colors.white,
            ),
            label: Text(
              _hasActiveFilters ? 'CLEAR FILTER' : 'FILTER',
              style: TextStyle(
                color: _hasActiveFilters ? Colors.red : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasActiveFilters 
                  ? Colors.white 
                  : const Color(0xFF20201F),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: _hasActiveFilters 
                    ? const BorderSide(color: Colors.red, width: 1)
                    : BorderSide.none,
              ),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Export CSV Button with Icon
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exportToCsv,
            icon: const Icon(
              Icons.download,
              size: 18,
              color: Colors.white,
            ),
            label: const Text(
              'EXPORT CSV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20201F),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
      ],
    ),
  );
}

  // Build guests list
  Widget _buildGuestsList() {
    return Expanded(
      child: visibleGuests.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleGuests.length,
              itemBuilder: (context, index) => _buildGuestCard(visibleGuests[index]),
            ),
    );
  }

  // Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.demoId != null 
                ? 'No guests registered for this demo'
                : 'No guests found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Build individual guest card
  Widget _buildGuestCard(Guest guest) {
    return Card(
      color: const Color(0xFFF5F5F5),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guest.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: guest.name == "Untitled Guest"
                    ? FontWeight.w400
                    : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildGuestDetailRow(Icons.phone, "Mobile: ${guest.mobile}"),
            _buildGuestDetailRow(Icons.email, "Email: ${guest.email}"),
            _buildGuestDetailRow(Icons.access_time, "Created At: ${guest.createdOnWithTime}"),
          ],
        ),
      ),
    );
  }

  // Build guest detail row
  Widget _buildGuestDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF60615D)),
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
    );
  }
}