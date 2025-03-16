import 'package:flutter/material.dart';

class LogoService {
  static final LogoService _instance = LogoService._internal();
  
  factory LogoService() {
    return _instance;
  }
  
  LogoService._internal();
  
  // Direct URLs for most popular services - these will be tried first
  final Map<String, String> _directLogos = {
    'spotify': 'https://storage.googleapis.com/pr-newsroom-wp/1/2018/11/Spotify_Logo_RGB_Green.png',
    'apple music': 'https://www.apple.com/v/apple-music/s/images/overview/icon_apple_music__c6i9feyd4kky_large_2x.png',
    'netflix': 'https://assets.nflxext.com/us/ffe/siteui/common/icons/nficon2016.png',
    'disney+': 'https://cnbl-cdn.bamgrid.com/assets/7ecc8bcb60ad77193058d63e321bd21cbac2fc67281dbd9927676ea4a4c83594/original',
    'disney plus': 'https://cnbl-cdn.bamgrid.com/assets/7ecc8bcb60ad77193058d63e321bd21cbac2fc67281dbd9927676ea4a4c83594/original',
    'disneyplus': 'https://cnbl-cdn.bamgrid.com/assets/7ecc8bcb60ad77193058d63e321bd21cbac2fc67281dbd9927676ea4a4c83594/original',
    'hulu': 'https://assetshuluimcom-a.akamaihd.net/h3o/facebook_share_thumb_default_hulu.jpg',
    'hbo max': 'https://hbomax-images.warnermediacdn.com/2020-05/square%20social%20logo%20400%20x%20400_0.png',
    'hbomax': 'https://hbomax-images.warnermediacdn.com/2020-05/square%20social%20logo%20400%20x%20400_0.png',
    'youtube premium': 'https://www.gstatic.com/youtube/img/branding/youtubelogo/svg/youtubelogo.svg',
    'youtube': 'https://www.gstatic.com/youtube/img/branding/youtubelogo/svg/youtubelogo.svg',
    'amazon prime': 'https://m.media-amazon.com/images/G/01/digital/video/acquisition/amazon_video_light_on_dark.png',
    'amazon': 'https://m.media-amazon.com/images/G/01/digital/video/acquisition/amazon_video_light_on_dark.png',
    'prime': 'https://m.media-amazon.com/images/G/01/digital/video/acquisition/amazon_video_light_on_dark.png',
    'paramount+': 'https://www.paramountplus.com/assets/pplus/P+Logo_512x512.png',
    'paramountplus': 'https://www.paramountplus.com/assets/pplus/P+Logo_512x512.png',
    'apple tv+': 'https://tv.apple.com/assets/knowledge-graph/tv.png',
    'apple tv': 'https://tv.apple.com/assets/knowledge-graph/tv.png',
    'appletvplus': 'https://tv.apple.com/assets/knowledge-graph/tv.png',
    'appletv': 'https://tv.apple.com/assets/knowledge-graph/tv.png',
    'peacock': 'https://www.peacocktv.com/dam/growth/assets/seo/peacock-logo-white-background.png',
    'crunchyroll': 'https://static.crunchyroll.com/cr-assets/icons/beta/apple-touch-icon-152x152.png',
    'tidal': 'https://tidal.com/img/tidal-share-image.png',
    'deezer': 'https://e-cdns-files.dzcdn.net/img/common/opengraph-logo.png',
    'cursor': 'https://cursor.sh/apple-touch-icon.png',
  };
  
  // Map of common subscription services to their logo URLs
  final Map<String, String> _logoMap = {
    'netflix': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/netflix_logo_icon_170919.png',
    'spotify': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/spotify_logo_icon_170906.png',
    'amazon': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/amazon_logo_icon_168602.png',
    'disney': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/disney_plus_logo_icon_170057.png',
    'youtube': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/youtube_logo_icon_168737.png',
    'apple': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/apple_logo_icon_168588.png',
    'apple music': 'https://www.apple.com/v/apple-music/s/images/shared/apple-music-logo__dcojfwkzna2q_large.svg',
    'hbo': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/hbo_logo_icon_170310.png',
    'hulu': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/hulu_logo_icon_170429.png',
    'adobe': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/adobe_logo_icon_168156.png',
    'microsoft': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/microsoft_logo_icon_169837.png',
    'playstation': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/playstation_logo_icon_170528.png',
    'xbox': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/xbox_logo_icon_169694.png',
    'nintendo': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/nintendo_logo_icon_169898.png',
    'dropbox': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/dropbox_logo_icon_169102.png',
    'google': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/google_logo_icon_169090.png',
    'icloud': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/apple_icloud_logo_icon_169502.png',
    'audible': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/audible_logo_icon_168591.png',
    'twitch': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/twitch_logo_icon_170383.png',
    'patreon': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/patreon_logo_icon_170869.png',
    'notion': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/notion_logo_icon_168407.png',
    'slack': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/slack_logo_icon_170727.png',
    'zoom': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/zoom_logo_icon_168886.png',
    'canva': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/canva_logo_icon_168460.png',
    'figma': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/figma_logo_icon_170157.png',
    'grammarly': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/grammarly_logo_icon_170072.png',
    'expressvpn': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/expressvpn_logo_icon_169255.png',
    'nordvpn': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/nordvpn_logo_icon_169138.png',
    'surfshark': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/surfshark_logo_icon_169352.png',
    'dashlane': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/dashlane_logo_icon_169063.png',
    'lastpass': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/lastpass_logo_icon_169326.png',
    '1password': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/1password_logo_icon_169138.png',
    'cursor': 'https://cursor.sh/apple-touch-icon.png',
    // Additional popular services
    'github': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/github_logo_icon_169115.png',
    'gitlab': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/gitlab_logo_icon_169095.png',
    'bitbucket': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/bitbucket_logo_icon_168696.png',
    'trello': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/trello_logo_icon_167829.png',
    'asana': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/asana_logo_icon_168624.png',
    'jira': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/jira_logo_icon_167822.png',
    'confluence': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/confluence_logo_icon_167978.png',
    'monday': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/monday_logo_icon_169962.png',
    'clickup': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/clickup_logo_icon_169540.png',
    'evernote': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/evernote_logo_icon_169257.png',
    'todoist': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/todoist_logo_icon_168820.png',
    'mailchimp': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/mailchimp_logo_icon_169413.png',
    'hubspot': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/hubspot_logo_icon_169489.png',
    'salesforce': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/salesforce_logo_icon_169371.png',
    'zendesk': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/zendesk_logo_icon_168835.png',
    'intercom': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/intercom_logo_icon_169301.png',
    'freshdesk': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/freshdesk_logo_icon_169242.png',
    'stripe': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/stripe_logo_icon_167963.png',
    'paypal': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/paypal_logo_icon_168055.png',
    'square': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/square_logo_icon_168598.png',
    'shopify': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/shopify_logo_icon_169262.png',
    'woocommerce': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/woocommerce_logo_icon_168808.png',
    'wordpress': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/wordpress_logo_icon_167953.png',
    'wix': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/wix_logo_icon_169269.png',
    'squarespace': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/squarespace_logo_icon_169312.png',
    'webflow': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/webflow_logo_icon_169218.png',
    'medium': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/medium_logo_icon_169898.png',
    'substack': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/substack_logo_icon_169845.png',
    'ghost': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/ghost_logo_icon_169236.png',
    'linkedin': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/linkedin_logo_icon_170234.png',
    'twitter': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/twitter_logo_icon_170312.png',
    'facebook': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/facebook_logo_icon_169150.png',
    'instagram': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/instagram_logo_icon_170643.png',
    'tiktok': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/tiktok_logo_icon_170731.png',
    'snapchat': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/snapchat_logo_icon_169539.png',
    'pinterest': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/pinterest_logo_icon_169225.png',
    'reddit': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/reddit_logo_icon_169439.png',
    'discord': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/discord_logo_icon_169260.png',
    'telegram': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/telegram_logo_icon_169325.png',
    'whatsapp': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/whatsapp_logo_icon_169180.png',
    'signal': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/signal_logo_icon_169539.png',
    'protonmail': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/protonmail_logo_icon_169837.png',
    'gmail': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/gmail_logo_icon_169102.png',
    'outlook': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/outlook_logo_icon_169622.png',
    // Additional streaming and music services
    'spotify premium': 'https://cdn.icon-icons.com/icons2/2699/PNG/512/spotify_logo_icon_170906.png',
    'apple music': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Apple_Music_icon.svg/2048px-Apple_Music_icon.svg.png',
    'apple tv': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Apple_TV_Plus_Logo.svg/2560px-Apple_TV_Plus_Logo.svg.png',
    'apple tv+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Apple_TV_Plus_Logo.svg/2560px-Apple_TV_Plus_Logo.svg.png',
    'apple arcade': 'https://developer.apple.com/app-store/marketing/guidelines/images/arcade-badge-preferred.svg',
    'apple news': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Apple_News_icon.svg/1024px-Apple_News_icon.svg.png',
    'apple news+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Apple_News_icon.svg/1024px-Apple_News_icon.svg.png',
    'apple one': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1667px-Apple_logo_black.svg.png',
    'apple fitness+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Apple_Fitness%2B_Icon.svg/1024px-Apple_Fitness%2B_Icon.svg.png',
    'tidal': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Tidal_%28service%29_logo.svg/2560px-Tidal_%28service%29_logo.svg.png',
    'deezer': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Deezer_logo.svg/1280px-Deezer_logo.svg.png',
    'pandora': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Pandora_logo.svg/2560px-Pandora_logo.svg.png',
    'soundcloud': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/SoundCloud_logo.svg/2560px-SoundCloud_logo.svg.png',
    'amazon music': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/84/Amazon_Music_logo.svg/1280px-Amazon_Music_logo.svg.png',
    'amazon prime': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Amazon_Prime_Logo.svg/2560px-Amazon_Prime_Logo.svg.png',
    'amazon prime video': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Amazon_Prime_Video_logo.svg/2560px-Amazon_Prime_Video_logo.svg.png',
    'paramount+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Paramount_Plus.svg/2560px-Paramount_Plus.svg.png',
    'peacock': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/NBCUniversal_Peacock_Logo.svg/2560px-NBCUniversal_Peacock_Logo.svg.png',
    'crunchyroll': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Crunchyroll_Logo.svg/1280px-Crunchyroll_Logo.svg.png',
    'funimation': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Funimation_Logo.svg/2560px-Funimation_Logo.svg.png',
    'hbo max': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/17/HBO_Max_Logo.svg/2560px-HBO_Max_Logo.svg.png',
    'discovery+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Discovery%2B_logo.svg/2560px-Discovery%2B_logo.svg.png',
    'disney+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Disney%2B_logo.svg/2560px-Disney%2B_logo.svg.png',
    'espn+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/ESPN%2B_logo.svg/2560px-ESPN%2B_logo.svg.png',
    'youtube premium': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/YouTube_Premium_logo.svg/1280px-YouTube_Premium_logo.svg.png',
    'youtube music': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Youtube_Music_icon.svg/1200px-Youtube_Music_icon.svg.png',
    'youtube tv': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/YouTube_TV_logo.svg/1280px-YouTube_TV_logo.svg.png',
    'sling tv': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Sling_TV_logo.svg/1280px-Sling_TV_logo.svg.png',
    'fubo tv': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/FuboTV_logo.svg/2560px-FuboTV_logo.svg.png',
    'philo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Philo_logo.svg/2560px-Philo_logo.svg.png',
    'showtime': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Showtime.svg/1280px-Showtime.svg.png',
    'starz': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Starz_2022.svg/2560px-Starz_2022.svg.png',
    'mubi': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/MUBI_logo.svg/1280px-MUBI_logo.svg.png',
    'criterion channel': 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Criterion_Channel_logo.svg/1280px-Criterion_Channel_logo.svg.png',
    'shudder': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/21/Shudder_logo.svg/1280px-Shudder_logo.svg.png',
    'britbox': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7c/BritBox_logo.svg/2560px-BritBox_logo.svg.png',
    'acorn tv': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Acorn_TV_logo.svg/2560px-Acorn_TV_logo.svg.png',
  };
  
  // Additional popular service names that map to the same logo
  final Map<String, String> _serviceAliases = {
    'netflix': 'netflix',
    'netflix premium': 'netflix',
    'spotify': 'spotify',
    'spotify premium': 'spotify',
    'amazon prime': 'amazon',
    'amazon prime video': 'amazon',
    'amazon music': 'amazon',
    'amazon music unlimited': 'amazon',
    'prime video': 'amazon',
    'prime': 'amazon',
    'disney plus': 'disney+',
    'disney+': 'disney+',
    'disneyplus': 'disney+',
    'disney': 'disney+',
    'hbo': 'hbo',
    'hbo max': 'hbo max',
    'hbomax': 'hbo max',
    'hbo now': 'hbo',
    'hulu': 'hulu',
    'hulu + live tv': 'hulu',
    'youtube': 'youtube',
    'youtube premium': 'youtube premium',
    'youtube music': 'youtube music',
    'youtube tv': 'youtube tv',
    'apple music': 'apple music',
    'applemusic': 'apple music',
    'apple tv': 'apple tv',
    'appletv': 'apple tv',
    'apple tv+': 'apple tv+',
    'appletvplus': 'apple tv+',
    'apple tv plus': 'apple tv+',
    'apple arcade': 'apple arcade',
    'applearcade': 'apple arcade',
    'apple one': 'apple one',
    'appleone': 'apple one',
    'apple news': 'apple news',
    'applenews': 'apple news',
    'apple news+': 'apple news+',
    'applenewsplus': 'apple news+',
    'apple fitness+': 'apple fitness+',
    'applefitness': 'apple fitness+',
    'apple fitness plus': 'apple fitness+',
    'icloud': 'icloud',
    'icloud+': 'icloud',
    'icloud plus': 'icloud',
    'paramount+': 'paramount+',
    'paramountplus': 'paramount+',
    'paramount plus': 'paramount+',
    'paramount': 'paramount+',
  };
  
  // Common word separators to try when matching
  final List<String> _commonSeparators = ['', ' ', '+', 'plus', '-', '_'];
  
  // Get logo URL from website URL or name
  String? getLogoUrl(String? websiteOrName) {
    if (websiteOrName == null || websiteOrName.isEmpty) {
      return null;
    }
    
    // Normalize the input (lowercase, remove extra spaces)
    final normalized = _normalizeInput(websiteOrName);
    
    // STEP 1: Check direct logos for most popular services first
    for (final entry in _directLogos.entries) {
      if (_isMatch(normalized, entry.key)) {
        return entry.value;
      }
    }
    
    // STEP 2: Check if we have a direct match in our aliases
    if (_serviceAliases.containsKey(normalized)) {
      final serviceName = _serviceAliases[normalized]!;
      if (_logoMap.containsKey(serviceName)) {
        return _logoMap[serviceName];
      }
    }
    
    // STEP 3: Try variations with different separators
    final possibleMatches = _generateVariations(normalized);
    for (final variation in possibleMatches) {
      // Check in direct logos
      for (final entry in _directLogos.entries) {
        if (_isMatch(variation, entry.key)) {
          return entry.value;
        }
      }
      
      // Check in aliases
      if (_serviceAliases.containsKey(variation)) {
        final serviceName = _serviceAliases[variation]!;
        if (_logoMap.containsKey(serviceName)) {
          return _logoMap[serviceName];
        }
      }
      
      // Check in logo map
      if (_logoMap.containsKey(variation)) {
        return _logoMap[variation];
      }
    }
    
    // STEP 4: Check for exact matches in our predefined map
    if (_logoMap.containsKey(normalized)) {
      return _logoMap[normalized];
    }
    
    // STEP 5: Check for partial matches in our predefined map
    for (final entry in _logoMap.entries) {
      // Check if the normalized input contains the service name
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
      
      // Check if the service name contains the normalized input
      if (entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    
    // STEP 6: Special handling for common services that might be missed
    if (normalized.contains('spotify')) {
      return _directLogos['spotify'];
    }
    
    if (normalized.contains('apple') && normalized.contains('music')) {
      return _directLogos['apple music'];
    }
    
    if (normalized.contains('netflix')) {
      return _directLogos['netflix'];
    }
    
    if (normalized.contains('disney')) {
      return _directLogos['disney+'];
    }
    
    if (normalized.contains('hbo')) {
      return _directLogos['hbo max'];
    }
    
    if (normalized.contains('amazon') || normalized.contains('prime')) {
      return _directLogos['amazon prime'];
    }
    
    // STEP 7: Try to extract domain from website URL
    String? domain = _extractDomain(websiteOrName);
    
    // If we have a domain, try to get logo from various sources
    if (domain != null) {
      // Try Clearbit Logo API first (high quality)
      return 'https://logo.clearbit.com/$domain';
    }
    
    // STEP 8: Try to construct a domain from the name
    final possibleDomain = _constructDomainFromName(normalized);
    if (possibleDomain != null) {
      // Try with constructed domain
      return 'https://logo.clearbit.com/$possibleDomain';
    }
    
    // STEP 9: If all else fails, try Google's favicon service with the name
    return 'https://www.google.com/s2/favicons?domain=$normalized&sz=128';
  }
  
  // Normalize input by removing spaces, special characters, etc.
  String _normalizeInput(String input) {
    return input.toLowerCase().trim();
  }
  
  // Check if two strings match, considering variations
  bool _isMatch(String input, String target) {
    // Direct match
    if (input == target) return true;
    
    // Remove spaces and special characters for comparison
    final cleanInput = input.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanTarget = target.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Check if cleaned strings match
    if (cleanInput == cleanTarget) return true;
    
    // Check if one contains the other
    if (cleanInput.contains(cleanTarget) || cleanTarget.contains(cleanInput)) return true;
    
    return false;
  }
  
  // Generate variations of the input with different separators
  List<String> _generateVariations(String input) {
    final result = <String>[];
    
    // Remove all spaces and special characters
    final cleanInput = input.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    // Common service prefixes to try
    final prefixes = ['', 'apple', 'amazon', 'google', 'microsoft'];
    
    // Common words to split on
    final commonWords = ['plus', 'premium', 'music', 'video', 'tv'];
    
    // Add the clean input
    result.add(cleanInput);
    
    // Try with different separators for common splits
    for (final word in commonWords) {
      if (cleanInput.contains(word)) {
        final parts = cleanInput.split(word);
        if (parts.length > 1) {
          for (final separator in _commonSeparators) {
            result.add('${parts[0]}$separator$word');
            result.add('$word$separator${parts[1]}');
          }
        }
      }
    }
    
    // Try with different prefixes
    for (final prefix in prefixes) {
      if (prefix.isNotEmpty && !cleanInput.startsWith(prefix) && !input.contains(prefix)) {
        for (final separator in _commonSeparators) {
          result.add('$prefix$separator$cleanInput');
        }
      }
    }
    
    return result;
  }
  
  // Get all possible logos for a given input
  List<LogoSuggestion> getLogoSuggestions(String input) {
    if (input.isEmpty) return [];
    
    final suggestions = <LogoSuggestion>[];
    final normalized = _normalizeInput(input);
    final seenUrls = <String>{};
    
    // Function to add a suggestion if the URL hasn't been seen yet
    void addSuggestion(String name, String url) {
      if (!seenUrls.contains(url)) {
        suggestions.add(LogoSuggestion(name: name, logoUrl: url));
        seenUrls.add(url);
      }
    }
    
    // Check direct logos
    for (final entry in _directLogos.entries) {
      if (_isMatch(normalized, entry.key)) {
        addSuggestion(entry.key, entry.value);
      }
    }
    
    // Check aliases
    for (final entry in _serviceAliases.entries) {
      if (_isMatch(normalized, entry.key)) {
        final serviceName = entry.value;
        if (_logoMap.containsKey(serviceName)) {
          addSuggestion(entry.key, _logoMap[serviceName]!);
        }
      }
    }
    
    // Check variations
    final variations = _generateVariations(normalized);
    for (final variation in variations) {
      // Check in direct logos
      for (final entry in _directLogos.entries) {
        if (_isMatch(variation, entry.key)) {
          addSuggestion(entry.key, entry.value);
        }
      }
    }
    
    // Add special handling for common services
    if (normalized.contains('spotify')) {
      addSuggestion('Spotify', _directLogos['spotify']!);
    }
    
    if (normalized.contains('apple')) {
      if (_directLogos.containsKey('apple music')) {
        addSuggestion('Apple Music', _directLogos['apple music']!);
      }
      if (_directLogos.containsKey('apple tv+')) {
        addSuggestion('Apple TV+', _directLogos['apple tv+']!);
      }
    }
    
    if (normalized.contains('disney')) {
      addSuggestion('Disney+', _directLogos['disney+']!);
    }
    
    if (normalized.contains('netflix')) {
      addSuggestion('Netflix', _directLogos['netflix']!);
    }
    
    if (normalized.contains('hbo')) {
      addSuggestion('HBO Max', _directLogos['hbo max']!);
    }
    
    if (normalized.contains('amazon') || normalized.contains('prime')) {
      addSuggestion('Amazon Prime', _directLogos['amazon prime']!);
    }
    
    return suggestions;
  }
  
  // Extract domain from a URL or text
  String? _extractDomain(String text) {
    // Check if it's already a URL
    if (text.startsWith('http://') || text.startsWith('https://')) {
      try {
        final uri = Uri.parse(text);
        return uri.host;
      } catch (e) {
        debugPrint('Error parsing URL: $e');
      }
    }
    
    // Try to guess the domain from the text
    // Remove common prefixes and suffixes
    String normalized = text.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '');
    
    // Common domain extensions
    const extensions = ['.com', '.org', '.net', '.io', '.co', '.app'];
    
    // Try to construct a domain
    for (final ext in extensions) {
      if (normalized.contains(ext)) {
        // Extract the part before the extension
        final parts = normalized.split(ext);
        if (parts.isNotEmpty) {
          // Get the last part before the extension
          String domainName = parts[0];
          
          // Remove any remaining non-alphanumeric characters
          domainName = domainName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          
          // Construct the domain
          return '$domainName$ext';
        }
      }
    }
    
    return null;
  }
  
  // Try to construct a domain name from a service name
  String? _constructDomainFromName(String name) {
    // Remove spaces and special characters
    final normalized = name.toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .trim();
    
    if (normalized.isEmpty) return null;
    
    // Common words to remove from domain names
    final wordsToRemove = ['premium', 'plus', 'subscription', 'service'];
    
    String domainName = normalized;
    for (final word in wordsToRemove) {
      domainName = domainName.replaceAll(word, '');
    }
    
    if (domainName.isEmpty) domainName = normalized;
    
    return '$domainName.com';
  }
  
  // Get a fallback icon based on the first letter of the name
  IconData getFallbackIcon(String name) {
    final firstLetter = name.isNotEmpty ? name[0].toLowerCase() : 'a';
    
    // Map first letter to different icons
    switch (firstLetter) {
      case 'a':
      case 'b':
      case 'c':
        return Icons.subscriptions_rounded;
      case 'd':
      case 'e':
      case 'f':
        return Icons.movie_rounded;
      case 'g':
      case 'h':
      case 'i':
        return Icons.music_note_rounded;
      case 'j':
      case 'k':
      case 'l':
        return Icons.games_rounded;
      case 'm':
      case 'n':
      case 'o':
        return Icons.cloud_rounded;
      case 'p':
      case 'q':
      case 'r':
        return Icons.book_rounded;
      case 's':
      case 't':
      case 'u':
        return Icons.shopping_cart_rounded;
      case 'v':
      case 'w':
      case 'x':
      case 'y':
      case 'z':
        return Icons.sports_esports_rounded;
      default:
        return Icons.subscriptions_rounded;
    }
  }
}

// Class to represent a logo suggestion
class LogoSuggestion {
  final String name;
  final String logoUrl;
  
  LogoSuggestion({required this.name, required this.logoUrl});
} 