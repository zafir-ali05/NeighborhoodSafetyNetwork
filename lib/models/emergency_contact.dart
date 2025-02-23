import 'package:hive/hive.dart';
part 'emergency_contact.g.dart';

@HiveType(typeId: 0)
class EmergencyContact extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String phone;
  
  @HiveField(3)
  final String email;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });
}