import 'package:dart_backend_tech_test/core/config/app_config.dart';
import 'package:dart_backend_tech_test/src/feature_flags/domain/entities/api_tier.dart';
import 'package:test/test.dart';

void main() {
  group('AppConfig.fromEnvironment', () {
    test('throws when API_KEYS is missing', () {
      expect(
        () => AppConfig.fromEnvironment(<String, String>{}),
        throwsArgumentError,
      );
    });

    test('throws when API_KEYS count is not 4', () {
      expect(
        () => AppConfig.fromEnvironment(<String, String>{'API_KEYS': 'a:b:c'}),
        throwsArgumentError,
      );
    });

    test('throws when API_KEYS contains duplicates', () {
      expect(
        () => AppConfig.fromEnvironment(<String, String>{
          'API_KEYS': 'a:a:c:d',
        }),
        throwsArgumentError,
      );
    });

    test('maps keys to tiers by fixed order', () {
      final config = AppConfig.fromEnvironment(<String, String>{
        'API_KEYS': 'sandboxKey:standardKey:enhancedKey:enterpriseKey',
      });

      expect(config.tierForApiKey('sandboxKey'), ApiTier.sandbox);
      expect(config.tierForApiKey('standardKey'), ApiTier.standard);
      expect(config.tierForApiKey('enhancedKey'), ApiTier.enhanced);
      expect(config.tierForApiKey('enterpriseKey'), ApiTier.enterprise);
      expect(config.tierForApiKey('unknown'), isNull);
    });
  });
}
