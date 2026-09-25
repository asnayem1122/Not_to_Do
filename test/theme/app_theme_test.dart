import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do/core/theme/app_theme.dart';
import 'package:not_to_do/core/theme/app_colors.dart';

void main() {
  testWidgets('AppTheme extensions and critical colors are valid', (tester) async {
    final lightExtension = AppTheme.lightTheme.extension<AppCustomColors>();
    final darkExtension = AppTheme.darkTheme.extension<AppCustomColors>();

    expect(lightExtension, isNotNull);
    expect(darkExtension, isNotNull);

    // Check non-null critical colors
    expect(lightExtension!.primaryAccent, isNotNull);
    expect(lightExtension.cardBackground, isNotNull);
    expect(lightExtension.textPrimary, isNotNull);

    expect(darkExtension!.primaryAccent, isNotNull);
    expect(darkExtension.cardBackground, isNotNull);
    expect(darkExtension.textPrimary, isNotNull);

    // Light vs Dark should differ (or at least be properly instantiated)
    // Note: If both themes share the same primaryAccent, we don't strictly assert difference on it,
    // but backgrounds and text colors should definitely differ.
    expect(lightExtension.cardBackground != darkExtension.cardBackground, isTrue);
    expect(lightExtension.textPrimary != darkExtension.textPrimary, isTrue);
    expect(lightExtension.canvasBackground != darkExtension.canvasBackground, isTrue);
  });
}
