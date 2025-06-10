import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:my_app/models/teacher_model.dart'; // Import the existing Teacher model

class TeacherDialog extends StatefulWidget {
  final void Function(String name, String loginId, String password)? onSave;
  final void Function(List<Teacher> teachers)? onBulkSave;

  const TeacherDialog({Key? key, this.onSave, this.onBulkSave}) : super(key: key);

  @override
  State<TeacherDialog> createState() => _TeacherDialogState();
}

class _TeacherDialogState extends State<TeacherDialog> {
  late TextEditingController nameController;
  late TextEditingController loginIdController;
  late TextEditingController passwordController;
  final _formKey = GlobalKey<FormState>();
  
  // Focus nodes for tracking focus loss
  late FocusNode nameFocusNode;
  late FocusNode loginIdFocusNode;
  late FocusNode passwordFocusNode;
  
  // Validation errors for all fields
  String? nameError;
  String? loginIdError;
  String? passwordError;
  
  // Track which fields have been touched (lost focus)
  bool nameHasBeenTouched = false;
  bool loginIdHasBeenTouched = false;
  bool passwordHasBeenTouched = false;
  
  // CSV related variables
  bool _isCSVMode = false;
  String? _selectedFileName;
  List<Teacher> _teachersFromCSV = [];
  bool _isProcessingCSV = false;
  String? _csvError;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    loginIdController = TextEditingController();
    passwordController = TextEditingController();
    
    // Initialize focus nodes
    nameFocusNode = FocusNode();
    loginIdFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    
    // Add listeners for focus changes and text changes
    nameController.addListener(_onTextChanged);
    loginIdController.addListener(_onTextChanged);
    passwordController.addListener(_onTextChanged);
    
    nameFocusNode.addListener(() => _onFocusChanged(nameFocusNode, 'name'));
    loginIdFocusNode.addListener(() => _onFocusChanged(loginIdFocusNode, 'loginId'));
    passwordFocusNode.addListener(() => _onFocusChanged(passwordFocusNode, 'password'));
  }

  @override
  void dispose() {
    nameController.removeListener(_onTextChanged);
    loginIdController.removeListener(_onTextChanged);
    passwordController.removeListener(_onTextChanged);
    
    nameController.dispose();
    loginIdController.dispose();
    passwordController.dispose();
    
    nameFocusNode.dispose();
    loginIdFocusNode.dispose();
    passwordFocusNode.dispose();
    
    super.dispose();
  }

  void _onTextChanged() {
    // Update the button state whenever text changes
    setState(() {});
  }

  void _onFocusChanged(FocusNode focusNode, String fieldName) {
    if (!focusNode.hasFocus) {
      // Field lost focus, mark as touched and validate
      setState(() {
        switch (fieldName) {
          case 'name':
            nameHasBeenTouched = true;
            nameError = _getNameError(nameController.text);
            break;
          case 'loginId':
            loginIdHasBeenTouched = true;
            loginIdError = _getLoginIdError(loginIdController.text);
            break;
          case 'password':
            passwordHasBeenTouched = true;
            passwordError = _getPasswordError(passwordController.text);
            break;
        }
      });
    }
  }

  String? _getNameError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Teacher name is required';
    }
    return null;
  }

  String? _getLoginIdError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Login ID is required';
    }
    return null;
  }

  String? _getPasswordError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  bool _isFormValid() {
    if (_isCSVMode) {
      return _teachersFromCSV.isNotEmpty && _csvError == null;
    }
    
    // Check if all fields have non-empty values (for button state)
    final nameValid = nameController.text.trim().isNotEmpty;
    final loginIdValid = loginIdController.text.trim().isNotEmpty;
    final passwordValid = passwordController.text.trim().isNotEmpty;
    
    return nameValid && loginIdValid && passwordValid;
  }

  // Enhanced CSV validation function
  String? _validateCSVFormat(List<List<dynamic>> csvData) {
    if (csvData.isEmpty) {
      return 'CSV file is empty';
    }

    List<String> expectedHeaders = ['name', 'loginid', 'password'];
    List<String> alternativeHeaders = ['name', 'login_id', 'password'];
    
    // Check if first row looks like headers
    if (csvData.isNotEmpty) {
      List<String> firstRow = csvData[0].map((e) => e.toString().toLowerCase().trim()).toList();
      
      // Check if headers match expected format
      bool hasCorrectHeaders = false;
      if (firstRow.length >= 3) {
        // Check for exact match with expected headers
        hasCorrectHeaders = (firstRow[0] == expectedHeaders[0] && 
                           (firstRow[1] == expectedHeaders[1] || firstRow[1] == alternativeHeaders[1]) &&
                           firstRow[2] == expectedHeaders[2]);
      }
      
      if (!hasCorrectHeaders) {
        return 'Invalid CSV format. Expected headers: "name", "loginid", "password"\nExample format:\nname,loginid,password\npriya,priya@123,12345678';
      }
    }

    // Validate data rows
    List<List<dynamic>> dataRows = csvData.length > 1 ? csvData.skip(1).toList() : [];
    
    if (dataRows.isEmpty) {
      return 'No data found in CSV file. Please add teacher data after the header row.';
    }

    // Check each data row
    for (int i = 0; i < dataRows.length; i++) {
      List<dynamic> row = dataRows[i];
      
      // Skip empty rows
      if (row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }
      
      if (row.length < 3) {
        return 'Row ${i + 2} has insufficient columns. Expected: name, loginid, password';
      }
      
      String name = row[0].toString().trim();
      String loginId = row[1].toString().trim();
      String password = row[2].toString().trim();
      
      if (name.isEmpty) {
        return 'Row ${i + 2}: Teacher name cannot be empty';
      }
      
      if (loginId.isEmpty) {
        return 'Row ${i + 2}: Login ID cannot be empty';
      }
      
      if (password.isEmpty) {
        return 'Row ${i + 2}: Password cannot be empty';
      }
    }
    
    return null; // No errors
  }

  Future<void> _pickCSVFile() async {
    try {
      setState(() {
        _isProcessingCSV = true;
        _csvError = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        
        // Parse CSV
        List<List<dynamic>> csvData = const CsvToListConverter().convert(contents);
        
        // Validate CSV format
        String? validationError = _validateCSVFormat(csvData);
        if (validationError != null) {
          setState(() {
            _csvError = validationError;
            _selectedFileName = null;
            _teachersFromCSV.clear();
            _isProcessingCSV = false;
          });
          return;
        }
        
        // Process valid CSV data
        List<List<dynamic>> dataRows = csvData.length > 1 ? csvData.skip(1).toList() : csvData;
        
        List<Teacher> teachers = [];
        for (var row in dataRows) {
          // Skip empty rows
          if (row.every((cell) => cell.toString().trim().isEmpty)) {
            continue;
          }
          
          if (row.length >= 3) {
            String name = row[0].toString().trim();
            String loginId = row[1].toString().trim();
            String password = row[2].toString().trim();
            
            // Only add if all fields are non-empty (already validated above)
            if (name.isNotEmpty && loginId.isNotEmpty && password.isNotEmpty) {
              teachers.add(Teacher(
                name: name,
                loginId: loginId,
                password: password,
                createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
              ));
            }
          }
        }

        setState(() {
          _selectedFileName = result.files.single.name;
          _teachersFromCSV = teachers;
          _csvError = null;
          _isProcessingCSV = false;
        });
      } else {
        setState(() {
          _isProcessingCSV = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessingCSV = false;
        _csvError = 'Error reading CSV file: ${e.toString()}';
        _selectedFileName = null;
        _teachersFromCSV.clear();
      });
    }
  }

  void _handleSave() {
    if (_isCSVMode) {
      if (_teachersFromCSV.isNotEmpty && _csvError == null) {
        widget.onBulkSave?.call(_teachersFromCSV);
        Navigator.pop(context);
      }
    } else {
      // Final validation before saving
      final name = nameController.text.trim();
      final loginId = loginIdController.text.trim();
      final password = passwordController.text.trim();

      if (name.isNotEmpty && loginId.isNotEmpty && password.isNotEmpty) {
        widget.onSave?.call(name, loginId, password);
        Navigator.pop(context);
      }
    }
  }

  void _showCSVFormatExample() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV Format Example'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your CSV file should have this format:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'name,loginid,password\npriya,priya@123,12345678\njohn,john@456,password123',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 10),
            const Text('• First row must contain headers: name, loginid, password'),
            const Text('• Each subsequent row contains one teacher\'s data'),
            const Text('• All fields are required'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 253, 250, 250),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        _isCSVMode ? 'Add Teachers' : 'Add Teacher',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          height: _isCSVMode ? 400 : 300, // Reduced heights
          child: Column( // Removed SingleChildScrollView
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle between manual and CSV mode
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCSVMode = false;
                          _selectedFileName = null;
                          _teachersFromCSV.clear();
                          _csvError = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: !_isCSVMode ? Colors.black : Colors.grey,
                              width: !_isCSVMode ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'Manual Entry',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: !_isCSVMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCSVMode = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _isCSVMode ? Colors.black : Colors.grey,
                              width: _isCSVMode ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'CSV Upload',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: _isCSVMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Reduced spacing

              if (_isCSVMode) ...[
                // CSV Format Help Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _showCSVFormatExample,
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: const Text('Format Example'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                
                // CSV Upload Section
                GestureDetector(
                  onTap: _isProcessingCSV ? null : _pickCSVFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12), // Reduced padding
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _csvError != null ? Colors.red : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 32, // Reduced icon size
                          color: _csvError != null ? Colors.red : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 6), // Reduced spacing
                        Text(
                          _selectedFileName ?? 'Choose CSV file (name, loginid, password)',
                          style: TextStyle(
                            color: _csvError != null ? Colors.red : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (_isProcessingCSV) ...[
                          const SizedBox(height: 6),
                          const SizedBox(
                            width: 16,
                            height: 16, // Smaller progress indicator
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // CSV Error Display
                if (_csvError != null) ...[
                  const SizedBox(height: 8), // Reduced spacing
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'CSV Format Error',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _csvError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),

                // Display CSV data preview
                if (_teachersFromCSV.isNotEmpty && _csvError == null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(6), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${_teachersFromCSV.length} teachers ready to add',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded( // Use Expanded instead of fixed height
                    child: ListView.builder(
                      itemCount: _teachersFromCSV.length,
                      itemBuilder: (context, index) {
                        final teacher = _teachersFromCSV[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 1),
                          child: Padding(
                            padding: const EdgeInsets.all(6), // Reduced padding
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Name',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        teacher.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Login ID',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        teacher.loginId,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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
              ] else ...[
                // Manual Entry Section with compact text fields
                Expanded(
                  child: Column(
                    children: [
                      // Teacher Name
                      TextField(
                        controller: nameController,
                        focusNode: nameFocusNode,
                        style: const TextStyle(fontSize: 14), // Smaller font
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Teacher Name *',
                          labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 136, 134, 134),
                            fontSize: 14, // Smaller label
                          ),
                          errorText: nameHasBeenTouched ? nameError : null,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12, // Smaller error text
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8), // Reduced padding
                          isDense: true, // Makes the field more compact
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: (nameHasBeenTouched && nameError != null) ? Colors.red : Colors.black12,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: (nameHasBeenTouched && nameError != null) 
                                  ? Colors.red 
                                  : const Color.fromARGB(255, 136, 134, 134),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Reduced spacing

                      // Login ID
                      TextField(
                        controller: loginIdController,
                        focusNode: loginIdFocusNode,
                        style: const TextStyle(fontSize: 14), // Smaller font
                        decoration: InputDecoration(
                          labelText: 'Login ID *',
                          labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 136, 134, 134),
                            fontSize: 14, // Smaller label
                          ),
                          errorText: loginIdHasBeenTouched ? loginIdError : null,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12, // Smaller error text
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8), // Reduced padding
                          isDense: true, // Makes the field more compact
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: (loginIdHasBeenTouched && loginIdError != null) ? Colors.red : Colors.black12,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: (loginIdHasBeenTouched && loginIdError != null) 
                                  ? Colors.red 
                                  : const Color.fromARGB(255, 136, 134, 134),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Reduced spacing

                      // Password
                      TextField(
                        controller: passwordController,
                        focusNode: passwordFocusNode,
                        obscureText: true,
                        style: const TextStyle(fontSize: 14), // Smaller font
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          labelStyle: const TextStyle(
                            color: Color.fromARGB(255, 136, 134, 134),
                            fontSize: 14, // Smaller label
                          ),
                          errorText: passwordHasBeenTouched ? passwordError : null,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12, // Smaller error text
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8), // Reduced padding
                          isDense: true, // Makes the field more compact
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: (passwordHasBeenTouched && passwordError != null) ? Colors.red : Colors.black12,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: (passwordHasBeenTouched && passwordError != null) 
                                  ? Colors.red 
                                  : const Color.fromARGB(255, 136, 134, 134),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: _cancelButtonStyle(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isFormValid() ? _handleSave : null,
          style: _addButtonStyle(_isFormValid()),
          child: const Text('ADD'),
        ),
      ],
    );
  }

  ButtonStyle _cancelButtonStyle() => TextButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 253, 250, 250),
        foregroundColor: const Color.fromARGB(255, 36, 36, 36),
        side: const BorderSide(
          color: Color.fromARGB(255, 21, 21, 21),
          width: 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  ButtonStyle _addButtonStyle(bool isEnabled) => ElevatedButton.styleFrom(
        backgroundColor: isEnabled 
            ? const Color.fromARGB(255, 39, 38, 38)
            : const Color.fromARGB(255, 158, 158, 158),
        foregroundColor: const Color.fromARGB(255, 244, 244, 244),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      );
}