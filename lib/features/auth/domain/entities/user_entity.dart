// lib/features/auth/domain/entities/user_entity.dart

import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String role;
  final String? photoUrl;
  final String? groupId;
  final String? departmentId;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.role,
    this.photoUrl,
    this.groupId,
    this.departmentId,
  });

  String get fullName =>
      '$lastName $firstName${middleName != null ? ' $middleName' : ''}';
  String get shortName =>
      '$lastName ${firstName.isNotEmpty ? '${firstName[0]}.' : ''}${middleName != null && middleName!.isNotEmpty ? '${middleName![0]}.' : ''}';

  @override
  List<Object?> get props => [id, email, role];
}
