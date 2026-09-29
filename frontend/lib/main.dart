import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/community_voice_screen.dart';
import 'screens/downloads_screen.dart';
import 'screens/home_screen.dart';
import 'screens/language_screen.dart';
import 'screens/learning_cards_screen.dart';
import 'screens/lessons_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sync_screen.dart';
import 'screens/translation_screen.dart';
import 'screens/chapter_notes_screen.dart';
import 'state/classroom_state.dart';
import 'widgets/app_drawer.dart';
import 'widgets/app_header.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BhashaSangiApp());
}

class BhashaSangiApp extends StatelessWidget {
  const BhashaSangiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bhasha Sangi | भाषा संगी',
      debugShowCheckedModeBanner: false,
      theme: ClassroomTheme.lightTheme,
      home: const ClassroomAppShell(),
    );
  }
}

class ClassroomAppShell extends StatefulWidget {
  const ClassroomAppShell({super.key});

  @override
  State<ClassroomAppShell> createState() => _ClassroomAppShellState();
}

class _ClassroomAppShellState extends State<ClassroomAppShell> {
  AppRouteItem _currentRoute = AppRouteItem.home;

  @override
  void initState() {
    super.initState();
    // Non-blocking initial backend check and data fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ClassroomState.instance.refreshAll();
    });
  }

  void _navigateTo(AppRouteItem route) {
    setState(() {
      _currentRoute = route;
    });
  }

  Widget _buildActiveScreen() {
    switch (_currentRoute) {
      case AppRouteItem.home:
        return HomeScreen(onNavigate: _navigateTo);
      case AppRouteItem.languages:
        return LanguageScreen(onNavigate: _navigateTo);
      case AppRouteItem.lessons:
        return LessonsScreen(onNavigate: _navigateTo);
      case AppRouteItem.translate:
        return TranslationScreen(onNavigate: _navigateTo);
      case AppRouteItem.downloads:
        return DownloadsScreen(onNavigate: _navigateTo);
      case AppRouteItem.worksheets:
        return ChapterNotesScreen(onNavigate: _navigateTo);
      case AppRouteItem.learningCards:
        return LearningCardsScreen(onNavigate: _navigateTo);
      case AppRouteItem.communityVoice:
        return CommunityVoiceScreen(onNavigate: _navigateTo);
      case AppRouteItem.syncStatus:
        return SyncScreen(onNavigate: _navigateTo);
      case AppRouteItem.settings:
        return SettingsScreen(onNavigate: _navigateTo);
      case AppRouteItem.login:
        return LoginScreen(onNavigate: _navigateTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        currentRoute: _currentRoute,
        onSelectRoute: _navigateTo,
      ),
      drawer: AppDrawer(
        currentRoute: _currentRoute,
        onSelectRoute: _navigateTo,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<AppRouteItem>(_currentRoute),
          child: _buildActiveScreen(),
        ),
      ),
    );
  }
}
