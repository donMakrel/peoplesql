import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqflite.dart';

class SQLHelper {
  // Create the tables for the database
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE people(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      first_name TEXT,
      last_name TEXT,
      date_of_birth TEXT,
      address TEXT,
      postal_code TEXT,  
      city TEXT,         
      group_id INTEGER,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )""");

    await database.execute("""CREATE TABLE groups(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      name TEXT,
      createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )""");
  }


  // Open the database connection
  static Future<sql.Database> db() async {
    return sql.openDatabase(
      "aha_databases.db",
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  // People CRUD Operations

  // Create a new person record
  static Future<int> createPerson(String firstName, String lastName, String dateOfBirth, String address, String postalCode, String city, int? groupId) async {
    final db = await SQLHelper.db();
    final data = {
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'address': address,
      'postal_code': postalCode,
      'city': city,
      'group_id': groupId
    };
    return db.insert('people', data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  // Get all people records
  static Future<List<Map<String, dynamic>>> getAllPeople() async {
    final db = await SQLHelper.db();
    return db.query('people', orderBy: 'id');
  }

  // Get a specific person record by ID
  static Future<List<Map<String, dynamic>>> getPerson(int id) async {
    final db = await SQLHelper.db();
    return db.query('people', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an existing person record
  static Future<int> updatePerson(int id, String firstName, String lastName, String dateOfBirth, String address, String postalCode, String city, int? groupId) async {
    final db = await SQLHelper.db();
    final data = {
      'first_name': firstName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'address': address,
      'postal_code': postalCode,
      'city': city,
      'group_id': groupId,
      'createdAt': DateTime.now().toString()
    };
    return db.update('people', data, where: "id = ?", whereArgs: [id]);
  }

  // Delete a person record
  static Future<void> deletePerson(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete('people', where: "id = ?", whereArgs: [id]);
    } catch (e) {
      // Handle error
    }
  }

  // Groups CRUD Operations

  // Create a new group record
  static Future<int> createGroup(String name) async {
    final db = await SQLHelper.db();
    final data = {'name': name};
    return db.insert('groups', data, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  // Get all group records
  static Future<List<Map<String, dynamic>>> getAllGroups() async {
    final db = await SQLHelper.db();
    return db.query('groups', orderBy: 'id');
  }

  // Get a specific group record by ID
  static Future<List<Map<String, dynamic>>> getGroup(int id) async {
    final db = await SQLHelper.db();
    return db.query('groups', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Get all people in a specific group
  static Future<List<Map<String, dynamic>>> getPeopleInGroup(int groupId) async {
    final db = await SQLHelper.db();
    return db.query('people', where: "group_id = ?", whereArgs: [groupId]);
  }

  // Update an existing group record
  static Future<int> updateGroup(int id, String name) async {
    final db = await SQLHelper.db();
    final data = {
      'name': name,
      'createdAt': DateTime.now().toString()
    };
    return db.update('groups', data, where: "id = ?", whereArgs: [id]);
  }

  // Clear group ID for all people in a specific group
  static Future<void> clearGroupForPeople(int groupId) async {
    final db = await SQLHelper.db();
    await db.update('people', {'group_id': null}, where: "group_id = ?", whereArgs: [groupId]);
  }

  // Delete a group record
  static Future<void> deleteGroup(int id) async {
    final db = await SQLHelper.db();
    try {
      await clearGroupForPeople(id);
      await db.delete('groups', where: "id = ?", whereArgs: [id]);
    } catch (e) {
      // Handle error
    }
  }

  // Get the count of people in a specific group
  static Future<int?> getPeopleCountInGroup(int groupId) async {
    final db = await SQLHelper.db();
    var x = await db.rawQuery('SELECT COUNT(*) FROM people WHERE group_id = ?', [groupId]);
    int? count = Sqflite.firstIntValue(x);
    return count;
  }
}
