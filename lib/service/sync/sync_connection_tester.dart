import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/enums/sync_protocol.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/sync/sync_client_factory.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/service/sync/sync_feedback.dart';
import 'package:flutter/widgets.dart';

/// Utility class for testing sync connections
class SyncConnectionTester {
  /// Test reachability without creating remote files.
  static Future<SyncTestResult> testConnection({
    required SyncProtocol protocol,
    required Map<String, dynamic> config,
  }) =>
      _test(protocol, config, (client) => client.ping(), 'connection');

  /// Test create, upload, download and delete capabilities.
  static Future<SyncTestResult> testFullConnection({
    required SyncProtocol protocol,
    required Map<String, dynamic> config,
  }) =>
      _test(protocol, config, (client) => client.testFullCapabilities(),
          'full connection');

  static Future<SyncTestResult> _test(
    SyncProtocol protocol,
    Map<String, dynamic> config,
    Future<void> Function(SyncClientBase) check,
    String operation,
  ) async {
    // Resolve messages before awaiting network work; the initiating route may
    // have disappeared by the time the request completes.
    final context = navigatorKey.currentContext;
    final l10n = context == null
        ? await lookupL10n(const Locale('zh'))
        : L10n.of(context);
    try {
      final client = SyncClientFactory.createClient(protocol, config);
      if (!client.isConfigured) {
        return SyncTestResult.failure(
            l10n.configurationInformationIsIncomplete);
      }
      await check(client);
      AnxLog.info('${protocol.displayName} $operation test successful');
      return SyncTestResult.success(l10n.connectionSuccessful);
    } catch (error) {
      final message =
          syncFailureMessage(error, chinese: l10n.localeName.startsWith('zh'));
      AnxLog.severe('${protocol.displayName} $operation test failed: $message');
      return SyncTestResult.failure(message);
    }
  }
}

/// Test result class
class SyncTestResult {
  final bool isSuccess;
  final String message;

  const SyncTestResult._({
    required this.isSuccess,
    required this.message,
  });

  /// Create success result
  factory SyncTestResult.success(String message) {
    return SyncTestResult._(isSuccess: true, message: message);
  }

  /// Create failure result
  factory SyncTestResult.failure(String message) {
    return SyncTestResult._(isSuccess: false, message: message);
  }
}
