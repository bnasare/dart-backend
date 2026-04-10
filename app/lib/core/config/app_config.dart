import 'package:dart_backend_tech_test/src/feature_flags/domain/entities/api_tier.dart';

class AppConfig {
  const AppConfig({
    required this.port,
    required this.apiKeys,
    required this.rateLimitMax,
    required this.rateLimitWindowSec,
    required this.databasePath,
  });

  factory AppConfig.fromEnvironment(Map<String, String> environment) {
    final rawApiKeys = environment['API_KEYS']?.trim() ?? '';
    if (rawApiKeys.isEmpty) {
      throw ArgumentError(
        'API_KEYS must be configured before starting the server.',
      );
    }
    final parsedApiKeys = rawApiKeys
        .split(':')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    if (parsedApiKeys.length != ApiTier.values.length) {
      throw ArgumentError(
        'API_KEYS must include exactly ${ApiTier.values.length} keys in order: sandbox:standard:enhanced:enterprise.',
      );
    }
    if (parsedApiKeys.toSet().length != parsedApiKeys.length) {
      throw ArgumentError('API_KEYS entries must be unique.');
    }

    final parsedPort = int.tryParse(environment['PORT'] ?? '8080') ?? 8080;
    final parsedRateLimitMax =
        int.tryParse(environment['RATE_LIMIT_MAX'] ?? '60') ?? 60;
    final parsedRateLimitWindowSec =
        int.tryParse(environment['RATE_LIMIT_WINDOW_SEC'] ?? '60') ?? 60;

    return AppConfig(
      port: parsedPort,
      apiKeys: parsedApiKeys,
      rateLimitMax: parsedRateLimitMax,
      rateLimitWindowSec: parsedRateLimitWindowSec,
      databasePath: environment['DATABASE_PATH']?.trim().isNotEmpty == true
          ? environment['DATABASE_PATH']!.trim()
          : 'data/notes.sqlite',
    );
  }

  final int port;
  final List<String> apiKeys;
  final int rateLimitMax;
  final int rateLimitWindowSec;
  final String databasePath;

  bool isProtectedPath(String path) {
    return path.startsWith('v1/');
  }

  ApiTier? tierForApiKey(String apiKey) {
    final index = apiKeys.indexOf(apiKey);
    if (index < 0 || index >= ApiTier.values.length) {
      return null;
    }

    return ApiTier.values[index];
  }
}
