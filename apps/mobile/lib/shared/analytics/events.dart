/// Application-owned schema, mirrored by apps/frontend/src/analytics/events.ts.
/// Values are categorical: never pass wallet DTOs or free-form errors.
class AnalyticsEvent {
  const AnalyticsEvent(this.name, this.properties);
  factory AnalyticsEvent.screen(String name) =>
      AnalyticsEvent('screen_viewed', {'screen_name': name});
  factory AnalyticsEvent.send(String name, String chain, {String? errorCode}) =>
      AnalyticsEvent(name, {
        'chain': chain,
        if (errorCode != null) 'error_code': errorCode,
      });
  final String name;
  final Map<String, Object> properties;
}

AnalyticsEvent? sanitizeEvent(String name, Map<String, Object> properties) {
  if ({
    'pix_request_started',
    'pix_request_created',
    'pix_request_failed',
    'pix_code_copied',
  }.contains(name)) {
    return AnalyticsEvent(name, const {});
  }
  if (name == 'pix_deposit_status_changed') {
    final status = properties['status'];
    return {
          'pending',
          'processing',
          'completed',
          'failed',
          'expired',
          'refunded',
        }.contains(status)
        ? AnalyticsEvent(name, {'status': status!})
        : null;
  }
  if ({
    'swap_review_opened',
    'swap_started',
    'swap_submission_succeeded',
    'swap_failed',
  }.contains(name)) {
    final type = properties['swap_type'];
    return {'liquid', 'peg_in', 'peg_out'}.contains(type)
        ? AnalyticsEvent(name, {'swap_type': type!})
        : null;
  }
  const screens = {
    'wallet',
    'assets',
    'asset',
    'activity',
    'send',
    'send_review',
    'receive',
    'swap',
    'pix',
    'settings',
    'account',
    'onboarding',
  };
  if (name == 'screen_viewed' && screens.contains(properties['screen_name'])) {
    return AnalyticsEvent(name, {'screen_name': properties['screen_name']!});
  }
  if (name == 'onboarding_completed' &&
      {'create', 'import'}.contains(properties['method'])) {
    return AnalyticsEvent(name, {'method': properties['method']!});
  }
  final chain = properties['chain'];
  if (chain != 'bitcoin' && chain != 'liquid') return null;
  if (name == 'send_started' || name == 'send_submission_succeeded') {
    return AnalyticsEvent(name, {'chain': chain!});
  }
  if (name == 'send_failed' &&
      {'rejected', 'unknown'}.contains(properties['error_code'])) {
    return AnalyticsEvent(name, {
      'chain': chain!,
      'error_code': properties['error_code']!,
    });
  }
  return null;
}

String? screenForPath(String location) {
  final path = location.split(RegExp('[?#]')).first;
  return const {
    '/home': 'wallet',
    '/asset': 'assets',
    '/asset-activity': 'asset',
    '/transactions-history': 'activity',
    '/send-asset': 'send',
    '/send-funds/review-onchain': 'send_review',
    '/send-funds/review-simple': 'send_review',
    '/receive-asset': 'receive',
    '/receive-qr': 'receive',
    '/swap': 'swap',
    '/pix': 'pix',
    '/settings': 'settings',
    '/menu': 'settings',
    '/wallet-levels': 'account',
    '/setup/first-access': 'onboarding',
    '/setup/onboarding': 'onboarding',
  }[path];
}
