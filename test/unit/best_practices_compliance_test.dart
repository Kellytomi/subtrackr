import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Best Practices Compliance Tests', () {
    test('all dart files should follow snake_case naming convention', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .where((file) => file.path.endsWith('.dart'))
          .map((file) => file.path.split('/').last);

      for (final fileName in dartFiles) {
        // Skip generated files
        if (fileName.endsWith('.g.dart')) continue;
        
        // Check snake_case (allowing dots for extensions)
        final fileNameWithoutExtension = fileName.replaceAll('.dart', '');
        expect(
          fileNameWithoutExtension,
          matches(RegExp(r'^[a-z][a-z0-9_]*$')),
          reason: 'File $fileName should use snake_case naming',
        );
      }
    });

    test('widget build methods should be reasonably sized', () async {
      final homeScreenFile = File('lib/presentation/screens/home_screen.dart');
      final content = await homeScreenFile.readAsString();
      
      // Find build method
      final buildMethodMatch = RegExp(
        r'@override\s+Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*{',
        multiLine: true,
      ).firstMatch(content);
      
      if (buildMethodMatch != null) {
        final startIndex = buildMethodMatch.end;
        int braceCount = 1;
        int endIndex = startIndex;
        
        // Find the closing brace of build method
        while (braceCount > 0 && endIndex < content.length) {
          if (content[endIndex] == '{') braceCount++;
          if (content[endIndex] == '}') braceCount--;
          endIndex++;
        }
        
        final buildMethodContent = content.substring(startIndex, endIndex - 1);
        final lineCount = buildMethodContent.split('\n').length;
        
        // After refactoring, build method should be under 50 lines
        expect(
          lineCount,
          lessThan(50),
          reason: 'Build method in home_screen.dart should be under 50 lines (found $lineCount lines)',
        );
      }
    });

    test('constants should use SCREAMING_SNAKE_CASE', () async {
      final constantsFile = File('lib/core/constants/app_constants.dart');
      final content = await constantsFile.readAsString();
      
      // Find all static const declarations
      final constantMatches = RegExp(
        r'static\s+const\s+\w+\s+(\w+)\s*=',
        multiLine: true,
      ).allMatches(content);
      
      for (final match in constantMatches) {
        final constantName = match.group(1)!;
        expect(
          constantName,
          matches(RegExp(r'^[A-Z][A-Z0-9_]*$')),
          reason: 'Constant $constantName should use SCREAMING_SNAKE_CASE',
        );
      }
    });

    test('project structure should follow recommended pattern', () {
      // Check required directories exist
      final requiredDirs = [
        'lib/core',
        'lib/core/constants',
        'lib/core/theme',
        'lib/core/utils',
        'lib/data',
        'lib/data/models',
        'lib/data/repositories',
        'lib/data/services',
        'lib/presentation',
        'lib/presentation/screens',
        'lib/presentation/widgets',
      ];
      
      for (final dirPath in requiredDirs) {
        final dir = Directory(dirPath);
        expect(
          dir.existsSync(),
          isTrue,
          reason: 'Directory $dirPath should exist',
        );
      }
    });

    test('extracted widgets should exist for better code organization', () {
      // Check that we have extracted widget directories
      final widgetDirs = [
        'lib/presentation/widgets/home',
        'lib/presentation/widgets/add_subscription',
        'lib/presentation/widgets/settings',
      ];
      
      for (final dirPath in widgetDirs) {
        final dir = Directory(dirPath);
        expect(
          dir.existsSync(),
          isTrue,
          reason: 'Widget directory $dirPath should exist for extracted components',
        );
        
        // Verify directory has widgets
        final widgets = dir.listSync().where((f) => f.path.endsWith('.dart'));
        expect(
          widgets.isNotEmpty,
          isTrue,
          reason: 'Directory $dirPath should contain widget files',
        );
      }
    });
  });
} 