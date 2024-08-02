import 'package:flutter/material.dart';
import 'package:peoplesql/db_helper.dart';

class GroupScreen extends StatefulWidget {
  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  List<Map<String, dynamic>> _allGroups = [];
  bool _isLoading = true;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshGroups();
  }

  void _refreshGroups() async {
    final data = await SQLHelper.getAllGroups();
    setState(() {
      _allGroups = data;
      _isLoading = false;
    });
  }

  Future<void> _addGroup() async {
    await SQLHelper.createGroup(_nameController.text);
    _refreshGroups();
    _nameController.clear();
  }

  Future<void> _updateGroup(int id) async {
    await SQLHelper.updateGroup(id, _nameController.text);
    _refreshGroups();
    _nameController.clear();
  }

  void _deleteGroup(int id) async {
    final count = await SQLHelper.getPeopleCountInGroup(id);
    if (count! > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Cannot delete group with assigned people"),
        ),
      );
    } else {
      await SQLHelper.deleteGroup(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Group Deleted"),
        ),
      );
      _refreshGroups();
    }
  }

  Future<void> _showGroupForm(int? id) async {
    if (id != null) {
      final existingGroup = _allGroups.firstWhere((element) => element['id'] == id);
      _nameController.text = existingGroup['name'];
    } else {
      _nameController.clear();
    }

    showModalBottomSheet(
      elevation: 5,
      isScrollControlled: true,
      context: context,
      builder: (_) => GroupForm(
        nameController: _nameController,
        onSave: () async {
          if (id == null) {
            await _addGroup();
          } else {
            await _updateGroup(id);
          }
          Navigator.of(context).pop(true); // Return true to indicate that data has changed
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEAF4),
      appBar: AppBar(
        title: const Text("Group Management"),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _allGroups.length,
              itemBuilder: (context, index) => GroupCard(
                group: _allGroups[index],
                onEdit: () => _showGroupForm(_allGroups[index]['id']),
                onDelete: () => _deleteGroup(_allGroups[index]['id']),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GroupForm extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onSave;

  const GroupForm({
    required this.nameController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 30,
        left: 15,
        right: 15,
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Group Name",
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: onSave,
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GroupCard({
    required this.group,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(15),
      child: ExpansionTile(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(
            group['name'],
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
        ),
        subtitle: FutureBuilder(
          future: SQLHelper.getPeopleCountInGroup(group['id']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading...");
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else {
              return Text("Members: ${snapshot.data}");
            }
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit,
                color: Colors.indigo,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
          ],
        ),
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: SQLHelper.getPeopleInGroup(group['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                return const Text("No members in this group");
              } else {
                return Column(
                  children: snapshot.data!.map((person) {
                    return ListTile(
                      title: Text('${person['first_name']} ${person['last_name']}'),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously
