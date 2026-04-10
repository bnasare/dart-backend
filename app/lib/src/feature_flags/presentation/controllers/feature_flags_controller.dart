import 'package:dart_backend_tech_test/shared/error/app_exception.dart';
import 'package:dart_backend_tech_test/shared/http/json_response.dart';
import 'package:dart_backend_tech_test/shared/http/request_context.dart';
import 'package:dart_backend_tech_test/src/feature_flags/domain/entities/api_tier.dart';
import 'package:shelf/shelf.dart';

class FeatureFlagsController {
  const FeatureFlagsController();

  Future<Response> handleGet(Request request) async {
    final tier = request.context[RequestContext.tier] as ApiTier?;
    if (tier == null) {
      throw const UnauthorizedException('Missing API key tier context.');
    }

    return jsonResponse(200, _payloadForTier(tier));
  }

  Map<String, Object?> _payloadForTier(ApiTier tier) {
    return <String, Object?>{
      'tier': tier.label,
      'features': switch (tier) {
        ApiTier.sandbox => <String, Object?>{
            'notesCrud': true,
            'oauth': false,
            'advancedReports': false,
          },
        ApiTier.standard => <String, Object?>{
            'notesCrud': true,
            'oauth': true,
            'advancedReports': false,
          },
        ApiTier.enhanced => <String, Object?>{
            'notesCrud': true,
            'oauth': true,
            'advancedReports': true,
          },
        ApiTier.enterprise => <String, Object?>{
            'notesCrud': true,
            'oauth': true,
            'advancedReports': true,
            'ssoSaml': true,
          },
      },
    };
  }
}
