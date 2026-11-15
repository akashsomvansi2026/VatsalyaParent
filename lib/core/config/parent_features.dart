import 'package:flutter/material.dart';

class ParentFeature {
  const ParentFeature(
    this.key,
    this.title,
    this.icon, {
    this.fields = const ['notes'],
    this.notice,
  });
  final String key, title;
  final IconData icon;
  final List<String> fields;
  final String? notice;
  static const all = [
    ParentFeature(
      'control',
      'Control records',
      Icons.tune,
      fields: ['notes'],
      notice:
          'These records do not send device commands. Use the child supervision screen for tracking, protection and PIN controls.',
    ),
    ParentFeature(
      'screen_time',
      'Screen-time plans',
      Icons.hourglass_bottom,
      fields: ['dailyMinutes', 'startTime', 'endTime', 'notes'],
      notice:
          'Plans are saved records. Apply enforced daily limits from the child Apps screen.',
    ),
    ParentFeature('app.approval', 'App approvals', Icons.fact_check_outlined),
    ParentFeature(
      'web_filter',
      'Web filters',
      Icons.filter_alt_outlined,
      fields: ['category', 'notes'],
      notice:
          'Filters are saved records; Android web-filter enforcement requires a compatible Child integration.',
    ),
    ParentFeature(
      'website',
      'Website rules',
      Icons.language,
      fields: ['url', 'notes'],
      notice:
          'Allow/block decisions are recorded. Device browser enforcement requires a compatible Child integration.',
    ),
    ParentFeature(
      'geofence',
      'Geofences',
      Icons.radar,
      fields: ['latitude', 'longitude', 'radiusMetres', 'notes'],
      notice:
          'A fresh Child location report can trigger an entry or exit alert after two recent GPS fixes. Alerts may be delayed when the phone is offline or location accuracy is low.',
    ),
    ParentFeature('alert', 'Alerts', Icons.warning_amber),
    ParentFeature('activity', 'Activity', Icons.timeline),
    ParentFeature('activity.history', 'Activity history', Icons.history),
    ParentFeature('report', 'Reports & export', Icons.summarize_outlined),
    ParentFeature(
      'notification',
      'Notifications',
      Icons.notifications_outlined,
      fields: ['body', 'notes'],
      notice:
          'Delivery depends on registered devices and the server push provider. The record shows its queue status.',
    ),
    ParentFeature(
      'subscription',
      'Subscriptions',
      Icons.event_repeat,
      fields: ['plan', 'notes'],
      notice: 'Subscription records do not activate external billing.',
    ),
    ParentFeature(
      'payment',
      'Payment requests',
      Icons.payments_outlined,
      fields: ['amount', 'currency', 'notes'],
      notice:
          'This creates a payment request. It does not charge a card or complete a payment.',
    ),
    ParentFeature('invoice', 'Invoices', Icons.receipt_long),
    ParentFeature(
      'support',
      'Support requests',
      Icons.support_agent,
      fields: ['subject', 'notes'],
    ),
  ];
  bool can(Set<String> permissions, String action) {
    var keyAction = action;
    if (key == 'app.approval' && action == 'view') keyAction = 'manage';
    if (key == 'website' && action == 'view') {
      return permissions.contains('parent.website.allow') ||
          permissions.contains('parent.website.block');
    }
    if (['subscription', 'notification'].contains(key) &&
        ['create', 'update', 'delete'].contains(action)) {
      keyAction = 'manage';
    }
    return permissions.contains('parent.$key.$keyAction');
  }
}
