import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:llm_in_fabula/models/game_theme.dart';
import 'package:provider/provider.dart';

/// Widget that displays themed role name
class ThemedRoleName extends StatelessWidget {
  final String baseRole;
  final TextStyle? style;
  
  const ThemedRoleName({
    super.key,
    required this.baseRole,
    this.style,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<GameState>().theme;
    return Text(
      theme.getRoleName(baseRole),
      style: style,
    );
  }
}

/// Widget that displays themed role icon (supports custom image icons)
class ThemedRoleIcon extends StatelessWidget {
  final String baseRole;
  final double? size;
  final Color? color;
  final GameTheme? themeOverride;
  
  const ThemedRoleIcon({
    super.key,
    required this.baseRole,
    this.size,
    this.color,
    this.themeOverride,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = themeOverride ?? context.watch<GameState>().theme;
    final element = theme.roles[baseRole];
    
    if (element == null) {
      return Icon(Icons.circle, size: size, color: color);
    }
    
    // Use custom icon if available
    if (element.usesCustomIcon && element.customIconPath != null) {
      return Image.asset(
        element.customIconPath!,
        width: size,
        height: size,
        color: color,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to material icon if image fails to load
          return Icon(element.icon, size: size, color: color);
        },
      );
    }
    
    // Use material icon
    return Icon(element.icon, size: size, color: color);
  }
}

/// Helper extension to get themed values from context
extension ThemeContext on BuildContext {
  /// Get themed role name
  String themedRole(String baseRole) {
    return read<GameState>().theme.getRoleName(baseRole);
  }
  
  /// Get themed role icon
  IconData themedRoleIcon(String baseRole) {
    return read<GameState>().theme.getRoleIcon(baseRole);
  }
}
