enum Difficulty { easy, medium, hard, daily }

class DifficultyConfig {
  const DifficultyConfig({
    required this.label,
    required this.description,
    required this.holes,
    required this.useSymmetry,
  });

  final String label;
  final String description;
  final int holes;
  final bool useSymmetry;
}

extension DifficultyX on Difficulty {
  DifficultyConfig get config {
    switch (this) {
      case Difficulty.easy:
        return const DifficultyConfig(
          label: 'Easy',
          description: 'Beginner-friendly board.',
          holes: 38,
          useSymmetry: false,
        );
      case Difficulty.medium:
        return const DifficultyConfig(
          label: 'Medium',
          description: 'Balanced challenge for daily play.',
          holes: 46,
          useSymmetry: false,
        );
      case Difficulty.hard:
        return const DifficultyConfig(
          label: 'Hard',
          description: 'Dense board with fewer givens.',
          holes: 54,
          useSymmetry: false,
        );
      case Difficulty.daily:
        return const DifficultyConfig(
          label: 'Daily',
          description: 'Deterministic challenge seeded by date.',
          holes: 46,
          useSymmetry: true,
        );
    }
  }
}
