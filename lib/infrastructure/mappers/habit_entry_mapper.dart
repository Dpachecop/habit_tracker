import '../../domain/entities/date_only.dart';
import '../../domain/entities/habit_entry.dart';
import '../models/habit_entry_dto.dart';

/// Converts between the stored check-in and the domain entity.
abstract final class HabitEntryMapper {
  /// Builds the entity. Throws [FormatException] if the stored date is not
  /// `yyyy-MM-dd`.
  static HabitEntry toEntity(HabitEntryDto dto) => HabitEntry(
    habitId: dto.habitId,
    date: DateOnly.parse(dto.date),
    completedAt: dto.completedAt.toUtc(),
  );

  /// Builds the DTO.
  static HabitEntryDto toDto(HabitEntry entry) => HabitEntryDto(
    habitId: entry.habitId,
    date: entry.date.toIso8601(),
    completedAt: entry.completedAt,
  );
}
