import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peoplesql/address_api.dart';
import 'package:peoplesql/db_helper.dart';
import 'group_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> _allPeople = [];
  List<Map<String, dynamic>> _allGroups = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  // Fetch and refresh the list of people from the database
  void _refreshPeople() async {
    final data = await SQLHelper.getAllPeople();
    setState(() {
      _allPeople = data;
      _isLoading = false;
    });
  }

  // Fetch and refresh the list of groups from the database
  Future<void> _refreshGroups() async {
    final data = await SQLHelper.getAllGroups();
    setState(() {
      _allGroups = data;

      if (_selectedGroupId != null &&
          !_allGroups.any((group) => group['id'] == _selectedGroupId)) {
        _selectedGroupId = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshPeople();
    _refreshGroups();
  }

  // Text editing controllers for form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  int? _selectedGroupId;

  // Add a new person to the database
  Future<void> _addPerson() async {
    await SQLHelper.createPerson(
      _firstNameController.text,
      _lastNameController.text,
      _dateOfBirthController.text,
      _addressController.text,
      _postalCodeController.text,
      _cityController.text,
      _selectedGroupId,
    );
    _refreshPeople();
  }

  // Update an existing person's information in the database
  Future<void> _updatePerson(int id) async {
    await SQLHelper.updatePerson(
      id,
      _firstNameController.text,
      _lastNameController.text,
      _dateOfBirthController.text,
      _addressController.text,
      _postalCodeController.text,
      _cityController.text,
      _selectedGroupId,
    );
    _refreshPeople();
  }

  // Delete a person from the database
  void _deletePerson(int id) async {
    await SQLHelper.deletePerson(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text("Person Deleted"),
      ),
    );
    _refreshPeople();
  }

  // Fetch address data based on the postal code
  Future<void> fetchAddressData(String postalCode) async {
    final addressData = await APIHelper.fetchAddressData(postalCode);
    if (addressData.isNotEmpty) {
      _addressController.text = addressData['ulica'] ?? '';
      _cityController.text = addressData['miejscowosc'] ?? '';
    } else {
      _addressController.clear();
      _cityController.clear();
    }
  }

  // Show the bottom sheet for adding or editing a person
  Future<void> showBottomSheet(int? id) async {
    await _refreshGroups();

    if (id != null) {
      final existingPerson =
          _allPeople.firstWhere((element) => element['id'] == id);
      _firstNameController.text = existingPerson['first_name'];
      _lastNameController.text = existingPerson['last_name'];
      _dateOfBirthController.text = existingPerson['date_of_birth'];
      _postalCodeController.text = existingPerson['postal_code'];
      _addressController.text = existingPerson['address'];
      _cityController.text = existingPerson['city'];
      _selectedGroupId = existingPerson['group_id'];
    } else {
      _firstNameController.clear();
      _lastNameController.clear();
      _dateOfBirthController.clear();
      _addressController.clear();
      _cityController.clear();
      _selectedGroupId = null;
    }

    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: 30,
            left: 15,
            right: 15,
            bottom: MediaQuery.of(context).viewInsets.bottom + 50,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "First Name",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Last Name",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _dateOfBirthController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Date of Birth",
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DateInputFormatter(),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Postal Code",
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    PostalCodeInputFormatter(),
                  ],
                  onChanged: (value) {
                    if (value.length == 6) {
                      fetchAddressData(value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Street Address",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "City",
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _selectedGroupId,
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text("No Group"),
                    ),
                    ..._allGroups.map((group) {
                      return DropdownMenuItem<int>(
                        value: group['id'],
                        child: Text(group['name']),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGroupId = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Select Group",
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (id == null) {
                          await _addPerson();
                        } else {
                          await _updatePerson(id);
                        }

                        _firstNameController.clear();
                        _lastNameController.clear();
                        _dateOfBirthController.clear();
                        _postalCodeController.clear();
                        _addressController.clear();
                        _cityController.clear();
                        _selectedGroupId = null;

                        Navigator.of(context).pop();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        id == null ? "Add Person" : "Update",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigate to the group management screen
  Future<void> _navigateToGroups() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupScreen()),
    );
    if (result == true) {
      _refreshGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEAF4),
      appBar: AppBar(
        title: const Text("People Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: _navigateToGroups,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _allPeople.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.all(15),
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      '${_allPeople[index]['first_name']} ${_allPeople[index]['last_name']}',
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_allPeople[index]['address']}, ${_allPeople[index]['postal_code']} ${_allPeople[index]['city']}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Date of Birth: ${_allPeople[index]['date_of_birth']}',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showBottomSheet(_allPeople[index]['id']);
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.indigo,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _deletePerson(_allPeople[index]['id']);
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBottomSheet(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Formatter for postal code in the format xx-xxx
class PostalCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length > 6) {
      return oldValue;
    }

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('-');
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection.copyWith(
        baseOffset: buffer.length,
        extentOffset: buffer.length,
      ),
    );
  }
}

// Formatter for date of birth in the format dd.mm.yyyy
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length > 10) {
      return oldValue;
    }

    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection.copyWith(
        baseOffset: buffer.length,
        extentOffset: buffer.length,
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

