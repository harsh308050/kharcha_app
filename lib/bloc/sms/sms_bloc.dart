import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:kharcha/bloc/sms/sms_event.dart';
import 'package:kharcha/bloc/sms/sms_state.dart';
import 'package:kharcha/utils/sms/bank_sender_mapper.dart';
import 'package:kharcha/utils/sms/sms_inbox_service.dart';
import 'package:kharcha/utils/sms/sms_parser.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';

class SmsBloc extends Bloc<SmsEvent, SmsState> {
  final SmsInboxService _service;

  SmsBloc({SmsInboxService? service})
      : _service = service ?? SmsInboxService(),
        super(const SmsInitial()) {
    on<SmsFetchRequested>(_onFetchRequested);
  }

  Future<void> _onFetchRequested(
    SmsFetchRequested event,
    Emitter<SmsState> emit,
  ) async {
    emit(const SmsLoading(totalMessages: 0, processedMessages: 0, matchedMessages: 0));

    try {
      final bool granted = await _service.requestPermission();
      if (!granted) {
        emit(const SmsPermissionDenied());
        return;
      }

      final List<SmsMessage> inbox = await _service.fetchInboxMessages();
      final List<SmsMessage> messages = inbox
          .where(
            (SmsMessage message) =>
                (message.body ?? '').trim().isNotEmpty,
          )
          .toList();

      final int totalMessages = messages.length;
      final int step = totalMessages <= 0 ? 1 : (totalMessages / 200).ceil();
      int processed = 0;
      int matched = 0;
      final List<SmsTransaction> parsed = <SmsTransaction>[];
      final Stopwatch throttle = Stopwatch()..start();

      emit(SmsLoading(
        totalMessages: totalMessages,
        processedMessages: 0,
        matchedMessages: 0,
      ));

      for (final SmsMessage message in messages) {
        final String body = (message.body ?? '').trim();
        final SmsTransaction? parsedItem = SmsParser.parseMessage(body);
        processed += 1;
        if (parsedItem != null) {
          parsed.add(
            parsedItem.copyWith(
              senderId: _resolveSenderId(message),
              smsDate: message.date ?? message.dateSent,
            ),
          );
          matched += 1;
        }

        if (processed % step == 0 || processed == totalMessages) {
          emit(SmsLoading(
            totalMessages: totalMessages,
            processedMessages: processed,
            matchedMessages: matched,
          ));
          if (throttle.elapsedMilliseconds >= 12 || processed == totalMessages) {
            await Future<void>.delayed(const Duration(milliseconds: 8));
            throttle.reset();
          }
        }
      }

      for (final SmsTransaction item in parsed) {
        debugPrint(jsonEncode(item.toLedgerJson()));
      }

      emit(SmsLoaded(parsed));
    } catch (e, stackTrace) {
      debugPrint('Sms fetch failed: $e');
      debugPrint(stackTrace.toString());
      emit(SmsFailure(e.toString()));
    }
  }

  String _resolveSenderId(SmsMessage message) {
    final String rawSender = (message.sender ?? message.address ?? '').trim();
    if (rawSender.isEmpty) {
      return '';
    }

    return BankSenderMapper.normalizeSenderId(rawSender);
  }

}
