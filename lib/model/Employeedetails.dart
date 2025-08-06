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
    required this.joiningDate,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  factory Employee.fromMap(Map<String, dynamic> data) {
    return Employee(
      
      name: data['name'] ?? '',
      number: data['number'] ?? '',
      state: data['state'] ?? '',
      salary: data['salary']?.toString() ?? '',
      section: data['section'] ?? '',
      imageUrl: data['image'] ?? '',
      profileImageUrl: data['profileimage'] ?? '',
      district: data['district'] ?? '',
      joiningDate: data['joiningDate'],
      location: data['location'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
    );
  }
}