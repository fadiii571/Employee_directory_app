class Employee {
  final String name;
  final String number;
  final String state;
  final String salary;
  final String section;
  final String imageUrl;
  final String profileImageUrl;

  Employee({
    required this.name,
    required this.number,
    required this.state,
    required this.salary,
    required this.section,
    required this.imageUrl,
    required this.profileImageUrl,
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
    );
  }
}