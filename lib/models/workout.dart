class WorkoutCategory {
  final String name;
  final String image;

  const WorkoutCategory({
    required this.name,
    required this.image,
  });
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
