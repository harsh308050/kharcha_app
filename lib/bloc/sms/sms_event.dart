import 'package:equatable/equatable.dart';

abstract class SmsEvent extends Equatable {
  const SmsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class SmsFetchRequested extends SmsEvent {
  const SmsFetchRequested();
}
