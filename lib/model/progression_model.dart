class RewardTransaction {
  final DateTime timestamp;
  final String reason;
  final int amount;
  final bool isCredit;

  RewardTransaction({
    required this.timestamp,
    required this.reason,
    required this.amount,
    required this.isCredit,
  });

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      timestamp: DateTime.parse(json['timestamp']),
      reason: json['reason'] ?? '',
      amount: json['amount'] ?? 0,
      isCredit: json['isCredit'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
      'amount': amount,
      'isCredit': isCredit,
    };
  }
}

class ProgressionModel {
  int diamondsBalance;
  int lifetimeDiamondsEarned;
  int currentStreak;
  int longestStreak;
  DateTime lastActiveDate;
  DateTime lastCheckInDate;
  List<String> redeemedCollections;
  List<String> completedMilestones;
  List<RewardTransaction> transactionHistory;
  
  // Daily Tracking
  int dailyAdViews;
  int dailyDownloads;
  int dailyApplies;
  int dailyShares; // Track daily app shares
  DateTime lastAdViewDate;

  ProgressionModel({
    this.diamondsBalance = 0,
    this.lifetimeDiamondsEarned = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.lastActiveDate,
    required this.lastCheckInDate,
    List<String>? redeemedCollections,
    List<String>? completedMilestones,
    List<RewardTransaction>? transactionHistory,
    this.dailyAdViews = 0,
    this.dailyDownloads = 0,
    this.dailyApplies = 0,
    this.dailyShares = 0,
    required this.lastAdViewDate,
  })  : redeemedCollections = redeemedCollections ?? [],
        completedMilestones = completedMilestones ?? [],
        transactionHistory = transactionHistory ?? [];

  factory ProgressionModel.fromJson(Map<String, dynamic> json) {
    return ProgressionModel(
      diamondsBalance: json['diamondsBalance'] ?? 0,
      lifetimeDiamondsEarned: json['lifetimeDiamondsEarned'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastActiveDate: json['lastActiveDate'] != null 
          ? DateTime.parse(json['lastActiveDate'])
          : DateTime.now().subtract(const Duration(days: 1)),
      lastCheckInDate: json['lastCheckInDate'] != null 
          ? DateTime.parse(json['lastCheckInDate'])
          : DateTime.now().subtract(const Duration(days: 1)),
      redeemedCollections: List<String>.from(json['redeemedCollections'] ?? []),
      completedMilestones: List<String>.from(json['completedMilestones'] ?? []),
      transactionHistory: (json['transactionHistory'] as List?)
              ?.map((e) => RewardTransaction.fromJson(e))
              .toList() ?? [],
      dailyAdViews: json['dailyAdViews'] ?? 0,
      dailyDownloads: json['dailyDownloads'] ?? 0,
      dailyApplies: json['dailyApplies'] ?? 0,
      dailyShares: json['dailyShares'] ?? 0,
      lastAdViewDate: json['lastAdViewDate'] != null 
          ? DateTime.parse(json['lastAdViewDate'])
          : DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diamondsBalance': diamondsBalance,
      'lifetimeDiamondsEarned': lifetimeDiamondsEarned,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'lastCheckInDate': lastCheckInDate.toIso8601String(),
      'redeemedCollections': redeemedCollections,
      'completedMilestones': completedMilestones,
      'transactionHistory': transactionHistory.map((e) => e.toJson()).toList(),
      'dailyAdViews': dailyAdViews,
      'dailyDownloads': dailyDownloads,
      'dailyApplies': dailyApplies,
      'dailyShares': dailyShares,
      'lastAdViewDate': lastAdViewDate.toIso8601String(),
    };
  }
}
