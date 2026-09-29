import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/language.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/error_view.dart';
import '../widgets/language_card.dart';
import '../widgets/loading_skeleton.dart';

class LanguageScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const LanguageScreen({super.key, required this.onNavigate});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ClassroomState.instance,
      builder: (context, _) {
        final state = ClassroomState.instance;
        final isLoading = state.isLoading;
        final error = state.errorMessage;
        final allLanguages = state.languages;

        final filteredLanguages = allLanguages.where((l) {
          final query = _searchQuery.toLowerCase();
          return l.languageName.toLowerCase().contains(query) ||
              l.nativeName.toLowerCase().contains(query) ||
              l.languageCode.toLowerCase().contains(query) ||
              l.script.toLowerCase().contains(query);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context, allLanguages.length),

                  const SizedBox(height: 20),

                  // Selected Language Route Bar
                  _buildSelectedRouteBanner(state),

                  const SizedBox(height: 24),

                  // Search Bar & Filter
                  _buildSearchField(),

                  const SizedBox(height: 24),

                  // Content States
                  if (isLoading && allLanguages.isEmpty)
                    _buildLoadingGrid()
                  else if (error != null && allLanguages.isEmpty)
                    ErrorView(
                      friendlyMessage: error,
                      technicalDetails: state.technicalError,
                      onRetry: () => state.refreshAll(),
                    )
                  else if (allLanguages.isEmpty)
                    _buildEmptyState()
                  else if (filteredLanguages.isEmpty)
                    _buildNoResultsState()
                  else
                    _buildLanguageGrid(filteredLanguages, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classroom Languages',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dynamic vernacular catalog retrieved from GET /languages ($count registered)',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: ClassroomColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => ClassroomState.instance.refreshAll(),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedRouteBanner(ClassroomState state) {
    final source = state.selectedSourceLanguage;
    final target = state.selectedTargetLanguage;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClassroomColors.warmParchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Teaching Route for Translation',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: ClassroomColors.textDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (source != null && target != null)
                    TextButton.icon(
                      onPressed: () => widget.onNavigate(AppRouteItem.translate),
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Open Translate'),
                      style: TextButton.styleFrom(
                        foregroundColor: ClassroomColors.terracotta,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (isNarrow) ...[
                _buildRoutePill(
                  label: 'Source',
                  lang: source,
                  color: ClassroomColors.terracotta,
                  bgColor: ClassroomColors.terracottaLight,
                ),
                const SizedBox(height: 8),
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.swap_vert_rounded),
                    color: ClassroomColors.textMuted,
                    onPressed: state.swapLanguages,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRoutePill(
                  label: 'Target',
                  lang: target,
                  color: ClassroomColors.earthySage,
                  bgColor: ClassroomColors.sageLight,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildRoutePill(
                        label: 'Source Language',
                        lang: source,
                        color: ClassroomColors.terracotta,
                        bgColor: ClassroomColors.terracottaLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded),
                      tooltip: 'Swap source and target',
                      color: ClassroomColors.textMuted,
                      onPressed: state.swapLanguages,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoutePill(
                        label: 'Target Mother Tongue',
                        lang: target,
                        color: ClassroomColors.earthySage,
                        bgColor: ClassroomColors.sageLight,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoutePill({
    required String label,
    required Language? lang,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClassroomColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lang != null
                  ? '${lang.languageName} (${lang.nativeName.isNotEmpty ? lang.nativeName : lang.languageCode})'
                  : 'Select from below',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: lang != null
                    ? ClassroomColors.textDark
                    : ClassroomColors.textSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search by language name, native script, or code…',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ClassroomColors.textSubtle,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 3
            : constraints.maxWidth > 550
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => const LoadingSkeleton(height: 180),
        );
      },
    );
  }

  Widget _buildLanguageGrid(List<Language> languages, ClassroomState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 3
            : constraints.maxWidth > 550
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.45,
          ),
          itemCount: languages.length,
          itemBuilder: (context, index) {
            final lang = languages[index];
            final isSource = state.selectedSourceLanguage?.id == lang.id;
            final isTarget = state.selectedTargetLanguage?.id == lang.id;

            return LanguageCard(
              language: lang,
              isSourceSelected: isSource,
              isTargetSelected: isTarget,
              onSelectAsSource: () => state.selectSourceLanguage(lang),
              onSelectAsTarget: () => state.selectTargetLanguage(lang),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ClassroomColors.borderWarm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              size: 48,
              color: ClassroomColors.textSubtle,
            ),
            const SizedBox(height: 14),
            Text(
              'No Active Languages Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ClassroomColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The GET /languages endpoint returned an empty list. Please check that MySQL contains active language records.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: ClassroomColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ClassroomState.instance.refreshAll(),
              child: const Text('Retry Fetching'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: ClassroomColors.textSubtle,
            ),
            const SizedBox(height: 12),
            Text(
              'No languages match "$_searchQuery"',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ClassroomColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with a different language code or script name',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: ClassroomColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
