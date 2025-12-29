// lib/core/utils/level_calculator.dart

class LevelInfo {
  final int level;
  final String fullName; // Contoh: "Iron Scholar"
  final int currentLevelPoints; // Poin saat ini di level ini (misal: 50)
  final int pointsToNextLevel; // Target poin ke level berikutnya (misal: 100)
  final double progress; // 0.0 sampai 1.0 untuk Progress Bar

  LevelInfo({
    required this.level,
    required this.fullName,
    required this.currentLevelPoints,
    required this.pointsToNextLevel,
    required this.progress,
  });
}

class LevelCalculator {
  // Konstanta: Berapa neuron untuk naik 1 level
  static const int _neuronsPerLevel = 100;

  // Daftar Pangkat Dasar (Rank) - 10 Item
  static const List<String> _baseRanks = [
    'Wanderer', // 0
    'Seeker', // 1
    'Apprentice', // 2
    'Scholar', // 3
    'Adept', // 4
    'Expert', // 5
    'Master', // 6
    'Sage', // 7
    'Architect', // 8
    'Visionary', // 9
  ];

  // Daftar Tingkatan Material (Tier)
  static const List<String> _tiers = [
    '', // Cycle 0 (Tanpa prefix)
    'Iron', // Cycle 1
    'Bronze', // Cycle 2
    'Silver', // Cycle 3
    'Gold', // Cycle 4
    'Platinum', // Cycle 5
    'Diamond', // Cycle 6
    'Obsidian', // Cycle 7
    'Ethereal', // Cycle 8
    'Celestial', // Cycle 9
    'Divine', // Cycle 10
  ];

  static LevelInfo calculate(int totalNeurons) {
    // 1. Hitung Level saat ini
    // Contoh: 1250 Neurons / 100 = Level 12
    final int level = (totalNeurons / _neuronsPerLevel).floor();

    // 2. Hitung Progress di level ini
    // Contoh: 1250 % 100 = 50 poin
    final int currentLevelPoints = totalNeurons % _neuronsPerLevel;

    // 3. Persentase (0.0 - 1.0)
    final double progress = currentLevelPoints / _neuronsPerLevel;

    // 4. Tentukan Nama Unik
    final String name = _generateName(level);

    return LevelInfo(
      level: level + 1, // Kita tampilkan mulai dari Level 1, bukan 0
      fullName: name,
      currentLevelPoints: currentLevelPoints,
      pointsToNextLevel: _neuronsPerLevel,
      progress: progress,
    );
  }

  static String _generateName(int level) {
    final int ranksCount = _baseRanks.length;

    // Index Rank: Sisa bagi level dengan jumlah rank
    // Level 12 % 10 = 2 -> 'Apprentice'
    final int rankIndex = level % ranksCount;
    final String rankName = _baseRanks[rankIndex];

    // Index Tier: Hasil bagi level dengan jumlah rank
    // Level 12 / 10 = 1 -> 'Iron'
    final int tierCycle = (level / ranksCount).floor();

    // Logika Penamaan:
    if (tierCycle < _tiers.length) {
      // Jika masih dalam daftar Tier (Iron, Bronze, dll)
      final String tierName = _tiers[tierCycle];
      if (tierName.isEmpty) {
        return rankName; // Cycle 0: "Wanderer"
      } else {
        return '$tierName $rankName'; // Cycle 1+: "Iron Apprentice"
      }
    } else {
      // Jika Level SANGAT TINGGI (Infinite Mode)
      // Contoh: "Divine Apprentice IV"
      final String lastTier = _tiers.last; // Divine
      final int extraCycle = tierCycle - _tiers.length + 1;
      final String roman = _toRoman(extraCycle);

      return '$lastTier $rankName $roman';
    }
  }

  // Helper sederhana untuk Angka Romawi (untuk level sangat tinggi)
  static String _toRoman(int number) {
    if (number <= 0) return "";
    if (number >= 1000) return "M${_toRoman(number - 1000)}";
    if (number >= 900) return "CM${_toRoman(number - 900)}";
    if (number >= 500) return "D${_toRoman(number - 500)}";
    if (number >= 400) return "CD${_toRoman(number - 400)}";
    if (number >= 100) return "C${_toRoman(number - 100)}";
    if (number >= 90) return "XC${_toRoman(number - 90)}";
    if (number >= 50) return "L${_toRoman(number - 50)}";
    if (number >= 40) return "XL${_toRoman(number - 40)}";
    if (number >= 10) return "X${_toRoman(number - 10)}";
    if (number >= 9) return "IX${_toRoman(number - 9)}";
    if (number >= 5) return "V${_toRoman(number - 5)}";
    if (number >= 4) return "IV${_toRoman(number - 4)}";
    if (number >= 1) return "I${_toRoman(number - 1)}";
    return "";
  }
}
