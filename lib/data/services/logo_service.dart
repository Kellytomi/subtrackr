import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:subtrackr/core/config/brandfetch_config.dart';

class LogoService {
  static final LogoService _instance = LogoService._internal();
  
  factory LogoService() {
    return _instance;
  }
  
  LogoService._internal();
  

  
  // No local assets - everything uses Brandfetch now
  final Map<String, String> _localAssets = {};
  
  // Special domain mappings for services that don't use .com
  final Map<String, String> _domainMappings = {
    'claude': 'claude.ai',
    'anthropic': 'anthropic.com',
    'chatgpt': 'openai.com',
    'openai': 'openai.com',
    'notion': 'notion.so',
    'figma': 'figma.com',
    'canva': 'canva.com',
    'discord': 'discord.com',
    'reddit': 'reddit.com',
    'twitter': 'twitter.com',
    'x': 'x.com',
    'instagram': 'instagram.com',
    'facebook': 'facebook.com',
    'linkedin': 'linkedin.com',
    'tiktok': 'tiktok.com',
    'snapchat': 'snapchat.com',
    'whatsapp': 'whatsapp.com',
    'telegram': 'telegram.org',
    'cursor': 'cursor.sh',
  };
  

  
  // Get logo URL from website URL or name
  String? getLogoUrl(String? websiteOrName) {
    if (websiteOrName == null || websiteOrName.isEmpty) {
      return null;
    }
    
    // Normalize the input (lowercase, remove extra spaces)
    final normalized = _normalizeInput(websiteOrName);
    
    // Check for local assets first
    if (_localAssets.containsKey(normalized)) {
      return _localAssets[normalized];
    }
    
    // Check for special domain mappings
    if (_domainMappings.containsKey(normalized)) {
      return _getBrandfetchUrl(_domainMappings[normalized]!);
    }
    
    // Try to extract domain from website URL
    String? domain = _extractDomain(websiteOrName);
    
    // If we have a domain, use Brandfetch API
    if (domain != null) {
      return _getBrandfetchUrl(domain);
    }
    
    // Try to construct a domain from the name
    final possibleDomain = _constructDomainFromName(normalized);
    if (possibleDomain != null) {
      return _getBrandfetchUrl(possibleDomain);
    }
    
    // Final fallback - try Google's favicon service
    return 'https://www.google.com/s2/favicons?domain=$normalized&sz=128';
  }
  
  // Normalize input by removing spaces, special characters, etc.
  String _normalizeInput(String input) {
    return input.toLowerCase().trim();
  }
  
  // Simple service name matching
  bool _isServiceMatch(String input, String serviceName) {
    return input == serviceName;
  }
  
  // Get Brandfetch URL with proper client ID parameter
  String _getBrandfetchUrl(String domain) {
    if (!BrandfetchConfig.isConfigured) {
      // Fallback to simple format for testing (may not work optimally)
      debugPrint('⚠️ Please get your free Brandfetch client ID from: ${BrandfetchConfig.registrationUrl}');
      return 'https://cdn.brandfetch.io/$domain';
    }
    return 'https://cdn.brandfetch.io/$domain?c=${BrandfetchConfig.clientId}';
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
  
  // Get logo suggestions using Brandfetch Brand Search API
  Future<List<LogoSuggestion>> getLogoSuggestions(String input) async {
    if (input.isEmpty) return [];
    
    // Try Brandfetch Brand Search API first
    final apiSuggestions = await _searchBrandsApi(input);
    if (apiSuggestions.isNotEmpty) {
      return apiSuggestions;
    }
    
    // Fallback to original logic if API fails
    return _getLogoSuggestionsLocal(input);
  }
  
  // Search brands using Brandfetch Brand Search API
  Future<List<LogoSuggestion>> _searchBrandsApi(String query) async {
    if (!BrandfetchConfig.isConfigured) {
      debugPrint('⚠️ Brandfetch client ID not configured, using fallback suggestions');
      return [];
    }
    
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://api.brandfetch.io/v2/search/$encodedQuery?c=${BrandfetchConfig.clientId}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        final suggestions = <LogoSuggestion>[];
        
        if (jsonData is List) {
          for (final result in jsonData.take(8)) {
            final name = result['name']?.toString();
            final iconUrl = result['icon']?.toString();
            
            if (name != null && iconUrl != null) {
              suggestions.add(LogoSuggestion(name: name, logoUrl: iconUrl));
            }
          }
        }
        
        return suggestions;
      } else {
        debugPrint('Brandfetch API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling Brandfetch API: $e');
    }
    
    return [];
  }
  
  // Fallback logo suggestions with local logic
  List<LogoSuggestion> _getLogoSuggestionsLocal(String input) {
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
    
    // Generate multiple suggestions based on input
    final commonServices = _getCommonServiceVariations(normalized);
    
    // Add exact match first
    final exactLogoUrl = getLogoUrl(normalized);
    if (exactLogoUrl != null) {
      addSuggestion(_capitalizeServiceName(normalized), exactLogoUrl);
    }
    
    // Add common service variations
    for (final serviceName in commonServices) {
      final logoUrl = getLogoUrl(serviceName);
      if (logoUrl != null) {
        addSuggestion(_capitalizeServiceName(serviceName), logoUrl);
      }
    }
    
    // Add domain-based suggestions
    final possibleDomains = _generateDomainVariations(normalized);
    for (final domain in possibleDomains) {
      final logoUrl = _getBrandfetchUrl(domain);
      final displayName = domain.replaceAll(RegExp(r'\.(com|ai|so|sh|org)$'), '');
      addSuggestion(_capitalizeServiceName(displayName), logoUrl);
    }
    
    // Limit to 8 suggestions for better variety
    return suggestions.take(8).toList();
  }
  
  // Helper method to capitalize service names for display
  String _capitalizeServiceName(String name) {
    if (name.isEmpty) return name;
    
    // Capitalize first letter of each word
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  // Generate common service variations for better suggestions
  List<String> _getCommonServiceVariations(String input) {
    final variations = <String>[];
    
    // Common service patterns
    final patterns = {
      'spot': ['spotify'],
      'net': ['netflix'],
      'dis': ['disney+', 'disney plus'],
      'app': ['apple music', 'apple tv+', 'apple arcade'],
      'you': ['youtube', 'youtube premium', 'youtube music'],
      'ama': ['amazon prime', 'amazon music'],
      'hbo': ['hbo max'],
      'par': ['paramount+'],
      'chat': ['chatgpt'],
      'gpt': ['chatgpt'],
      'open': ['openai'],
      'clau': ['claude'],
      'ant': ['anthropic'],
      'twi': ['twitch'],
      'tik': ['tiktok'],
      'ins': ['instagram'],
      'face': ['facebook'],
      'lin': ['linkedin'],
      'mic': ['microsoft 365'],
      'goo': ['google drive', 'google one'],
      'dro': ['dropbox'],
      'not': ['notion'],
      'sla': ['slack'],
      'zoo': ['zoom'],
      'can': ['canva'],
      'fig': ['figma'],
    };
    
    // Find matching patterns
    for (final entry in patterns.entries) {
      if (input.contains(entry.key)) {
        variations.addAll(entry.value);
      }
    }
    
    return variations;
  }
  
  // Generate domain variations for suggestions
  List<String> _generateDomainVariations(String input) {
    final domains = <String>[];
    
    // Common domain patterns
    domains.add('$input.com');
    domains.add('$input.io');
    domains.add('$input.app');
    
    // Handle special cases
    if (input.contains('plus') || input.contains('+')) {
      final baseName = input.replaceAll('plus', '').replaceAll('+', '').trim();
      domains.add('${baseName}plus.com');
      domains.add('$baseName.com');
    }
    
    // Remove duplicates
    return domains.toSet().toList();
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