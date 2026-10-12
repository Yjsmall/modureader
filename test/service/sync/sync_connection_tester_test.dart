import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/sync/sync_connection_tester.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final full in [false, true]) {
    test('${full ? 'full' : 'ping'} test handles missing UI context', () async {
      expect(navigatorKey.currentContext, isNull);
      final check = full
          ? SyncConnectionTester.testFullConnection
          : SyncConnectionTester.testConnection;
      final result = await check(protocol: SyncProtocol.webdav, config: {});
      expect(result.isSuccess, false);
      expect(result.message, isNotEmpty);
      // An incomplete endpoint must fail validation before accessing the network.
      expect(result.message, isNot(contains('同步失败：')));
    });
  }
}
