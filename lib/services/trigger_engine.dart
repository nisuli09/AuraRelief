class TriggerEngine {
  static Map<String, int> detectTriggers(Map<String, dynamic> data) {
    Map<String, int> detected = {};

    bool isMigraine = data['isMigraine'] ?? false;
    if (!isMigraine) return detected;

    double sleep = (data['sleepHours'] ?? 0).toDouble();
    int stress = data['stressLevel'] ?? 0;

    if (sleep < 6) {
      detected['Lack of Sleep'] =
          (detected['Lack of Sleep'] ?? 0) + 1;
    }

    if (sleep > 9) {
      detected['Oversleeping'] =
          (detected['Oversleeping'] ?? 0) + 1;
    }

    if (stress >= 7) {
      detected['High Stress'] =
          (detected['High Stress'] ?? 0) + 1;
    }

    return detected;
  }
}