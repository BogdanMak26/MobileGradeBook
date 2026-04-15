// lib/features/disciplines/domain/entities/discipline_entity.dart

import 'package:equatable/equatable.dart';

class DisciplineEntity extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? instructorId;
  final int? semester;
  final int? year;
  final String? description;

  const DisciplineEntity({
    required this.id,
    required this.name,
    this.code,
    this.instructorId,
    this.semester,
    this.year,
    this.description,
  });

  String get displayName => code != null ? '$code — $name' : name;

  @override
  List<Object?> get props => [id, name, code];
}
