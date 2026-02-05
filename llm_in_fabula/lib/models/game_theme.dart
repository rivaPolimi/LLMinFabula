import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Lookup from material icon string to IconData (fallback if icons.json misses one).
const Map<String, IconData> _materialIconLookup = {
  'person': Icons.person,
  'pets': Icons.pets,
  'visibility': Icons.visibility,
  'architecture': Icons.architecture,
  'science': Icons.science,
  'shield': Icons.shield,
  'favorite': Icons.favorite,
  'dangerous': Icons.dangerous,
  'radar': Icons.radar,
  'security': Icons.security,
  'medical_services': Icons.medical_services,
  'engineering': Icons.engineering,
  'rocket_launch': Icons.rocket_launch,
  'assignment': Icons.assignment,
  'badge': Icons.badge,
  'campaign': Icons.campaign,
  'exit_to_app': Icons.exit_to_app,
  'power_off': Icons.power_off,
  'lightbulb': Icons.lightbulb,
  'work': Icons.work,
  'home': Icons.home,
  'menu_book': Icons.menu_book,
  'forum': Icons.forum,
  'how_to_vote': Icons.how_to_vote,
  'nightlight': Icons.nightlight,
  'wb_sunny': Icons.wb_sunny,
  'dark_mode': Icons.dark_mode,
  'circle': Icons.circle,
  'church': Icons.church,
  'block': Icons.block,
};

/// Icon definition loaded from icons.json
class IconDefinition {
  final String materialName;
  final IconData iconData;
  final String? customPath;

  const IconDefinition({
    required this.materialName,
    required this.iconData,
    this.customPath,
  });
}

/// Map populated from assets/icons.json (icon key -> definition)
final Map<String, IconDefinition> _iconMap = {};

/// Represents a themed version of game elements (roles, phases, etc.)
class GameTheme {
  final String settingName;
  final Map<String, ThemeElement> roles;
  final String? eliminatedIcon; // Icon shown when player is eliminated
  
  const GameTheme({
    required this.settingName,
    required this.roles,
    this.eliminatedIcon,
  });
  
  /// Get themed name for a role
  String getRoleName(String baseRole) => roles[baseRole]?.name ?? baseRole;
  
  /// Get themed icon for a role
  IconData getRoleIcon(String baseRole) => roles[baseRole]?.icon ?? Icons.person;

  /// Create GameTheme from JSON
  factory GameTheme.fromJson(Map<String, dynamic> json) {
    return GameTheme(
      settingName: json['settingName'] as String,
      roles: (json['roles'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, ThemeElement.fromJson(value)),
      ),
      eliminatedIcon: json['eliminated_icon'] as String?,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'settingName': settingName,
      'roles': roles.map((key, value) => MapEntry(key, value.toJson())),
      if (eliminatedIcon != null) 'eliminated_icon': eliminatedIcon,
    };
  }
  
  /// Get the icon to show for eliminated players
  IconData getEliminatedIcon() {
    if (eliminatedIcon == null) return Icons.person;
    final def = _iconMap[eliminatedIcon];
    return def?.iconData ?? Icons.person;
  }
}

/// Represents a themed element (name + icon)
class ThemeElement {
  final String name;
  final IconData icon;
  final String iconName; // For material icons
  final String? customIconPath; // For custom image icons (PNG, SVG, etc.)
  
  const ThemeElement({
    required this.name,
    required this.icon,
    String? iconName,
    this.customIconPath,
  }) : iconName = iconName ?? 'circle';
  
  /// Check if this element uses a custom icon
  bool get usesCustomIcon => customIconPath != null;
  
  /// Create ThemeElement from JSON
  factory ThemeElement.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final icon = json['icon'];

    if (icon is String) {
      final def = _iconMap[icon];
      final fallbackIcon = _materialIconLookup[def?.materialName ?? icon] ?? Icons.circle;
      return ThemeElement(
        name: name,
        icon: def?.iconData ?? fallbackIcon,
        iconName: icon,
        customIconPath: def?.customPath,
      );
    } else if (icon is Map<String, dynamic>) {
      final materialIconName = icon['material'] as String? ?? 'circle';
      final customPath = icon['custom'] as String?;
      return ThemeElement(
        name: name,
        icon: _materialIconLookup[materialIconName] ?? Icons.circle,
        iconName: materialIconName,
        customIconPath: customPath,
      );
    }

    return ThemeElement(
      name: name,
      icon: Icons.circle,
      iconName: 'circle',
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    if (customIconPath != null) {
      return {
        'name': name,
        'icon': {
          'material': iconName,
          'custom': customIconPath,
        },
      };
    }
    return {
      'name': name,
      'icon': iconName,
    };
  }
}

/// Available game themes/settings
class GameThemes {
  static final Map<String, GameTheme> _loadedThemes = {};
  static bool _initialized = false;

  /// Load the icon registry from icons.json. Icons are referred by name in themes.json.
  static Future<void> loadIconMapFromJson(String assetPath) async {
    _iconMap.clear();
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final iconsJson = jsonData['icons'];

      if (iconsJson is Map<String, dynamic>) {
        iconsJson.forEach((iconKey, value) {
          if (value is! Map<String, dynamic>) return;

          final materialName = value['material'] as String? ?? 'circle';
          final customPath = value['custom'] as String?;
          final iconData = _materialIconLookup[materialName] ?? Icons.circle;

          _iconMap[iconKey] = IconDefinition(
            materialName: materialName,
            iconData: iconData,
            customPath: customPath,
          );
        });
      }

      // If nothing was loaded, seed with defaults to avoid empty map usage.
      if (_iconMap.isEmpty) {
        _materialIconLookup.forEach((name, data) {
          _iconMap[name] = IconDefinition(materialName: name, iconData: data);
        });
        debugPrint('⚠️ icons.json empty or invalid; using material icon defaults');
      } else {
        debugPrint('✅ Loaded ${_iconMap.length} icons from $assetPath');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load icons from $assetPath: $e');
      if (_iconMap.isEmpty) {
        _materialIconLookup.forEach((name, data) {
          _iconMap[name] = IconDefinition(materialName: name, iconData: data);
        });
        debugPrint('ℹ️ Using material icon defaults');
      }
    }
  }
  
  // Fallback themes (used if JSON loading fails or during development)
  static final GameTheme medieval = GameTheme(
    settingName: 'medieval',
    roles: {
      'villager': ThemeElement(name: 'Villager', icon: Icons.person, iconName: 'person'),
      'werewolf': ThemeElement(name: 'Werewolf', icon: Icons.pets, iconName: 'pets'),
      'seer': ThemeElement(name: 'Seer', icon: Icons.visibility, iconName: 'visibility'),
      'hunter': ThemeElement(name: 'Hunter', icon: Icons.architecture, iconName: 'architecture'),
      'witch': ThemeElement(name: 'Witch', icon: Icons.science, iconName: 'science'),
      'guard': ThemeElement(name: 'Guard', icon: Icons.shield, iconName: 'shield'),
      'cupid': ThemeElement(name: 'Cupid', icon: Icons.favorite, iconName: 'favorite'),
    },
  );
  
  static final GameTheme space = GameTheme(
    settingName: 'space',
    roles: {
      'villager': ThemeElement(name: 'Crewmate', icon: Icons.person, iconName: 'person'),
      'werewolf': ThemeElement(name: 'Impostor', icon: Icons.dangerous, iconName: 'dangerous'),
      'seer': ThemeElement(name: 'Scanner', icon: Icons.radar, iconName: 'radar'),
      'hunter': ThemeElement(name: 'Security', icon: Icons.security, iconName: 'security'),
      'witch': ThemeElement(name: 'Medic', icon: Icons.medical_services, iconName: 'medical_services'),
      'guard': ThemeElement(name: 'Engineer', icon: Icons.engineering, iconName: 'engineering'),
      'cupid': ThemeElement(name: 'Matchmaker', icon: Icons.favorite, iconName: 'favorite'),
    },
  );
  
  /// Load themes from JSON file in assets
  static Future<void> loadThemesFromJson(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final themes = jsonData['themes'] as List;
      for (final themeJson in themes) {
        final theme = GameTheme.fromJson(themeJson);
        _loadedThemes[theme.settingName.toLowerCase()] = theme;
      }
      
      _initialized = true;
      debugPrint('✅ Loaded ${_loadedThemes.length} themes from $assetPath');
    } catch (e) {
      debugPrint('⚠️ Failed to load themes from JSON: $e');
      debugPrint('Using fallback hardcoded themes');
      _initializeFallbackThemes();
    }
  }
  
  /// Initialize with fallback themes
  static void _initializeFallbackThemes() {
    _loadedThemes['medieval'] = medieval;
    _loadedThemes['space'] = space;
    _initialized = true;
  }
  
  /// Get theme by setting name
  static GameTheme getTheme(String settingName) {
    if (!_initialized) {
      _initializeFallbackThemes();
    }
    
    return _loadedThemes[settingName.toLowerCase()] ?? medieval;
  }
  
  /// List of all available theme names
  static List<String> get availableThemes {
    if (!_initialized) {
      _initializeFallbackThemes();
    }
    return _loadedThemes.keys.toList();
  }
  
  /// Get all loaded themes
  static List<GameTheme> get all {
    if (!_initialized) {
      _initializeFallbackThemes();
    }
    return _loadedThemes.values.toList();
  }
}
