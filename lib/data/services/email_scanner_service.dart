import 'dart:convert';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'auth_service.dart';

/// Service for scanning emails to detect subscriptions
class EmailScannerService {
  static final EmailScannerService _instance = EmailScannerService._internal();
  factory EmailScannerService() => _instance;
  EmailScannerService._internal();

  final AuthService _authService = AuthService();

  /// Common subscription-related keywords for email filtering
  static const List<String> _subscriptionKeywords = [
    'subscription',
    'billing',
    'invoice',
    'payment',
    'receipt',
    'charged',
    'renewal',
    'auto-renewal',
    'monthly charge',
    'annual charge',
    'subscription fee',
    'membership fee',
  ];

  /// Known subscription service domains
  static const List<String> _subscriptionDomains = [
    'netflix.com',
    'spotify.com',
    'apple.com',
    'google.com',
    'amazon.com',
    'microsoft.com',
    'adobe.com',
    'dropbox.com',
    'zoom.us',
    'slack.com',
    'notion.so',
    'figma.com',
    'canva.com',
    'youtube.com',
    'hulu.com',
    'disney.com',
    'paramount.com',
    'hbo.com',
    'twitch.tv',
    'github.com',
    'gitlab.com',
    'atlassian.com',
    'salesforce.com',
    'mailchimp.com',
    'surveymonkey.com',
    'grammarly.com',
    'dashlane.com',
    '1password.com',
    'lastpass.com',
    'nordvpn.com',
    'expressvpn.com',
  ];

  /// Scan recent emails for subscription information
  Future<List<DetectedSubscription>> scanForSubscriptions({
    int maxResults = 100,
    int daysBack = 90,
  }) async {
    final gmailApi = _authService.gmailApi;
    if (gmailApi == null) {
      throw Exception('Gmail API not initialized. Please sign in first.');
    }

    try {
      // Calculate date filter for recent emails
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
      final dateFilter = 'after:${cutoffDate.year}/${cutoffDate.month}/${cutoffDate.day}';
      
      // Build search query for subscription-related emails
      final searchQuery = _buildSearchQuery(dateFilter);
      
      // Search for emails
      final searchResponse = await gmailApi.users.messages.list(
        'me',
        q: searchQuery,
        maxResults: maxResults,
      );

      if (searchResponse.messages == null || searchResponse.messages!.isEmpty) {
        return [];
      }

      // Process each message to extract subscription info
      final detectedSubscriptions = <DetectedSubscription>[];
      
      for (final message in searchResponse.messages!) {
        try {
          final fullMessage = await gmailApi.users.messages.get(
            'me',
            message.id!,
            format: 'full',
          );
          
          final subscription = await _parseEmailForSubscription(fullMessage);
          if (subscription != null) {
            detectedSubscriptions.add(subscription);
          }
        } catch (e) {
          print('Error processing message ${message.id}: $e');
          continue;
        }
      }

      return _deduplicateSubscriptions(detectedSubscriptions);
    } catch (error) {
      print('Error scanning emails: $error');
      rethrow;
    }
  }

  /// Build Gmail search query for subscription-related emails
  String _buildSearchQuery(String dateFilter) {
    final keywordQuery = _subscriptionKeywords
        .map((keyword) => '"$keyword"')
        .join(' OR ');
    
    final domainQuery = _subscriptionDomains
        .map((domain) => 'from:$domain')
        .join(' OR ');
    
    return '$dateFilter AND (($keywordQuery) OR ($domainQuery))';
  }

  /// Parse an email message to extract subscription information
  Future<DetectedSubscription?> _parseEmailForSubscription(
    gmail.Message message,
  ) async {
    try {
      final headers = message.payload?.headers ?? [];
      final subject = _getHeaderValue(headers, 'Subject') ?? '';
      final from = _getHeaderValue(headers, 'From') ?? '';
      final date = _getHeaderValue(headers, 'Date') ?? '';
      
      // Get email body
      final body = _extractEmailBody(message.payload);
      
      // Extract subscription details
      final serviceName = _extractServiceName(from, subject, body);
      final amount = _extractAmount(subject, body);
      final currency = _extractCurrency(subject, body);
      final billingCycle = _extractBillingCycle(subject, body);
      
      if (serviceName != null && amount != null) {
        return DetectedSubscription(
          serviceName: serviceName,
          amount: amount,
          currency: currency ?? 'USD',
          billingCycle: billingCycle ?? BillingCycle.monthly,
          detectedFrom: from,
          emailSubject: subject,
          emailDate: _parseEmailDate(date),
        );
      }
      
      return null;
    } catch (error) {
      print('Error parsing email: $error');
      return null;
    }
  }

  /// Extract header value from email headers
  String? _getHeaderValue(List<gmail.MessagePartHeader> headers, String name) {
    for (final header in headers) {
      if (header.name?.toLowerCase() == name.toLowerCase()) {
        return header.value;
      }
    }
    return null;
  }

  /// Extract email body content
  String _extractEmailBody(gmail.MessagePart? payload) {
    if (payload == null) return '';
    
    // Try to get text/plain or text/html body
    if (payload.mimeType == 'text/plain' || payload.mimeType == 'text/html') {
      final data = payload.body?.data;
      if (data != null) {
        final decoded = utf8.decode(base64Url.decode(data));
        return decoded;
      }
    }
    
    // Check parts for multipart messages
    if (payload.parts != null) {
      for (final part in payload.parts!) {
        final partBody = _extractEmailBody(part);
        if (partBody.isNotEmpty) {
          return partBody;
        }
      }
    }
    
    return '';
  }

  /// Extract service name from email sender and content
  String? _extractServiceName(String from, String subject, String body) {
    // Try to extract from known domains
    for (final domain in _subscriptionDomains) {
      if (from.toLowerCase().contains(domain)) {
        return _formatServiceName(domain);
      }
    }
    
    // Try to extract from subject or body using patterns
    final text = '$subject $body'.toLowerCase();
    
    // Common patterns for service names
    final patterns = [
      RegExp(r'(netflix|spotify|apple|google|amazon|microsoft|adobe|dropbox)'),
      RegExp(r'your ([a-z\s]+) subscription'),
      RegExp(r'thank you for your ([a-z\s]+) payment'),
      RegExp(r'([a-z\s]+) billing statement'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _formatServiceName(match.group(1) ?? '');
      }
    }
    
    return null;
  }

  /// Extract amount from email content
  double? _extractAmount(String subject, String body) {
    final text = '$subject $body';
    
    // Pattern to match currency amounts
    final patterns = [
      RegExp(r'\$(\d+\.?\d*)'),
      RegExp(r'(\d+\.?\d*)\s*(USD|usd|\$)'),
      RegExp(r'amount:\s*\$?(\d+\.?\d*)'),
      RegExp(r'total:\s*\$?(\d+\.?\d*)'),
      RegExp(r'charged:\s*\$?(\d+\.?\d*)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          return double.tryParse(amountStr);
        }
      }
    }
    
    return null;
  }

  /// Extract currency from email content
  String? _extractCurrency(String subject, String body) {
    final text = '$subject $body'.toUpperCase();
    
    if (text.contains('USD') || text.contains('\$')) return 'USD';
    if (text.contains('EUR') || text.contains('€')) return 'EUR';
    if (text.contains('GBP') || text.contains('£')) return 'GBP';
    if (text.contains('CAD')) return 'CAD';
    if (text.contains('AUD')) return 'AUD';
    
    return null;
  }

  /// Extract billing cycle from email content
  BillingCycle? _extractBillingCycle(String subject, String body) {
    final text = '$subject $body'.toLowerCase();
    
    if (text.contains('annual') || text.contains('yearly') || text.contains('year')) {
      return BillingCycle.yearly;
    }
    if (text.contains('monthly') || text.contains('month')) {
      return BillingCycle.monthly;
    }
    if (text.contains('weekly') || text.contains('week')) {
      return BillingCycle.weekly;
    }
    
    return null;
  }

  /// Parse email date string
  DateTime? _parseEmailDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Format service name for display
  String _formatServiceName(String name) {
    return name
        .replaceAll('.com', '')
        .replaceAll('.', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ')
        .trim();
  }

  /// Remove duplicate subscriptions based on service name and amount
  List<DetectedSubscription> _deduplicateSubscriptions(
    List<DetectedSubscription> subscriptions,
  ) {
    final uniqueSubscriptions = <String, DetectedSubscription>{};
    
    for (final subscription in subscriptions) {
      final key = '${subscription.serviceName}_${subscription.amount}';
      if (!uniqueSubscriptions.containsKey(key)) {
        uniqueSubscriptions[key] = subscription;
      }
    }
    
    return uniqueSubscriptions.values.toList();
  }
}

/// Detected subscription information from email
class DetectedSubscription {
  final String serviceName;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final String detectedFrom;
  final String emailSubject;
  final DateTime? emailDate;

  const DetectedSubscription({
    required this.serviceName,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.detectedFrom,
    required this.emailSubject,
    this.emailDate,
  });

  @override
  String toString() {
    return 'DetectedSubscription(serviceName: $serviceName, amount: $amount $currency, cycle: $billingCycle)';
  }
}

/// Billing cycle options
enum BillingCycle {
  weekly,
  monthly,
  yearly,
} 