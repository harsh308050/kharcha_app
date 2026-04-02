import 'package:equatable/equatable.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';

abstract class SmsState extends Equatable {
  const SmsState();

  @override
  List<Object?> get props => <Object?>[];
}

class SmsInitial extends SmsState {
  const SmsInitial();
}

class SmsLoading extends SmsState {
  final int totalMessages;
  final int processedMessages;
  final int matchedMessages;

  const SmsLoading({
    required this.totalMessages,
    required this.processedMessages,
    required this.matchedMessages,
  });

  @override
  List<Object?> get props => <Object?>[
        totalMessages,
        processedMessages,
        matchedMessages,
      ];
}

class SmsPermissionDenied extends SmsState {
  const SmsPermissionDenied();
}

class SmsLoaded extends SmsState {
  final List<SmsTransaction> transactions;

  const SmsLoaded(this.transactions);

  @override
  List<Object?> get props => <Object?>[transactions];
}

class SmsFailure extends SmsState {
  final String message;

  const SmsFailure(this.message);

  @override
  List<Object?> get props => <Object?>[message];
}
