import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../state/classroom_state.dart';
import 'app_drawer.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final AppRouteItem currentRoute;
  final ValueChanged<AppRouteItem> onSelectRoute;
  final bool showLeadingDrawer;

  const AppHeader({
    super.key,
    required this.currentRoute,
    required this.onSelectRoute,
    this.showLeadingDrawer = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: ClassroomColors.creamBackground,
        border: Border(
          bottom: BorderSide(color: ClassroomColors.borderWarm, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showLeadingDrawer)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: ClassroomColors.textDark, size: 26),
              tooltip: 'Classroom Navigation Menu',
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          const SizedBox(width: 8),

          // Logo & Title
          Flexible(
            child: InkWell(
              onTap: () => onSelectRoute(AppRouteItem.home),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: ClassroomColors.terracotta,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BHASHA SANGI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ClassroomColors.terracotta,
                            letterSpacing: 0.6,
                          ),
                        ),
                        if (screenWidth >= 750)
                          Text(
                            'भाषा संगी • Vernacular Pedagogy',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: ClassroomColors.textSubtle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Desktop horizontal quick links
          if (isDesktop) ...[
            const SizedBox(width: 32),
            _DesktopNavLink(
              title: 'Home',
              isSelected: currentRoute == AppRouteItem.home,
              onTap: () => onSelectRoute(AppRouteItem.home),
            ),
            _DesktopNavLink(
              title: 'Languages',
              isSelected: currentRoute == AppRouteItem.languages,
              onTap: () => onSelectRoute(AppRouteItem.languages),
            ),
            _DesktopNavLink(
              title: 'Translate',
              isSelected: currentRoute == AppRouteItem.translate,
              onTap: () => onSelectRoute(AppRouteItem.translate),
            ),
            _DesktopNavLink(
              title: 'Lessons Library',
              isSelected: currentRoute == AppRouteItem.lessons,
              onTap: () => onSelectRoute(AppRouteItem.lessons),
            ),
            _DesktopNavLink(
              title: 'Sync',
              isSelected: currentRoute == AppRouteItem.syncStatus,
              onTap: () => onSelectRoute(AppRouteItem.syncStatus),
            ),
          ],

          const Spacer(),

          // Backend Live Status Indicator
          AnimatedBuilder(
            animation: ClassroomState.instance,
            builder: (context, _) {
              final isConnected = ClassroomState.instance.isBackendConnected;
              return Tooltip(
                message: isConnected
                    ? 'Backend connected (FastAPI online)'
                    : 'Backend offline or unreachable (Check localhost:8000 & CORS)',
                child: InkWell(
                  onTap: () => onSelectRoute(AppRouteItem.syncStatus),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? ClassroomColors.sageLight
                          : ClassroomColors.marigoldLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isConnected
                            ? ClassroomColors.earthySage.withOpacity(0.3)
                            : ClassroomColors.marigold.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? ClassroomColors.earthySage
                                : ClassroomColors.marigoldDark,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isConnected ? 'Connected' : 'Offline',
                          style: ClassroomTheme.highlightFont(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isConnected
                                ? ClassroomColors.sageDark
                                : ClassroomColors.marigoldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // Teacher profile chip
          AnimatedBuilder(
            animation: AuthService.instance,
            builder: (context, _) {
              final teacher = AuthService.instance.currentTeacher;
              return InkWell(
                onTap: () => onSelectRoute(AppRouteItem.login),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ClassroomColors.borderWarm),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: ClassroomColors.terracottaLight,
                        child: Text(
                          teacher != null ? teacher.fullName.substring(0, 1) : 'T',
                          style: ClassroomTheme.highlightFont(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ClassroomColors.terracottaDark,
                          ),
                        ),
                      ),
                      if (screenWidth >= 820) ...[
                        const SizedBox(width: 8),
                        Text(
                          teacher != null ? teacher.fullName : 'Teacher',
                          style: ClassroomTheme.highlightFont(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: ClassroomColors.textDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DesktopNavLink extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DesktopNavLink({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: isSelected
              ? ClassroomColors.terracotta
              : ClassroomColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: ClassroomColors.terracotta,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
