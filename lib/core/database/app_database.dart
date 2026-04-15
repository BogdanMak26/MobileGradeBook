// lib/core/database/app_database.dart

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// ─── TABLE DEFINITIONS ───────────────────────────────────────────────────────

class Disciplines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  TextColumn get departmentId => text().nullable()();
  TextColumn get instructorId => text().nullable()();
  IntColumn get semester => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get serverVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get facultyId => text().nullable()();
  IntColumn get courseYear => integer().nullable()();
  TextColumn get departmentId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Cadets extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get middleName => text().nullable()();
  TextColumn get email => text()();
  TextColumn get groupId => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Instructors extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get middleName => text().nullable()();
  TextColumn get email => text()();
  TextColumn get departmentId => text().nullable()();
  TextColumn get position => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get disciplineId => text()();
  TextColumn get groupId => text()();
  IntColumn get lessonNumber => integer().nullable()();
  TextColumn get topic => text().nullable()();
  TextColumn get type => text().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get serverVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Grades extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text()();
  TextColumn get cadetId => text()();
  IntColumn get score => integer().nullable()();
  TextColumn get gradeValue => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get serverVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  IntColumn get clientVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get payload => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
}

// ─── DATABASE ─────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Disciplines,
  Groups,
  Cadets,
  Instructors,
  Lessons,
  Grades,
  SyncLog,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'gradebook_db');
  }

  // ── Grades ──────────────────────────────────────────────────────────────────

  Future<List<Grade>> getGradesForLesson(String lessonId) =>
      (select(grades)..where((g) => g.lessonId.equals(lessonId))).get();

  Future<List<Grade>> getGradesForCadet(String cadetId) =>
      (select(grades)..where((g) => g.cadetId.equals(cadetId))).get();

  Future<void> upsertGrade(GradesCompanion grade) =>
      into(grades).insertOnConflictUpdate(grade);

  Future<void> markGradeForSync(String gradeId, String payload) async {
    await batch((b) {
      b.update(
        grades,
        const GradesCompanion(isSynced: Value(false)),
        where: (g) => g.id.equals(gradeId),
      );
      b.insert(
        syncLog,
        SyncLogCompanion(
          entityType: const Value('grade'),
          entityId: Value(gradeId),
          operation: const Value('UPDATE'),
          timestamp: Value(DateTime.now()),
          payload: Value(payload),
        ),
      );
    });
  }

  // ── SyncLog ─────────────────────────────────────────────────────────────────

  Future<List<SyncLogData>> getPendingSyncItems() =>
      (select(syncLog)..where((s) => s.isSynced.equals(false))).get();

  Future<void> markSyncItemDone(int id) =>
      (update(syncLog)..where((s) => s.id.equals(id)))
          .write(const SyncLogCompanion(isSynced: Value(true)));

  Future<void> incrementRetry(int id, String error) async {
    final item = await (select(syncLog)..where((s) => s.id.equals(id))).getSingle();
    await (update(syncLog)..where((s) => s.id.equals(id))).write(
      SyncLogCompanion(
        retryCount: Value(item.retryCount + 1),
        errorMessage: Value(error),
      ),
    );
  }

  // ── Disciplines ─────────────────────────────────────────────────────────────

  Future<List<Discipline>> getAllDisciplines() => select(disciplines).get();

  Future<void> upsertDiscipline(DisciplinesCompanion d) =>
      into(disciplines).insertOnConflictUpdate(d);

  // ── Lessons ─────────────────────────────────────────────────────────────────

  Future<List<Lesson>> getLessonsForDiscipline(String disciplineId) =>
      (select(lessons)
            ..where((l) => l.disciplineId.equals(disciplineId))
            ..orderBy([(l) => OrderingTerm(expression: l.date)]))
          .get();

  Future<void> upsertLesson(LessonsCompanion l) =>
      into(lessons).insertOnConflictUpdate(l);

  // ── Cadets ──────────────────────────────────────────────────────────────────

  Future<List<Cadet>> getCadetsForGroup(String groupId) =>
      (select(cadets)..where((c) => c.groupId.equals(groupId))).get();

  Future<void> upsertCadet(CadetsCompanion c) =>
      into(cadets).insertOnConflictUpdate(c);
}

// ─── Provider (ручний) ────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
