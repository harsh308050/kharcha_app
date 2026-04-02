import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsInboxService {
  final SmsQuery _query = SmsQuery();

  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<SmsMessage>> fetchInboxMessages() async {
    return _query.querySms(
      kinds: <SmsQueryKind>[SmsQueryKind.inbox],
      sort: true,
    );
  }
}
