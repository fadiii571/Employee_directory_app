import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Employee Management Service
/// 
/// This service handles all employee-related operations:
/// - Creating new employee records
/// - Updating employee information
/// - Deleting employee records
/// - Retrieving employee data
/// - Managing employee cache for performance
/// 
/// All operations include proper error handling and user feedback.
class EmployeeService {
  
  // ==================== CONSTANTS ====================
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _employeesCollection = 'Employees';
  
  /// Available sections in the system
  static const List<String> availableSections = [
    'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering',
    'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'
  ];

  // ==================== CACHE MANAGEMENT ====================
  
  /// Cache for employee data to improve performance
  static final Map<String, Map<String, dynamic>> _employeeCache = {};
  
  /// Clear the employee cache
  static void clearCache() {
    _employeeCache.clear();
  }

  // ==================== EMPLOYEE CRUD OPERATIONS ====================
  
  /// Add a new employee to the system
  /// 
  /// This function creates a new employee record with all required information
  /// including personal details, work assignment, and location data.
  /// 
  /// Parameters:
  /// - Personal info: name, number, state, district
  /// - Work info: salary, section, joiningDate
  /// - Images: profileImageUrl, imageUrl
  /// - Location: location name, latitude, longitude
  /// - Auth: authNumber for identification
  /// 
  /// Returns: Future<bool> - true if successful, false otherwise
  static Future<bool> addEmployee({
    required String name,
    required String number,
    required String state,
    required String district,
    required String salary,
    required String section,
    required String joiningDate,
    required String profileImageUrl,
    required String imageUrl,
    required String location,
    required double latitude,
    required double longitude,
    required double authNumber,
    BuildContext? context,
  }) async {
    try {
      // Validate required fields
      if (name.isEmpty || number.isEmpty || section.isEmpty) {
        throw Exception('Name, number, and section are required fields');
      }

      // Validate section
      if (!availableSections.contains(section)) {
        throw Exception('Invalid section: $section. Must be one of: ${availableSections.join(', ')}');
      }

      // Validate salary
      final salaryValue = double.tryParse(salary);
      if (salaryValue == null || salaryValue <= 0) {
        throw Exception('Invalid salary amount');
      }

      // Create employee document
      final employeeData = {
        "name": name.trim(),
        "number": number.trim(),
        "state": state.trim(),
        "district": district.trim(),
        "salary": salary,
        "section": section,
        "joiningDate": joiningDate,
        "imageUrl": imageUrl,
        "profileImageUrl": profileImageUrl,
        "location": location.trim(),
        "latitude": latitude,
        "authNumber": authNumber,
        "longitude": longitude,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "isActive": true,
      };

      await _firestore.collection(_employeesCollection).add(employeeData);

      // Clear cache to ensure fresh data
      clearCache();
      
      // Show success message
      if (context != null && context.mounted) {
        _showSuccessMessage(context, "Employee added successfully");
      }

      return true;
    } catch (e) {
      // Show error message
      if (context != null && context.mounted) {
        _showErrorMessage(context, 'Error adding employee: ${e.toString()}');
      }
      return false;
    }
  }

  /// Update an existing employee's information
  /// 
  /// Parameters:
  /// - id: Employee document ID
  /// - updateData: Map of fields to update
  /// - context: BuildContext for showing messages (optional)
  /// 
  /// Returns: Future<bool> - true if successful, false otherwise
  static Future<bool> updateEmployee({
    required String id,
    required Map<String, dynamic> updateData,
    BuildContext? context,
  }) async {
    try {
      // Add update timestamp
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Validate section if being updated
      if (updateData.containsKey('section')) {
        final section = updateData['section'] as String;
        if (!availableSections.contains(section)) {
          throw Exception('Invalid section: $section');
        }
      }

      // Update employee document
      await _firestore.collection(_employeesCollection).doc(id).update(updateData);

      // Clear cache to ensure fresh data
      clearCache();

      // Show success message
      if (context != null && context.mounted) {
        _showSuccessMessage(context, "Employee updated successfully");
      }

      return true;
    } catch (e) {
      // Show error message
      if (context != null && context.mounted) {
        _showErrorMessage(context, 'Error updating employee: ${e.toString()}');
      }
      return false;
    }
  }

  /// Delete an employee (soft delete by setting isActive to false)
  ///
  /// Parameters:
  /// - id: Employee document ID
  /// - context: BuildContext for showing messages (optional)
  ///
  /// Returns: Future<bool> - true if successful, false otherwise
  static Future<bool> deleteEmployee({
    required String id,
    BuildContext? context,
  }) async {
    try {
      // Soft delete by setting isActive to false
      await _firestore.collection(_employeesCollection).doc(id).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cache
      clearCache();

      // Show success message
      if (context != null && context.mounted) {
        _showSuccessMessage(context, "Employee set to inactive successfully");
      }

      return true;
    } catch (e) {
      // Show error message
      if (context != null && context.mounted) {
        _showErrorMessage(context, 'Error updating employee status: ${e.toString()}');
      }
      return false;
    }
  }

  /// Toggle employee active status
  ///
  /// Parameters:
  /// - id: Employee document ID
  /// - isActive: New active status
  /// - context: BuildContext for showing messages (optional)
  ///
  /// Returns: Future<bool> - true if successful, false otherwise
  static Future<bool> toggleEmployeeStatus({
    required String id,
    required bool isActive,
    BuildContext? context,
  }) async {
    try {
      final updateData = {
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add appropriate timestamp based on status
      if (isActive) {
        updateData['reactivatedAt'] = FieldValue.serverTimestamp();
      } else {
        updateData['deactivatedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_employeesCollection).doc(id).update(updateData);

      // Clear cache
      clearCache();

      // Show success message
      if (context != null && context.mounted) {
        final statusText = isActive ? "activated" : "deactivated";
        _showSuccessMessage(context, "Employee $statusText successfully");
      }

      return true;
    } catch (e) {
      // Show error message
      if (context != null && context.mounted) {
        _showErrorMessage(context, 'Error updating employee status: ${e.toString()}');
      }
      return false;
    }
  }

  /// Get all active employees
  ///
  /// Returns: Future<List<Map<String, dynamic>>> - List of employee data
  static Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final snapshot = await _firestore
          .collection(_employeesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all employees (both active and inactive) for management purposes
  ///
  /// Returns: Future<List<Map<String, dynamic>>> - List of all employee data
  static Future<List<Map<String, dynamic>>> getAllEmployeesWithStatus() async {
    try {
      final snapshot = await _firestore
          .collection(_employeesCollection)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Ensure isActive field exists (for backward compatibility)
        data['isActive'] = data['isActive'] ?? true;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get only inactive employees
  ///
  /// Returns: Future<List<Map<String, dynamic>>> - List of inactive employee data
  static Future<List<Map<String, dynamic>>> getInactiveEmployees() async {
    try {
      final snapshot = await _firestore
          .collection(_employeesCollection)
          .where('isActive', isEqualTo: false)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get employees by section
  /// 
  /// Parameters:
  /// - section: Section name to filter by
  /// 
  /// Returns: Future<List<Map<String, dynamic>>> - List of employee data
  static Future<List<Map<String, dynamic>>> getEmployeesBySection(String section) async {
    try {
      final snapshot = await _firestore
          .collection(_employeesCollection)
          .where('isActive', isEqualTo: true)
          .where('section', isEqualTo: section)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a single employee by ID
  /// 
  /// Parameters:
  /// - id: Employee document ID
  /// 
  /// Returns: Future<Map<String, dynamic>?> - Employee data or null if not found
  static Future<Map<String, dynamic>?> getEmployeeById(String id) async {
    try {
      // Check cache first
      if (_employeeCache.containsKey(id)) {
        return _employeeCache[id];
      }

      // Fetch from Firestore
      final doc = await _firestore.collection(_employeesCollection).doc(id).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        
        // Cache the result
        _employeeCache[id] = data;
        
        return data;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== HELPER METHODS ====================
  
  /// Show success message to user
  static void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error message to user
  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Validate employee data before saving
  static String? validateEmployeeData(Map<String, dynamic> data) {
    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      return 'Employee name is required';
    }
    
    if (data['number'] == null || data['number'].toString().trim().isEmpty) {
      return 'Employee number is required';
    }
    
    if (data['section'] == null || !availableSections.contains(data['section'])) {
      return 'Valid section is required';
    }
    
    if (data['salary'] != null) {
      final salary = double.tryParse(data['salary'].toString());
      if (salary == null || salary <= 0) {
        return 'Valid salary amount is required';
      }
    }
    
    return null; // No validation errors
  }
}
