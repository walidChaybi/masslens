import 'dart:convert';
import 'dart:math';

enum RewardAttemptEvent {
  started('started'),
  clientEarned('client_earned');

  const RewardAttemptEvent(this.wireName);

  final String wireName;
}

enum RewardAttemptServerState { pending, verified, rejected, expired }

class RewardAttemptStatus {
  const RewardAttemptStatus({
    required this.attemptId,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.clientEarnedAt,
    this.rejectionCode,
  });

  factory RewardAttemptStatus.fromJson(Map<String, Object?> json) {
    DateTime timestamp(String key) {
      final value = json[key];
      if (value is! num) throw FormatException('Missing reward $key.');
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    final attemptId = json['attemptId'];
    final stateName = json['state'];
    if (attemptId is! String || !RewardAttemptId.isValid(attemptId)) {
      throw const FormatException('Invalid reward attempt ID.');
    }
    if (stateName is! String) {
      throw const FormatException('Missing reward attempt state.');
    }
    final state = RewardAttemptServerState.values.firstWhere(
      (value) => value.name == stateName,
      orElse: () =>
          throw FormatException('Unknown reward attempt state: $stateName'),
    );
    final clientEarnedAtMs = json['clientEarnedAtMs'];
    return RewardAttemptStatus(
      attemptId: attemptId,
      state: state,
      createdAt: timestamp('createdAtMs'),
      updatedAt: timestamp('updatedAtMs'),
      expiresAt: timestamp('expiresAtMs'),
      clientEarnedAt: clientEarnedAtMs is num
          ? DateTime.fromMillisecondsSinceEpoch(clientEarnedAtMs.toInt())
          : null,
      rejectionCode: json['rejectionCode'] as String?,
    );
  }

  final String attemptId;
  final RewardAttemptServerState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final DateTime? clientEarnedAt;
  final String? rejectionCode;

  bool get isTerminal => state != RewardAttemptServerState.pending;
}

class PendingRewardAttempt {
  const PendingRewardAttempt({
    required this.attemptId,
    required this.createdAt,
    this.clientEarned = false,
  });

  factory PendingRewardAttempt.fromJson(Map<String, Object?> json) {
    final attemptId = json['attemptId'];
    final createdAtMs = json['createdAtMs'];
    if (attemptId is! String ||
        !RewardAttemptId.isValid(attemptId) ||
        createdAtMs is! num) {
      throw const FormatException('Invalid pending reward attempt.');
    }
    return PendingRewardAttempt(
      attemptId: attemptId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs.toInt()),
      clientEarned: json['clientEarned'] as bool? ?? false,
    );
  }

  final String attemptId;
  final DateTime createdAt;
  final bool clientEarned;

  PendingRewardAttempt copyWith({bool? clientEarned}) => PendingRewardAttempt(
    attemptId: attemptId,
    createdAt: createdAt,
    clientEarned: clientEarned ?? this.clientEarned,
  );

  Map<String, Object> toJson() => {
    'attemptId': attemptId,
    'createdAtMs': createdAt.millisecondsSinceEpoch,
    'clientEarned': clientEarned,
  };
}

abstract final class RewardAttemptId {
  static final _pattern = RegExp(r'^[A-Za-z0-9_-]{20,80}$');

  static String create() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static bool isValid(String value) => _pattern.hasMatch(value);
}
