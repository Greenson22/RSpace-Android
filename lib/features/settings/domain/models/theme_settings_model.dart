// lib/features/settings/domain/models/theme_settings_model.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/theme/app_theme.dart';

class ThemeSettings {
  final bool isDarkMode;
  final bool isChristmasTheme;
  final bool isUnderwaterTheme;
  final int primaryColorValue;
  final List<int> recentColorValues;
  final double dashboardItemScale;
  final bool showFloatingCharacter;
  final bool showQuickFab;
  final String quickFabIcon;
  final double quickFabBgOpacity;
  final double quickFabOverallOpacity;
  final double quickFabSize;
  final bool fabMenuShowText;
  final bool openInAppBrowser;
  final String? htmlEditorTheme;
  // ==> PROPERTI BARU <==
  final String defaultNoteIcon;

  ThemeSettings({
    this.isDarkMode = false,
    this.isChristmasTheme = false,
    this.isUnderwaterTheme = false,
    required this.primaryColorValue,
    this.recentColorValues = const [],
    this.dashboardItemScale = 1.0,
    this.showFloatingCharacter = true,
    this.showQuickFab = true,
    this.quickFabIcon = '➕',
    this.quickFabBgOpacity = 1.0,
    this.quickFabOverallOpacity = 1.0,
    this.quickFabSize = 56.0,
    this.fabMenuShowText = true,
    this.openInAppBrowser = true,
    this.htmlEditorTheme,
    // ==> TAMBAHKAN DI KONSTRUKTOR <==
    this.defaultNoteIcon = '🗒️',
  });

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      isChristmasTheme: json['isChristmasTheme'] as bool? ?? false,
      isUnderwaterTheme: json['isUnderwaterTheme'] as bool? ?? false,
      primaryColorValue:
          json['primaryColorValue'] as int? ??
          AppTheme.selectableColors.first.value,
      recentColorValues:
          (json['recentColorValues'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      dashboardItemScale:
          (json['dashboardItemScale'] as num?)?.toDouble() ?? 1.0,
      showFloatingCharacter: json['showFloatingCharacter'] as bool? ?? true,
      showQuickFab: json['showQuickFab'] as bool? ?? true,
      quickFabIcon: json['quickFabIcon'] as String? ?? '➕',
      quickFabBgOpacity: (json['quickFabBgOpacity'] as num?)?.toDouble() ?? 1.0,
      quickFabOverallOpacity:
          (json['quickFabOverallOpacity'] as num?)?.toDouble() ?? 1.0,
      quickFabSize: (json['quickFabSize'] as num?)?.toDouble() ?? 56.0,
      fabMenuShowText: json['fabMenuShowText'] as bool? ?? true,
      openInAppBrowser: json['openInAppBrowser'] as bool? ?? true,
      htmlEditorTheme: json['htmlEditorTheme'] as String?,
      // ==> BACA DARI JSON <==
      defaultNoteIcon: json['defaultNoteIcon'] as String? ?? '🗒️',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'isChristmasTheme': isChristmasTheme,
      'isUnderwaterTheme': isUnderwaterTheme,
      'primaryColorValue': primaryColorValue,
      'recentColorValues': recentColorValues,
      'dashboardItemScale': dashboardItemScale,
      'showFloatingCharacter': showFloatingCharacter,
      'showQuickFab': showQuickFab,
      'quickFabIcon': quickFabIcon,
      'quickFabBgOpacity': quickFabBgOpacity,
      'quickFabOverallOpacity': quickFabOverallOpacity,
      'quickFabSize': quickFabSize,
      'fabMenuShowText': fabMenuShowText,
      'openInAppBrowser': openInAppBrowser,
      'htmlEditorTheme': htmlEditorTheme,
      // ==> SIMPAN KE JSON <==
      'defaultNoteIcon': defaultNoteIcon,
    };
  }

  ThemeSettings copyWith({
    bool? isDarkMode,
    bool? isChristmasTheme,
    bool? isUnderwaterTheme,
    int? primaryColorValue,
    List<int>? recentColorValues,
    double? dashboardItemScale,
    bool? showFloatingCharacter,
    bool? showQuickFab,
    String? quickFabIcon,
    double? quickFabBgOpacity,
    double? quickFabOverallOpacity,
    double? quickFabSize,
    bool? fabMenuShowText,
    bool? openInAppBrowser,
    ValueGetter<String?>? htmlEditorTheme,
    // ==> TAMBAHKAN DI COPYWITH <==
    String? defaultNoteIcon,
  }) {
    return ThemeSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isChristmasTheme: isChristmasTheme ?? this.isChristmasTheme,
      isUnderwaterTheme: isUnderwaterTheme ?? this.isUnderwaterTheme,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      recentColorValues: recentColorValues ?? this.recentColorValues,
      dashboardItemScale: dashboardItemScale ?? this.dashboardItemScale,
      showFloatingCharacter:
          showFloatingCharacter ?? this.showFloatingCharacter,
      showQuickFab: showQuickFab ?? this.showQuickFab,
      quickFabIcon: quickFabIcon ?? this.quickFabIcon,
      quickFabBgOpacity: quickFabBgOpacity ?? this.quickFabBgOpacity,
      quickFabOverallOpacity:
          quickFabOverallOpacity ?? this.quickFabOverallOpacity,
      quickFabSize: quickFabSize ?? this.quickFabSize,
      fabMenuShowText: fabMenuShowText ?? this.fabMenuShowText,
      openInAppBrowser: openInAppBrowser ?? this.openInAppBrowser,
      htmlEditorTheme: htmlEditorTheme != null
          ? htmlEditorTheme()
          : this.htmlEditorTheme,
      // ==> TAMBAHKAN DI COPYWITH <==
      defaultNoteIcon: defaultNoteIcon ?? this.defaultNoteIcon,
    );
  }
}
