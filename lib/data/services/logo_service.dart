import 'package:flutter/material.dart';

class LogoService {
  static final LogoService _instance = LogoService._internal();
  
  factory LogoService() {
    return _instance;
  }
  
  LogoService._internal();
  
  // Minimal hardcoded mappings for services where domain construction is tricky
  final Map<String, String> _specialCases = {
    'cursor': 'assets/logos/cursor-logo.png',
    // Services with non-obvious domains
    'disney+': 'disneyplus.com',
    'disney plus': 'disneyplus.com',
    'disneyplus': 'disneyplus.com',
    'disney': 'disney.com',
    'hbo max': 'hbomax.com',
    'hbomax': 'hbomax.com',
    'apple tv+': 'tv.apple.com',
    'apple tv plus': 'tv.apple.com',
    'paramount+': 'paramountplus.com',
    'paramount plus': 'paramountplus.com',
    'youtube premium': 'youtube.com',
    'youtube music': 'music.youtube.com',
    'apple music': 'music.apple.com',
    'amazon prime': 'primevideo.com',
    'prime video': 'primevideo.com',
    'amazon music': 'music.amazon.com',
    // Apple Services - use direct logo URLs since Clearbit returns generic Apple logo
    'apple music': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Apple_Music_icon.svg/512px-Apple_Music_icon.svg.png',
    'apple tv+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Apple_TV_Plus_logo.svg/512px-Apple_TV_Plus_logo.svg.png',
    'apple tv plus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/28/Apple_TV_Plus_logo.svg/512px-Apple_TV_Plus_logo.svg.png',
    'apple arcade': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Apple_Arcade_logo.svg/512px-Apple_Arcade_logo.svg.png',
    'apple news+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Apple_News_icon.svg/512px-Apple_News_icon.svg.png',
    'apple news plus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9c/Apple_News_icon.svg/512px-Apple_News_icon.svg.png',
    'apple fitness+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Apple_Fitness%2B_logo.svg/512px-Apple_Fitness%2B_logo.svg.png',
    'apple fitness plus': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Apple_Fitness%2B_logo.svg/512px-Apple_Fitness%2B_logo.svg.png',
    'icloud': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/ICloud_logo.svg/512px-ICloud_logo.svg.png',
    'icloud+': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/ICloud_logo.svg/512px-ICloud_logo.svg.png',
    'apple one': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/512px-Apple_logo_black.svg.png',
    // AI Services
    'chatgpt': 'openai.com',
    'chat gpt': 'openai.com',
    'openai': 'openai.com',
    'claude': 'anthropic.com',
    'anthropic': 'anthropic.com',
  };
  
  // Related services mapping for better suggestions
  final Map<String, List<String>> _relatedServices = {
    'disney': ['disney+', 'disney plus', 'disney'],
    'apple': ['apple music', 'apple tv+', 'apple arcade', 'apple news+', 'apple fitness+', 'icloud', 'apple one'],
    'youtube': ['youtube premium', 'youtube music', 'youtube tv'],
    'amazon': ['amazon prime', 'amazon music', 'prime video'],
    'google': ['youtube', 'google drive', 'google one'],
    'microsoft': ['microsoft 365', 'xbox game pass', 'outlook'],
    'hbo': ['hbo max', 'hbo'],
    'paramount': ['paramount+', 'paramount plus'],
    'openai': ['openai', 'chatgpt', 'chat gpt'],
    'anthropic': ['anthropic', 'claude'],
    'ai': ['openai', 'anthropic', 'chatgpt', 'claude'],
  };
  
  // Get logo URL from website URL or name
  String? getLogoUrl(String? websiteOrName) {
    if (websiteOrName == null || websiteOrName.isEmpty) {
      return null;
    }
    
    // Normalize the input (lowercase, remove extra spaces)
    final normalized = _normalizeInput(websiteOrName);
    
    // Special case for local assets
    if (normalized == 'cursor') {
      return 'assets/logos/cursor-logo.png';
    }
    
    // Check if we have a special case mapping FIRST (highest priority)
    for (final entry in _specialCases.entries) {
      if (_isServiceMatch(normalized, entry.key)) {
        final logoUrl = entry.value;
        if (logoUrl.startsWith('assets/')) {
          return logoUrl;
        }
        if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
          return logoUrl;
        }
        return 'https://logo.clearbit.com/$logoUrl';
      }
    }
    
    // Try to extract domain from website URL
    String? domain = _extractDomain(websiteOrName);
    
    // If we have a domain, use Clearbit API
    if (domain != null) {
      return 'https://logo.clearbit.com/$domain';
    }
    
    // Try to construct a domain from the name
    final possibleDomain = _constructDomainFromName(normalized);
    if (possibleDomain != null) {
      return 'https://logo.clearbit.com/$possibleDomain';
    }
    
    // Final fallback - try Google's favicon service
    return 'https://www.google.com/s2/favicons?domain=$normalized&sz=128';
  }
  
  // Normalize input by removing spaces, special characters, etc.
  String _normalizeInput(String input) {
    return input.toLowerCase().trim();
  }
  
  // Check if two service names match (handles typos and partial matches)
  bool _isServiceMatch(String input, String serviceName) {
    // Direct match - highest priority
    if (input == serviceName) return true;
    
    // Handle common typos and variations
    final cleanInput = input.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanService = serviceName.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    if (cleanInput == cleanService) return true;
    
    // Handle specific typos and variations
    if ((input.contains('cluade') || input.contains('claud')) && serviceName.contains('claude')) return true;
    if ((input.contains('chatgpt') || input.contains('chat gpt') || input.contains('gpt')) && 
        (serviceName.contains('chatgpt') || serviceName.contains('openai'))) return true;
    if (input.contains('anthropic') && serviceName.contains('claude')) return true;
    if (input.contains('claude') && serviceName.contains('anthropic')) return true;
    
    // Exact service name matches for Apple services (to prevent "apple" matching all apple services)
    if (serviceName.startsWith('apple ')) {
      return input == serviceName || cleanInput == cleanService;
    }
    
    // Check if one contains the other (but only for shorter strings to avoid false matches)
    if (input.length <= 5 || serviceName.length <= 5) {
      return input.contains(serviceName) || serviceName.contains(input);
    }
    
    // More precise matching for longer strings
    return cleanInput.contains(cleanService) || cleanService.contains(cleanInput);
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
  
  // Get logo suggestions with support for multiple related services
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
    
    // Special case for Cursor - return local asset
    if (normalized.contains('cursor')) {
      addSuggestion('Cursor', 'assets/logos/cursor-logo.png');
      return suggestions;
    }
    
    // Check for exact matches first
    final exactLogoUrl = getLogoUrl(normalized);
    if (exactLogoUrl != null) {
      addSuggestion(_capitalizeServiceName(normalized), exactLogoUrl);
    }
    
    // Check for partial matches in special cases (do this before related services)
    for (final entry in _specialCases.entries) {
      final serviceName = entry.key;
      // Check if input matches the service name (handle typos and partial matches)
      if (_isServiceMatch(normalized, serviceName)) {
        final logoUrl = getLogoUrl(serviceName);
        if (logoUrl != null) {
          addSuggestion(_capitalizeServiceName(serviceName), logoUrl);
        }
      }
    }
    
    // Check for related services when typing partial matches
    for (final entry in _relatedServices.entries) {
      final serviceFamily = entry.key;
      final relatedServices = entry.value;
      
      // If the input matches or is contained in the service family name
      if (_isServiceMatch(normalized, serviceFamily)) {
        for (final relatedService in relatedServices) {
          final logoUrl = getLogoUrl(relatedService);
          if (logoUrl != null) {
            addSuggestion(_capitalizeServiceName(relatedService), logoUrl);
          }
        }
      }
    }
    
    // If no suggestions found, try the original input
    if (suggestions.isEmpty) {
      final fallbackUrl = getLogoUrl(input);
      if (fallbackUrl != null) {
        addSuggestion(_capitalizeServiceName(input), fallbackUrl);
      }
    }
    
    // Limit to 5 suggestions to avoid overwhelming the UI
    return suggestions.take(5).toList();
  }
  
  // Helper method to capitalize service names for display
  String _capitalizeServiceName(String name) {
    if (name.isEmpty) return name;
    
    // Handle special cases
    switch (name.toLowerCase()) {
      case 'disney+':
      case 'disney plus':
        return 'Disney+';
      case 'hbo max':
        return 'HBO Max';
      case 'apple tv+':
      case 'apple tv plus':
        return 'Apple TV+';
      case 'paramount+':
      case 'paramount plus':
        return 'Paramount+';
      case 'youtube premium':
        return 'YouTube Premium';
      case 'youtube music':
        return 'YouTube Music';
      case 'apple music':
        return 'Apple Music';
      case 'amazon prime':
        return 'Amazon Prime';
      case 'prime video':
        return 'Prime Video';
      case 'amazon music':
        return 'Amazon Music';
      case 'chatgpt':
      case 'chat gpt':
        return 'ChatGPT';
      case 'openai':
        return 'OpenAI';
      case 'claude':
        return 'Claude';
      case 'anthropic':
        return 'Anthropic';
      default:
        // Capitalize first letter of each word
        return name.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
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