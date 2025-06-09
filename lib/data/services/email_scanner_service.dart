import 'dart:convert';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'auth_service.dart';
import 'logo_service.dart';

/// Service for scanning emails to detect subscriptions
class EmailScannerService {
  static final EmailScannerService _instance = EmailScannerService._internal();
  factory EmailScannerService() => _instance;
  EmailScannerService._internal();

  final AuthService _authService = AuthService();
  final LogoService _logoService = LogoService();

  /// Common subscription-related keywords for email filtering
  static const List<String> _subscriptionKeywords = [
    'subscription',
    'billing',
    'invoice',
    'recurring payment',
    'auto-renewal',
    'monthly charge',
    'annual charge',
    'subscription fee',
    'membership fee',
    'recurring charge',
    'automatic payment',
    'subscription renewal',
    'membership renewal',
    'subscription confirmation',
    'trial',
    'monthly plan',
    'annual plan',
    'yearly plan',
    'premium subscription',
    'pro subscription',
    'plus subscription',
    'membership billing',
    'subscription billing',
    'auto-pay',
    'autopay',
    'recurring billing',
    'subscription active',
    'plan continues',
    'next billing date',
    'billing cycle',
    'subscription statement',
    'membership statement',
  ];

  /// Keywords that indicate one-time purchases (NOT subscriptions)
  static const List<String> _excludeKeywords = [
    'your order',
    'order confirmation',
    'shipment',
    'shipped',
    'delivery',
    'tracking',
    'package',
    'item',
    'product',
    'purchase confirmation',
    'thank you for your order',
    'order summary',
    'one-time',
    'newsletter',
    'unsubscribe',
    'marketing',
    'promotion',
    'sale',
    'discount',
    'deal',
    'offer',
    'announcement',
    'update',
    'news',
    'tip',
    'feature',
    'blog',
    'guide',
    'tutorial',
    'event',
    'webinar',
    'survey',
    'feedback',
    'welcome email',
    'verification',
    'confirm your email',
    'security alert',
    'password',
    'login',
    'account activity',
    
    // API/Credits/One-time payments
    'api credit',
    'credit balance',
    'fund your',
    'top up',
    'add funds',
    'account credit',
    'balance funded',
    'credits purchased',
    'tokens',
    'usage',
    'api usage',
    'refund',
    'reimbursement',
    'gift card',
    'voucher',
    'one-time payment',
    'single payment',
    'deposit',
    'withdrawal',
    'transfer',
  ];

  /// Known subscription service domains
  static const List<String> _subscriptionDomains = [
    'netflix.com',
    'spotify.com',
    'apple.com',
    'google.com',
    'amazon.com',
    'amazon.co.uk',
    'amazon.ca',
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
    'disneyplus.com',
    'paramount.com',
    'hbo.com',
    'hbomax.com',
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
    'surfshark.com',
    'audible.com',
    'kindle.com',
    'primevideo.com',
    'icloud.com',
    'me.com',
    'patreon.com',
    'onlyfans.com',
    'crunchyroll.com',
    'funimation.com',
    'peacocktv.com',
    'showtime.com',
    'starz.com',
    'espn.com',
    'dazn.com',
    'mlb.com',
    'nba.com',
    'nfl.com',
    'playstation.com',
    'xbox.com',
    'nintendo.com',
    'steam.com',
    'epicgames.com',
    'ea.com',
    'ubisoft.com',
    'blizzard.com',
    'rockstargames.com',
    'origin.com',
    'gog.com',
    'humble.com',
  ];

  /// Scan recent emails for subscription information
  Future<List<DetectedSubscription>> scanForSubscriptions({
    int maxResults = 100,
    int daysBack = 90,
    void Function(double progress, String status)? onProgress,
  }) async {
    var gmailApi = _authService.gmailApi;
    if (gmailApi == null) {
      throw Exception('Gmail API not initialized. Please sign in first.');
    }

    try {
      onProgress?.call(10, 'Preparing email search...');
      
      // Calculate date filter for recent emails
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
      final dateFilter = 'after:${cutoffDate.year}/${cutoffDate.month}/${cutoffDate.day}';
      
      // Build search query for subscription-related emails
      final searchQuery = _buildSearchQuery(dateFilter);
      
      onProgress?.call(20, 'Searching emails...');
      
      // Search for emails with retry on auth failure
      gmail.ListMessagesResponse searchResponse;
      try {
        searchResponse = await gmailApi.users.messages.list(
          'me',
          q: searchQuery,
          maxResults: maxResults,
        );
      } catch (error) {
        // If we get an auth error, try refreshing authentication
        if (error.toString().contains('401') || error.toString().contains('authentication')) {
          print('🔄 Authentication error detected, attempting to refresh...');
          onProgress?.call(15, 'Refreshing authentication...');
          
          final refreshed = await _authService.refreshAuthentication();
          if (!refreshed) {
            throw Exception('Authentication failed. Please sign out and sign in again.');
          }
          
          // Retry with refreshed authentication
          gmailApi = _authService.gmailApi!;
          onProgress?.call(20, 'Retrying email search...');
          searchResponse = await gmailApi.users.messages.list(
            'me',
            q: searchQuery,
            maxResults: maxResults,
          );
        } else {
          rethrow;
        }
      }

      if (searchResponse.messages == null || searchResponse.messages!.isEmpty) {
        onProgress?.call(100, 'No emails found');
        return [];
      }

      // Process each message to extract subscription info
      final detectedSubscriptions = <DetectedSubscription>[];
      final totalMessages = searchResponse.messages!.length;
      
      print('🔍 Found $totalMessages potential emails to analyze...');
      print('📧 Search query used: $searchQuery');
      
      onProgress?.call(30, 'Found $totalMessages emails to analyze...');
      
      for (int i = 0; i < searchResponse.messages!.length; i++) {
        final message = searchResponse.messages![i];
        
        // Calculate progress: 30% start + 60% for processing emails = 90% max
        final emailProgress = 30 + ((i + 1) / totalMessages * 60);
        onProgress?.call(emailProgress, 'Analyzing email ${i + 1} of $totalMessages...');
        
        try {
          final fullMessage = await gmailApi.users.messages.get(
            'me',
            message.id!,
            format: 'full',
          );
          
          final subscription = await _parseEmailForSubscription(fullMessage);
          if (subscription != null) {
            print('✅ Found subscription: ${subscription.serviceName} - ${subscription.currency}${subscription.amount}');
            detectedSubscriptions.add(subscription);
          }
        } catch (e) {
          print('❌ Error processing message ${message.id}: $e');
          // Continue processing other messages even if one fails
          continue;
        }
      }
      
      print('🎯 Total subscriptions detected: ${detectedSubscriptions.length}');

      onProgress?.call(95, 'Removing duplicates...');
      final finalSubscriptions = _deduplicateSubscriptions(detectedSubscriptions);
      
      onProgress?.call(100, 'Found ${finalSubscriptions.length} subscription(s)!');
      
      return finalSubscriptions;
    } catch (error) {
      print('Error scanning emails: $error');
      rethrow;
    }
  }

  /// Build Gmail search query for subscription-related emails
  String _buildSearchQuery(String dateFilter) {
    // Much broader search - let parsing logic do the filtering
    final broadTerms = [
      'subscription',
      'billing',
      'recurring', 
      'membership',
      'renewal',
      'charged',
      'payment',
      'invoice',
      'receipt',
      'confirmation',
      'monthly',
      'annual',
      'yearly'
    ];
    
    final broadQuery = broadTerms.join(' OR ');
    
    // Known subscription services (cast a wide net)
    final services = [
      'netflix', 'spotify', 'amazon', 'apple', 'google', 'microsoft',
      'adobe', 'youtube', 'hulu', 'disney', 'paramount', 'hbo',
      'twitch', 'github', 'dropbox', 'zoom', 'slack', 'notion',
      'figma', 'canva', 'grammarly', 'lastpass', 'nordvpn'
    ];
    
    final serviceQuery = services
        .map((service) => 'from:$service')
        .join(' OR ');
    
    // Exclude obvious non-subscriptions but be less restrictive
    return '$dateFilter AND (($broadQuery) OR ($serviceQuery)) -(shipment OR tracking OR "order delivered" OR "item shipped")';
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
      
      print('🔍 Analyzing: "$subject" from: $from');
      
      // Get email body
      final body = _extractEmailBody(message.payload);
      final fullText = '$subject $body'.toLowerCase();
      
      // CHECK: Exclude non-subscription emails with detailed logging
      final excludeKeywords = [
        // Shipping/orders
        'shipment', 'shipped', 'delivery', 'tracking', 'package',
        'order confirmation', 'thank you for your order', 'order summary',
        
        // Failed/declined payments - specific patterns
        'payment was unsuccessful', 'payment to cursor was unsuccessful',
        'unable to charge', 'card declined', 'insufficient funds', 
        'transaction failed', 'could not be processed', 'was declined',
        'failed to charge', 'debit failed', 'payment could not',
        
        // Specific one-time payments
        'upwork connect', 'freelancer payment', 'project payment',
        
        // Technical/github
        'pull request', 'merge', 'commit', 'pr #', 'issue #',
        'repository', 'repo', 'branch',
        
        // Account credits (specific)
        'credit to your account', 'account credited', 'balance added',
        'wallet credit', 'bonus credit', 'referral credit',
        'account has been funded',
        
        // Marketing/newsletters/announcements - specific
        'donating \$200k', 'donating \$', 'newsletter', 'hackathon', 
        'competition', 'contest', 'winner', 'announcing', 
        'we are excited', 'join us', 'event', 'webinar', 'workshop', 
        'conference', 'prize', 'award', 'donate', 'donation', 
        'charity', 'fundraiser',
      ];
      
      for (final keyword in excludeKeywords) {
        if (fullText.contains(keyword.toLowerCase())) {
          print('❌ Excluding email due to keyword "$keyword": $subject');
          return null;
        }
      }
      
      // Check email domain for obvious non-subscription senders
      final fromLower = from.toLowerCase();
      if (fromLower.contains('marketing@') || 
          fromLower.contains('failed-payments@') ||
          fromLower.contains('noreply@marketing') ||
          fromLower.contains('engage.canva.com')) {
        print('❌ Excluding email from marketing/failed payment domain: $from');
        return null;
      }
      
      // MODERATE CHECK: Look for subscription patterns
      final subscriptionIndicators = [
        'subscription',
        'recurring',
        'membership',
        'auto-renew',
        'renewal',
        'billing',
        'invoice',
        'charged',
        'payment',
        'confirmation',
        'monthly',
        'yearly',
        'annual',
        'plan',
      ];
      
      final hasSubscriptionIndicators = subscriptionIndicators.any((indicator) => 
          fullText.contains(indicator.toLowerCase()));
      
      // OR is from known subscription service  
      final knownServiceDomains = [
        'netflix', 'spotify', 'amazon', 'apple', 'google', 'microsoft',
        'adobe', 'youtube', 'hulu', 'disney', 'paramount', 'hbo',
        'twitch', 'dropbox', 'zoom', 'slack', 'notion', 'canva',
        'figma', 'grammarly', 'github'
      ];
      
      final isFromKnownService = knownServiceDomains.any((service) => 
          from.toLowerCase().contains(service));
      
      if (!hasSubscriptionIndicators && !isFromKnownService) {
        print('❌ No subscription indicators or known service in: $subject');
        return null;
      }
      
      // Additional check: Exclude newsletters/announcements (but only if NOT a subscription)
      final hasSubscriptionTerms = fullText.contains('subscription') || 
          fullText.contains('renewal') || 
          fullText.contains('billing') ||
          fullText.contains('charged') ||
          fullText.contains('membership');
      
      if (!hasSubscriptionTerms) {
        final newsletterMarkers = [
          'newsletter', 'announcement', 'announcing', 'hackathon', 'competition',
          'contest', 'giveaway', 'winner', 'prize', 'award', 'join us',
          'we are excited', 'event', 'webinar', 'workshop', 'template',
          'design inspiration', 'marketing', 'promotional', 'campaign'
        ];
        
        for (final marker in newsletterMarkers) {
          if (fullText.contains(marker.toLowerCase())) {
            print('❌ Excluding newsletter/announcement due to "$marker": $subject');
            return null;
          }
        }
      }
      
      // Check for unrealistic amounts (likely promotional content)
      final largeAmountPattern = RegExp(r'[\$€£¥₹₦]\s*(\d{3,})[,.]?(\d{3,})');
      final largeAmountMatch = largeAmountPattern.firstMatch(fullText);
      if (largeAmountMatch != null) {
        final amountStr = largeAmountMatch.group(0) ?? '';
        final amount = double.tryParse(amountStr.replaceAll(RegExp(r'[\$€£¥₹₦,]'), ''));
        if (amount != null && amount > 1000) {
          print('❌ Excluding email with unrealistic amount ($amountStr): $subject');
          return null;
        }
      }
      
      // RELAXED CHECK: Look for any pricing indicators
      final hasPricingInfo = RegExp(r'[\$€£¥₹₦]\s*\d+|ngn\s*\d+|usd\s*\d+|\d+\.\d+|\d+,\d+|price|cost|amount|total|charged|fee|billing|payment|renewal|subscription')
          .hasMatch(fullText);
      
      if (!hasPricingInfo) {
        print('❌ No pricing information found in: $subject');
        return null;
      }
      
      // Only exclude very specific API credit emails
      if (fullText.contains('api credit') || fullText.contains('fund your account') || 
          fullText.contains('credit balance') || fullText.contains('token purchase') ||
          fullText.contains('account has been funded')) {
        print('❌ Excluding API/credit email: $subject');
        return null;
      }
      
      // Extract subscription details
      final serviceName = _extractServiceName(from, subject, body);
      final amount = _extractAmount(subject, body);
      final currency = _extractCurrency(subject, body);
      final billingCycle = _extractBillingCycle(subject, body);
      
      print('🔍 Extracted details: Service=$serviceName, Amount=$amount, Currency=$currency, From=$from');
      
      if (serviceName != null && amount != null) {
        // Extract trial and start date information
        final trialInfo = _extractTrialInfo(subject, body);
        
        // Fetch logo for the detected service
        String? logoUrl;
        try {
          final logoSearchTerm = _getLogoSearchTerm(serviceName);
          logoUrl = await _logoService.getLogoUrl(logoSearchTerm);
          print('🎨 Logo fetched for $serviceName (searched: $logoSearchTerm): $logoUrl');
        } catch (e) {
          print('❌ Failed to fetch logo for $serviceName: $e');
        }
        
        final emailDate = _parseEmailDate(date);
        final extractedStartDate = trialInfo['startDate'] as DateTime?;
        
        print('📅 Date info for $serviceName:');
        print('   Raw email date: $date');
        print('   Parsed email date: $emailDate');
        print('   Extracted start date: $extractedStartDate');
        print('   Will use: ${extractedStartDate ?? emailDate ?? DateTime.now()}');
        
        return DetectedSubscription(
          serviceName: serviceName,
          amount: amount,
          currency: currency ?? 'USD',
          billingCycle: billingCycle ?? BillingCycle.monthly,
          detectedFrom: from,
          emailSubject: subject,
          emailDate: emailDate,
          startDate: extractedStartDate,
          billingStartDate: trialInfo['billingStartDate'] as DateTime?,
          isFreeTrial: trialInfo['isFreeTrial'] as bool? ?? false,
          trialDays: trialInfo['trialDays'] as int?,
          logoUrl: logoUrl,
        );
      }
      
      print('❌ Missing required details (service=$serviceName, amount=$amount): $subject');
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
    final text = '$subject $body'.toLowerCase();
    
    // Handle Apple email addresses specially
    if (from.toLowerCase().contains('apple.com')) {
      print('🍎 Analyzing Apple email for service name...');
      print('🍎 Subject: $subject');
      print('🍎 Text sample: ${text.length > 200 ? text.substring(0, 200) : text}...');
      
             // Dynamic extraction patterns for Apple emails - capture full service names
       final appleServicePatterns = [
         // Pattern 1: Full service name with descriptors (prioritize complete names)
         RegExp(r'([a-zA-Z][a-zA-Z\s&+\-]{2,40}?\s+(?:photo\s*&\s*video\s+editor|prime\s+video|tv\+?|music|arcade|one|fitness\+?|news\+?))', caseSensitive: false),
         
         // Pattern 2: "Your [Full Service Name] subscription"
         RegExp(r'your\s+([a-zA-Z][a-zA-Z\s&+\-]{3,40}?)\s+subscription', caseSensitive: false),
         
         // Pattern 3: Complete service names in subject lines (before billing/problem keywords)
         RegExp(r'^([a-zA-Z][a-zA-Z\s&+\-]{3,40}?)(?:\s*[-–—]\s*(?:billing|subscription|premium|problem|renewal|statement))', caseSensitive: false),
         
         // Pattern 4: Service names followed by plan types
         RegExp(r'([a-zA-Z][a-zA-Z\s&+\-]{3,40}?)\s+(?:premium\s+yearly|plus|pro|basic|standard)', caseSensitive: false),
         
         // Pattern 5: "From [Service Name]" with extended capture
         RegExp(r'(?:from|for)\s+([a-zA-Z][a-zA-Z\s&+\-]{3,40}?)(?:\s+(?:subscription|billing|service)|$|\s*[-–—])', caseSensitive: false),
       ];
      
      print('🍎 Analyzing Apple email for service name...');
      print('🍎 Subject: $subject');
      print('🍎 Text sample: ${text.length > 200 ? text.substring(0, 200) : text}...');
      
      for (int i = 0; i < appleServicePatterns.length; i++) {
        final pattern = appleServicePatterns[i];
        final match = pattern.firstMatch('$subject $body');
        
        if (match != null && match.group(1) != null) {
          String extractedName = match.group(1)!.trim();
          
          // Clean up the extracted name
          extractedName = _cleanExtractedServiceName(extractedName);
          
          // Validate it's a reasonable service name (not too generic)
          if (_isValidServiceName(extractedName)) {
            print('🍎 ✅ Pattern ${i + 1} matched: "$extractedName"');
            return extractedName;
          } else {
            print('🍎 ❌ Pattern ${i + 1} matched but invalid name: "$extractedName"');
          }
        }
      }
      
      print('🍎 ❌ Could not extract service name from patterns, falling back to Apple Service');
      return 'Apple Service'; // Fallback for Apple
    }
    
    // Try to extract from known domains
    for (final domain in _subscriptionDomains) {
      if (from.toLowerCase().contains(domain)) {
        return _formatServiceName(domain);
      }
    }
    
    // Common patterns for service names
    final patterns = [
      RegExp(r'(lightroom photo & video editor|amazon prime video|netflix|spotify|apple|google|amazon|microsoft|adobe|dropbox|youtube|disney|hulu)'),
      RegExp(r'your ([a-z\s&]+) subscription'),
      RegExp(r'thank you for your ([a-z\s&]+) payment'),
      RegExp(r'([a-z\s&]+) billing statement'),
      RegExp(r'app\s+([a-z\s&]+)'),
      RegExp(r'subscription\s+([a-z\s&]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return _formatServiceName(match.group(1) ?? '');
      }
    }
    
    return 'Unknown Service';
  }

  /// Extract amount from email content
  double? _extractAmount(String subject, String body) {
    final text = '$subject $body';
    
    // Prioritize patterns with explicit subscription pricing context
    final contextualPatterns = [
      // Naira with strong subscription context
      RegExp(r'(?:renewal price|subscription|monthly|billing|amount charged|total)\s*[:\s]*₦\s*(\d{1,2}[,\.]\d{3}(?:[,\.]\d{2})?)'),
      RegExp(r'₦\s*(\d{1,2}[,\.]\d{3}(?:[,\.]\d{2})?)\s*(?:/month|/year|monthly|yearly|per month|per year)'),
      
      // USD with strong subscription context  
      RegExp(r'(?:renewal price|subscription|monthly|billing|amount charged|total)\s*[:\s]*\$\s*(\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?)'),
      RegExp(r'\$\s*(\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?)\s*(?:/month|/year|monthly|yearly|per month|per year)'),
      
      // Other currencies with subscription context
      RegExp(r'(?:renewal price|subscription|monthly|billing|amount charged|total)\s*[:\s]*[€£¥]\s*(\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?)'),
      
      // Currency codes with subscription context
      RegExp(r'(?:renewal price|subscription|monthly|billing|amount charged|total)\s*[:\s]*(\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?)\s*(NGN|USD|EUR|GBP)'),
    ];
    
    // Try contextual patterns first
    for (final pattern in contextualPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          final amount = _parseAmount(amountStr);
          if (amount != null && amount >= 0.99 && amount <= 10000) { // Wider range
            print('✅ Found contextual amount: $amountStr -> $amount');
            return amount;
          }
        }
      }
    }
    
    // Fallback: Look for currency symbols with reasonable amounts
    final fallbackPatterns = [
      RegExp(r'₦\s*(\d{1,4}[,\.]\d{3}(?:[,\.]\d{2})?)'), // Naira format
      RegExp(r'₦\s*(\d{1,4}(?:[,\.]\d{3})*)'), // Naira without cents
      RegExp(r'\$\s*(\d{1,4}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)'), // USD
      RegExp(r'[€£]\s*(\d{1,4}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)'), // EUR, GBP
    ];
    
    for (final pattern in fallbackPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          final amount = _parseAmount(amountStr);
          if (amount != null && amount >= 0.99 && amount <= 10000) {
            // Additional validation: avoid amounts that look like usernames/IDs
            if (!_looksLikeUsernameOrId(text, amountStr)) {
              print('✅ Found fallback amount: $amountStr -> $amount');
              return amount;
            } else {
              print('❌ Skipping suspected username/ID: $amountStr');
            }
          }
        }
      }
    }
    
    return null;
  }
  
  /// Parse amount string to double
  double? _parseAmount(String amountStr) {
    String clean = amountStr.trim();
    
    // Handle Naira format: 2,300.00
    if (clean.contains(',') && clean.contains('.')) {
      final parts = clean.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        // This is likely 2,300.00 format
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains(',') && !clean.contains('.')) {
      // This could be European format like 2.300,00 or just 2,300
      if (clean.split(',').last.length == 2) {
        // European: 2.300,00 -> 2300.00
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // US: 2,300 -> 2300
        clean = clean.replaceAll(',', '');
      }
    }
    
    return double.tryParse(clean);
  }
  
  /// Check if this email is promotional content
  bool _isPromotionalContent(String subject, String body, double amount) {
    final fullText = '$subject $body'.toLowerCase();
    
    // Check for large amounts that suggest promotional content
    if (amount > 1000) {
      return true;
    }
    
    // Check for promotional keywords
    final promotionalKeywords = [
      'newsletter', 'marketing', 'promotional', 'campaign', 'hackathon',
      'competition', 'contest', 'giveaway', 'winner', 'prize', 'award',
      'template', 'inspiration', 'announcing', 'we are excited',
      'design challenge', 'creative challenge'
    ];
    
    return promotionalKeywords.any((keyword) => fullText.contains(keyword));
  }

  /// Check if amount looks like a username or ID or promotional content
  bool _looksLikeUsernameOrId(String context, String amountStr) {
    final contextLower = context.toLowerCase();
    
    // Check for patterns that suggest this is not a subscription price
    return contextLower.contains('$amountStr.slack.com') ||
           contextLower.contains('personal-') ||
           contextLower.contains('user-') ||
           contextLower.contains('pr #$amountStr') ||
           contextLower.contains('#$amountStr') ||
           contextLower.contains('issue $amountStr') ||
           contextLower.contains('id: $amountStr') ||
           contextLower.contains('username') ||
           
           // Promotional/marketing content - more comprehensive
           contextLower.contains('hackathon') ||
           contextLower.contains('competition') ||
           contextLower.contains('contest') ||
           contextLower.contains('prize') ||
           contextLower.contains('winner') ||
           contextLower.contains('award') ||
           contextLower.contains('giveaway') ||
           contextLower.contains('announce') ||
           contextLower.contains('join us') ||
           contextLower.contains('we are excited') ||
           contextLower.contains('newsletter') ||
           contextLower.contains('marketing') ||
           contextLower.contains('promotional') ||
           contextLower.contains('campaign') ||
           contextLower.contains('template') ||
           contextLower.contains('inspiration') ||
           contextLower.contains('k ') || // For amounts like "200k"
           (contextLower.contains('000') && amountStr.length <= 3) || // Large round numbers
           
           // Failed payment context - more comprehensive
           contextLower.contains('failed') ||
           contextLower.contains('declined') ||
           contextLower.contains('unable to process') ||
           contextLower.contains('payment failed') ||
           contextLower.contains('could not be processed') ||
           contextLower.contains('was declined') ||
           contextLower.contains('debit failed');
  }

  /// Extract currency from email content
  String? _extractCurrency(String subject, String body) {
    final text = '$subject $body'.toUpperCase();
    
    // Check for Naira first (since you mentioned Naira subscriptions)
    if (text.contains('NGN') || text.contains('₦') || text.contains('NAIRA')) return 'NGN';
    if (text.contains('USD') || text.contains('\$')) return 'USD';
    if (text.contains('EUR') || text.contains('€')) return 'EUR';
    if (text.contains('GBP') || text.contains('£')) return 'GBP';
    if (text.contains('CAD')) return 'CAD';
    if (text.contains('AUD')) return 'AUD';
    if (text.contains('INR') || text.contains('₹')) return 'INR';
    if (text.contains('JPY') || text.contains('¥')) return 'JPY';
    if (text.contains('CNY') || text.contains('RMB')) return 'CNY';
    
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

  /// Extract trial and date information from email
  Map<String, dynamic> _extractTrialInfo(String subject, String body) {
    final text = '$subject $body';
    final now = DateTime.now();
    
    print('🔍 Trial detection analyzing text: ${text.substring(0, text.length > 500 ? 500 : text.length)}...');
    
    // Look for start date patterns
    DateTime? startDate;
    DateTime? billingStartDate;
    bool isFreeTrial = false;
    int? trialDays;
    
    // Pattern for "Date Accepted: 03 June 2025" and slash formats
    final dateAcceptedPattern = RegExp(r'date accepted\s*:?\s*(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})', caseSensitive: false);
    final dateAcceptedMatch = dateAcceptedPattern.firstMatch(text);
    
    // Try slash format patterns for start dates too
    final startDateSlashPatterns = [
      RegExp(r'trial.*?starting (\d{1,2})/(\d{1,2})/(\d{4})', caseSensitive: false),
      RegExp(r'starts (\d{1,2})/(\d{1,2})/(\d{4})', caseSensitive: false),
    ];
    
    if (dateAcceptedMatch != null) {
      final day = int.tryParse(dateAcceptedMatch.group(1) ?? '');
      final monthName = dateAcceptedMatch.group(2)?.toLowerCase();
      final year = int.tryParse(dateAcceptedMatch.group(3) ?? '');
      
      if (day != null && monthName != null && year != null) {
        final monthMap = {
          'january': 1, 'february': 2, 'march': 3, 'april': 4,
          'may': 5, 'june': 6, 'july': 7, 'august': 8,
          'september': 9, 'october': 10, 'november': 11, 'december': 12
        };
        final month = monthMap[monthName];
        if (month != null) {
          startDate = DateTime(year, month, day);
        }
      }
    } else {
      // Try slash format patterns for start dates
      for (final pattern in startDateSlashPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final firstNum = int.tryParse(match.group(1) ?? '');
          final secondNum = int.tryParse(match.group(2) ?? '');
          final year = int.tryParse(match.group(3) ?? '');
          
          print('📅 Trial start slash date found: $firstNum/$secondNum/$year');
          
          if (firstNum != null && secondNum != null && year != null) {
            // Use same logic as billing start date
            int month, day;
            if (firstNum > 12) {
              day = firstNum;
              month = secondNum;
            } else if (secondNum > 12) {
              month = firstNum;
              day = secondNum;
            } else {
              // Default to DD/MM/YYYY (international format)
              day = firstNum;
              month = secondNum;
            }
            
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
              startDate = DateTime(year, month, day);
              print('📅 Parsed trial start slash date as: $month/$day/$year -> $startDate');
              break;
            }
          }
        }
      }
    }
    
    // Look for free trial information
    final freeTrialPattern = RegExp(r'free for (\d+) (day|week|month)', caseSensitive: false);
    final freeTrialMatch = freeTrialPattern.firstMatch(text);
    
    print('🆓 Looking for free trial pattern in text...');
    print('🆓 Pattern: free for (\\d+) (day|week|month)');
    
    if (freeTrialMatch != null) {
      isFreeTrial = true;
      final duration = int.tryParse(freeTrialMatch.group(1) ?? '');
      final unit = freeTrialMatch.group(2)?.toLowerCase();
      
      print('🆓 ✅ Found free trial: ${freeTrialMatch.group(0)}');
      print('🆓 Duration: $duration, Unit: $unit');
      
      if (duration != null && unit != null) {
        switch (unit) {
          case 'day':
            trialDays = duration;
            break;
          case 'week':
            trialDays = duration * 7;
            break;
          case 'month':
            trialDays = duration * 30;
            break;
        }
        print('🆓 Calculated trial days: $trialDays');
      }
    } else {
      print('🆓 ❌ No free trial pattern found');
      
      // Try alternative patterns
      final altPatterns = [
        RegExp(r'free trial.*?(\d+)\s+(day|week|month)', caseSensitive: false),
        RegExp(r'trial.*?free.*?(\d+)\s+(day|week|month)', caseSensitive: false),
        RegExp(r'(\d+)\s+(day|week|month).*?free', caseSensitive: false),
        RegExp(r'free.*?(\d+)\s+(day|week|month)', caseSensitive: false),
      ];
      
      for (final pattern in altPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          print('🆓 ✅ Found with alternative pattern: ${match.group(0)}');
          isFreeTrial = true;
          final duration = int.tryParse(match.group(1) ?? '');
          final unit = match.group(2)?.toLowerCase();
          
          if (duration != null && unit != null) {
            switch (unit) {
              case 'day':
                trialDays = duration;
                break;
              case 'week':
                trialDays = duration * 7;
                break;
              case 'month':
                trialDays = duration * 30;
                break;
            }
            print('🆓 Alternative pattern trial days: $trialDays');
          }
          break;
        }
      }
    }
    
    // Look for billing start date "starting 10 June 2025"
    final billingStartPattern = RegExp(r'starting (\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})', caseSensitive: false);
    final billingStartMatch = billingStartPattern.firstMatch(text);
    
    // Also try alternative patterns including MM/DD/YYYY format
    final altBillingPatterns = [
      RegExp(r'billing.*?starting (\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})', caseSensitive: false),
      RegExp(r'charged.*?(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})', caseSensitive: false),
      RegExp(r'payment.*?(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})', caseSensitive: false),
      // Add patterns for MM/DD/YYYY and DD/MM/YYYY formats
      RegExp(r'billing starts (\d{1,2})/(\d{1,2})/(\d{4})', caseSensitive: false),
      RegExp(r'starting (\d{1,2})/(\d{1,2})/(\d{4})', caseSensitive: false),
    ];
    
    print('📅 Looking for billing start date pattern...');
    print('📅 Pattern: starting (\\d{1,2})\\s+(month)\\s+(\\d{4})');
    
    RegExpMatch? foundMatch = billingStartMatch;
    
    if (billingStartMatch != null) {
      print('📅 ✅ Found billing start with main pattern: ${billingStartMatch.group(0)}');
    } else {
      print('📅 ❌ Main pattern failed, trying alternatives...');
      for (final altPattern in altBillingPatterns) {
        final altMatch = altPattern.firstMatch(text);
        if (altMatch != null) {
          foundMatch = altMatch;
          print('📅 ✅ Found billing start with alternative pattern: ${altMatch.group(0)}');
          break;
        }
      }
    }
    
    if (foundMatch != null) {
      // Check if this is a slash-separated date format (MM/DD/YYYY or DD/MM/YYYY)
      final matchedText = foundMatch.group(0)?.toLowerCase() ?? '';
      if (matchedText.contains('/')) {
        final firstNum = int.tryParse(foundMatch.group(1) ?? '');
        final secondNum = int.tryParse(foundMatch.group(2) ?? '');
        final year = int.tryParse(foundMatch.group(3) ?? '');
        
        print('📅 Slash date format found: $firstNum/$secondNum/$year');
        
        if (firstNum != null && secondNum != null && year != null) {
          // Assume DD/MM/YYYY format if first number is > 12, otherwise check second number
          int month, day;
          if (firstNum > 12) {
            // Must be DD/MM/YYYY format
            day = firstNum;
            month = secondNum;
          } else if (secondNum > 12) {
            // Must be MM/DD/YYYY format  
            month = firstNum;
            day = secondNum;
          } else {
            // Ambiguous case - default to DD/MM/YYYY (international format) since user confirmed 3/6/25 = June 3rd
            day = firstNum;
            month = secondNum;
          }
          
          // Validate month and day ranges
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            billingStartDate = DateTime(year, month, day);
            print('📅 Parsed slash date as: $month/$day/$year -> $billingStartDate');
          } else {
            print('📅 ❌ Invalid month ($month) or day ($day) in slash date');
          }
        }
      } else {
        // Original month name parsing logic
        final day = int.tryParse(foundMatch.group(1) ?? '');
        final monthName = foundMatch.group(2)?.toLowerCase();
        final year = int.tryParse(foundMatch.group(3) ?? '');
        
        print('📅 Day: $day, Month: $monthName, Year: $year');
        
        if (day != null && monthName != null && year != null) {
          final monthMap = {
            'january': 1, 'february': 2, 'march': 3, 'april': 4,
            'may': 5, 'june': 6, 'july': 7, 'august': 8,
            'september': 9, 'october': 10, 'november': 11, 'december': 12
          };
          final month = monthMap[monthName];
          if (month != null) {
            billingStartDate = DateTime(year, month, day);
            print('📅 Parsed billing start date: $billingStartDate');
          }
        }
      }
    } else {
      print('📅 ❌ No billing start date pattern found with any method');
    }
    
    print('📊 Trial extraction summary:');
    print('   Start Date: $startDate');
    print('   Billing Start Date: $billingStartDate');
    print('   Is Free Trial: $isFreeTrial');
    print('   Trial Days: $trialDays');
    
    return {
      'startDate': startDate,
      'billingStartDate': billingStartDate,
      'isFreeTrial': isFreeTrial,
      'trialDays': trialDays,
    };
  }

  /// Parse email date string
  DateTime? _parseEmailDate(String dateStr) {
    try {
      // Try standard parsing first
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Gmail uses RFC 2822 format like: "Mon, 21 Oct 2024 10:30:00 +0000"
        // Try to parse this format
        final cleanedDate = dateStr
            .replaceAll(RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\s*'), '')
            .replaceAll(RegExp(r'\s*\([^)]+\)$'), '') // Remove timezone names in parentheses
            .replaceAll(RegExp(r'\s*[+-]\d{4}$'), ''); // Remove timezone offset
        
        // Try parsing as "21 Oct 2024 10:30:00"
        final parts = cleanedDate.split(' ');
        if (parts.length >= 3) {
          final day = int.tryParse(parts[0]);
          final monthName = parts[1].toLowerCase();
          final year = int.tryParse(parts[2]);
          
          final monthMap = {
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
            'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
            'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12
          };
          
          final month = monthMap[monthName];
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      } catch (e2) {
        print('Failed to parse email date: $dateStr - $e2');
      }
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

  /// Convert detected service names to better logo search terms
  String _getLogoSearchTerm(String serviceName) {
    final lowerName = serviceName.toLowerCase();
    
    // Map detected names to better logo search terms
    if (lowerName.contains('amazon prime video') || lowerName == 'amazon prime video') {
      return 'Prime Video';
    }
    
    if (lowerName.contains('lightroom photo & video editor') || lowerName == 'lightroom photo & video editor') {
      return 'Adobe Lightroom';
    }
    
    if (lowerName.contains('youtube premium') || lowerName == 'youtube premium') {
      return 'YouTube Premium';
    }
    
    if (lowerName.contains('youtube music') || lowerName == 'youtube music') {
      return 'YouTube Music';
    }
    
    if (lowerName.contains('microsoft 365') || lowerName == 'microsoft 365') {
      return 'Microsoft 365';
    }
    
    if (lowerName.contains('office 365') || lowerName == 'office 365') {
      return 'Microsoft 365';
    }
    
    if (lowerName.contains('google one') || lowerName == 'google one') {
      return 'Google One';
    }
    
    if (lowerName.contains('google drive') || lowerName == 'google drive') {
      return 'Google Drive';
    }
    
    if (lowerName.contains('icloud') || lowerName == 'icloud storage') {
      return 'iCloud';
    }
    
    if (lowerName.contains('adobe creative cloud') || lowerName == 'adobe creative cloud') {
      return 'Adobe Creative Cloud';
    }
    
    if (lowerName.contains('github pro') || lowerName == 'github pro') {
      return 'GitHub';
    }
    
    if (lowerName.contains('discord nitro') || lowerName == 'discord nitro') {
      return 'Discord Nitro';
    }
    
    // For services ending with specific suffixes, clean them up
    if (lowerName.endsWith(' subscription')) {
      return serviceName.substring(0, serviceName.length - 12);
    }
    
    if (lowerName.endsWith(' premium')) {
      return serviceName;  // Keep "Premium" for services like "Spotify Premium"
    }
    
    // Default: return the original service name
    return serviceName;
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

  /// Clean extracted service name by removing unwanted characters and formatting
  String _cleanExtractedServiceName(String name) {
    String cleaned = name.trim();
    
    // Remove common prefixes that aren't part of the service name
    cleaned = cleaned.replaceAll(RegExp(r'^(the|your|my)\s+', caseSensitive: false), '');
    
    // Remove trailing unwanted suffixes but preserve important descriptors
    cleaned = cleaned.replaceAll(RegExp(r'\s+(subscription|billing|payment|plan|service|statement|problem|renewal)$', caseSensitive: false), '');
    
    // Remove trailing punctuation but preserve + symbols in service names
    cleaned = cleaned.replaceAll(RegExp(r'[.,:;!?\-]+$'), '');
    
    // Clean up multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Capitalize properly but preserve existing + symbols and & characters
    cleaned = cleaned.split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          
          // Handle special cases
          if (word.toLowerCase() == 'tv+' || word.toLowerCase() == 'tv') {
            return word.contains('+') ? 'TV+' : 'TV';
          }
          if (word == '&') return '&';
          if (word.endsWith('+')) {
            return word.substring(0, word.length - 1).toLowerCase().replaceFirst(word[0], word[0].toUpperCase()) + '+';
          }
          
          // Regular capitalization
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
    
    return cleaned;
  }

  /// Check if extracted name is a valid service name (not too generic or suspicious)
  bool _isValidServiceName(String name) {
    if (name.length < 3 || name.length > 50) return false;
    
    // Exclude overly generic terms and email-specific words
    final invalidTerms = [
      'subscription', 'billing', 'payment', 'service', 'app', 'plan',
      'premium', 'plus', 'pro', 'basic', 'standard', 'monthly', 'yearly',
      'annual', 'free', 'trial', 'your', 'my', 'the', 'problem', 'help',
      'receipt', 'invoice', 'statement', 'confirmation', 'renewal',
      'billing problem', 'help with', 'your subscription', 'billing statement',
      'payment problem', 'account', 'update', 'important', 'notice',
      'reminder', 'expired', 'failed', 'error', 'issue'
    ];
    
    final lowerName = name.toLowerCase().trim();
    
    // Check exact matches or if the name starts with invalid terms
    for (final term in invalidTerms) {
      if (lowerName == term || lowerName.startsWith('$term ') || lowerName.endsWith(' $term')) {
        return false;
      }
    }
    
    // Must contain at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(name)) return false;
    
    // Exclude names that are mostly numbers or special characters
    final letterCount = RegExp(r'[a-zA-Z]').allMatches(name).length;
    if (letterCount < name.length * 0.6) return false;
    
    // Should not be all uppercase unless it's a known acronym
    if (name == name.toUpperCase() && name.length > 4) return false;
    
    return true;
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
  final DateTime? startDate;
  final DateTime? billingStartDate;
  final bool isFreeTrial;
  final int? trialDays;
  final String? logoUrl;

  const DetectedSubscription({
    required this.serviceName,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.detectedFrom,
    required this.emailSubject,
    this.emailDate,
    this.startDate,
    this.billingStartDate,
    this.isFreeTrial = false,
    this.trialDays,
    this.logoUrl,
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