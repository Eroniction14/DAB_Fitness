/// A training category on the Trainings tab. Trainers pick one of these as
/// their speciality; [matches] also recognises older free-text ones.
class WorkoutCategory {
  final String name;
  final String image;

  /// Lower-case words that mark a free-text speciality as this category.
  final List<String> keywords;

  /// Lower-case words that rule this category out (so "Yoga" doesn't also
  /// claim "Aerial Yoga").
  final List<String> excludes;

  const WorkoutCategory({
    required this.name,
    required this.image,
    this.keywords = const [],
    this.excludes = const [],
  });

  /// Whether a trainer with [speciality] belongs in this category: the
  /// category name itself, or one of its [keywords] (case-insensitive),
  /// unless an [excludes] word appears.
  bool matches(String speciality) {
    final s = speciality.toLowerCase().trim();
    if (s.isEmpty) return false;
    if (s == name.toLowerCase()) return true;
    if (excludes.any(s.contains)) return false;
    return s.contains(name.toLowerCase()) || keywords.any(s.contains);
  }
}

class Workout {
  final String name;
  final String videos;
  final String reps;
  final String image;
  final int sets;
  final String muscleGroupTargeted;

  const Workout({
    required this.name,
    required this.videos,
    required this.image,
    required this.reps,
    required this.sets,
    required this.muscleGroupTargeted,
  });
}

/// A category of offline workout videos, e.g. "Mobility".
class VideoCategory {
  final String category;
  final String image;
  final List<Workout> workouts;

  const VideoCategory({
    required this.category,
    required this.workouts,
    required this.image,
  });
}
