class Employee {
  
  final String name;
  final String number;
  final String state;
  final String salary;
  final String section;
  final String imageUrl;
  final String profileImageUrl;
  final String district;
  final String joiningDate;
  final String authNumber;
  final String location;
  final double latitude;
  final double longitude;

  Employee({
    
    required this.name,
    required this.number,
    required this.state,
    required this.salary,
    required this.section,
    required this.imageUrl,
    required this.profileImageUrl,
    required this.district,
    required this.authNumber,
    required this.joiningDate,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  /// Safely convert any value to String, handling type mismatches
  static String _safeGetString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return ''; // For timestamps/numbers, return empty string
    return value.toString();
  }

  factory Employee.fromMap(Map<String, dynamic> data) {
    return Employee(

      name: _safeGetString(data['name']),
      number: _safeGetString(data['number']),
      state: _safeGetString(data['state']),
      salary: data['salary']?.toString() ?? '',
      section: _safeGetString(data['section']),
      imageUrl: _safeGetString(data['imageUrl']),
      profileImageUrl: _safeGetString(data['profileImageUrl']),
      district: _safeGetString(data['district']),
      authNumber: _safeGetString(data['authNumber']),
      joiningDate: _safeGetString(data['joiningDate']),
      location: _safeGetString(data['location']),
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
    );
  }
}