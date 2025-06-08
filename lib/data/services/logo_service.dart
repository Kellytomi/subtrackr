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
    
    // Check if we have a special case mapping
    if (_specialCases.containsKey(normalized)) {
      final domain = _specialCases[normalized]!;
      if (domain.startsWith('assets/')) {
        return domain;
      }
      return 'https://logo.clearbit.com/$domain';
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
  
  // Get logo suggestions (simplified - just returns the main result)
  List<LogoSuggestion> getLogoSuggestions(String input) {
    if (input.isEmpty) return [];
    
    final logoUrl = getLogoUrl(input);
    if (logoUrl != null) {
      return [LogoSuggestion(name: input, logoUrl: logoUrl)];
    }
    
    return [];
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