import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:subtrackr/data/services/logo_service.dart';

/// Widget for selecting and displaying subscription logo
class LogoSelector extends StatelessWidget {
  final String? logoUrl;
  final String serviceName;
  final VoidCallback onRemoveLogo;
  final VoidCallback onSearchLogo;
  final Function(String) onSelectLogo;
  final List<LogoSuggestion> suggestions;
  final bool showSuggestions;

  const LogoSelector({
    super.key,
    required this.logoUrl,
    required this.serviceName,
    required this.onRemoveLogo,
    required this.onSearchLogo,
    required this.onSelectLogo,
    required this.suggestions,
    required this.showSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logoService = Provider.of<LogoService>(context, listen: false);
    
    return Column(
      children: [
        // Logo preview
        if (logoUrl != null)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Hero(
                tag: 'no_hero_animation',
                flightShuttleBuilder: (_, __, ___, ____, _____) => 
                  const SizedBox.shrink(),
                child: Image.network(
                  logoUrl!,
                  key: const ValueKey('add_subscription_logo_image'),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: colorScheme.primary,
                      child: Icon(
                        logoService.getFallbackIcon(serviceName),
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Logo action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (logoUrl != null)
              OutlinedButton.icon(
                onPressed: onRemoveLogo,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove Logo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: colorScheme.primary),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: onSearchLogo,
                icon: const Icon(Icons.image_search),
                label: const Text('Find Logo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
          ],
        ),
        
        // Logo suggestions
        if (showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Suggested Logos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => onSelectLogo(suggestion.logoUrl),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Hero(
                              tag: 'no_hero_animation_suggestion_${suggestion.name}',
                              child: Image.network(
                                suggestion.logoUrl,
                                key: ValueKey('logo_suggestion_${suggestion.name}'),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: colorScheme.primary,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Logo suggestion model
class LogoSuggestion {
  final String name;
  final String logoUrl;

  LogoSuggestion({
    required this.name,
    required this.logoUrl,
  });
} 