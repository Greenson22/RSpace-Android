// lib/features/html_editor/presentation/themes/editor_themes.dart

import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_highlight/themes/androidstudio.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_highlight/themes/xcode.dart';

class EditorTheme {
  final String name;
  final Map<String, TextStyle> theme;

  EditorTheme({required this.name, required this.theme});
}

final List<EditorTheme> editorThemes = [
  EditorTheme(name: 'VS 2015 (Default)', theme: vs2015Theme),
  EditorTheme(name: 'Atom One Dark', theme: atomOneDarkTheme),
  EditorTheme(name: 'Atom One Light', theme: atomOneLightTheme),
  EditorTheme(name: 'Monokai Sublime', theme: monokaiSublimeTheme),
  EditorTheme(name: 'GitHub', theme: githubTheme),
  EditorTheme(name: 'Android Studio', theme: androidstudioTheme),
  EditorTheme(name: 'Xcode', theme: xcodeTheme),
  EditorTheme(name: 'A11y Dark', theme: a11yDarkTheme),
  EditorTheme(name: 'A11y Light', theme: a11yLightTheme),
];
