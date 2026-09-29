import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;
import '../config/theme.dart';
import '../models/chapter_notes.dart';
import '../models/translation.dart';
import '../services/api_service.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/error_view.dart';
import '../widgets/lesson_card.dart';
import '../widgets/loading_skeleton.dart';

enum LessonViewMode { recent, folders, byLesson }

class LessonsScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const LessonsScreen({super.key, required this.onNavigate});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  String _searchQuery = '';
  String _selectedLanguageFilter = 'ALL';
  String _selectedCurriculumFilter = 'ALL';
  LessonViewMode _viewMode = LessonViewMode.recent;

  String? _generatingNotesForFolder;
  final Map<String, ChapterNotes> _sessionNotesCache = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _apiService.getSessions();
      if (mounted) {
        setState(() {
          for (final s in sessions) {
            if (s.notes != null) {
              _sessionNotesCache[s.folderTag] = s.notes!;
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _generateNotesForFolder(String folderTag) async {
    setState(() => _generatingNotesForFolder = folderTag);
    try {
      final result = await _apiService.generateSessionNotes(folderTag: folderTag);
      if (result != null && result.notes != null && mounted) {
        setState(() {
          _sessionNotesCache[folderTag] = result.notes!;
          _generatingNotesForFolder = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI study notes generated successfully for "$folderTag"!', style: GoogleFonts.notoSans(color: Colors.white)),
            backgroundColor: ClassroomColors.earthySage,
          ),
        );
        _loadSessions();
      } else {
        if (mounted) {
          setState(() => _generatingNotesForFolder = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not generate notes. Check server connection.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _generatingNotesForFolder = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation error: $e')),
        );
      }
    }
  }

  void _downloadSessionPdf(String folderTag) {
    final url = _apiService.getSessionPdfUrl(folderTag: folderTag);
    try {
      web.window.open(url, '_blank');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open PDF export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ClassroomState.instance,
      builder: (context, _) {
        final state = ClassroomState.instance;
        // Ensure most recent translations appear first
        final allTranslations = List<Translation>.from(state.translations)
          ..sort((a, b) => b.id.compareTo(a.id));
        final isLoading = state.isLoading;
        final error = state.errorMessage;

        // Unique languages available
        final availableLanguages = <String>{'ALL'};
        for (final t in allTranslations) {
          if (t.sourceLanguage.isNotEmpty) availableLanguages.add(t.sourceLanguage);
          if (t.targetLanguage.isNotEmpty) availableLanguages.add(t.targetLanguage);
        }

        // Filter by search query, language, and curriculum
        final filteredTranslations = allTranslations.where((t) {
          final query = _searchQuery.toLowerCase();
          final matchesQuery = query.isEmpty ||
              t.lessonTitle.toLowerCase().contains(query) ||
              t.sourceText.toLowerCase().contains(query) ||
              t.translatedText.toLowerCase().contains(query) ||
              t.sourceLanguage.toLowerCase().contains(query) ||
              t.targetLanguage.toLowerCase().contains(query) ||
              t.sessionTag.toLowerCase().contains(query);

          final matchesLang = _selectedLanguageFilter == 'ALL' ||
              t.sourceLanguage == _selectedLanguageFilter ||
              t.targetLanguage == _selectedLanguageFilter;

          bool matchesCurriculum = true;
          if (_selectedCurriculumFilter == 'SCIENCE') {
            matchesCurriculum = t.lessonTitle.toLowerCase().contains('science') ||
                (t.subject?.toLowerCase().contains('science') ?? false) ||
                (t.subject?.toLowerCase().contains('evs') ?? false);
          } else if (_selectedCurriculumFilter == 'ENGLISH') {
            matchesCurriculum = t.lessonTitle.toLowerCase().contains('english') ||
                (t.subject?.toLowerCase().contains('english') ?? false);
          }

          return matchesQuery && matchesLang && matchesCurriculum;
        }).toList();

        // Grouping by lesson title
        final Map<String, List<Translation>> groupedByTitle = {};
        for (final t in filteredTranslations) {
          final titleKey = t.lessonTitle.trim().isEmpty ? 'Classroom Translations' : t.lessonTitle.trim();
          groupedByTitle.putIfAbsent(titleKey, () => []).add(t);
        }

        // Grouping by folder tag
        final Map<String, List<Translation>> groupedByFolder = {};
        for (final t in filteredTranslations) {
          final folderKey = t.sessionTag.trim().isEmpty ? 'General Classroom Discussion' : t.sessionTag.trim();
          groupedByFolder.putIfAbsent(folderKey, () => []).add(t);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, allTranslations.length),
                  const SizedBox(height: 20),
                  _buildSearchAndFilters(availableLanguages),
                  const SizedBox(height: 20),

                  // Content States
                  if (isLoading && allTranslations.isEmpty)
                    _buildLoadingList()
                  else if (error != null && allTranslations.isEmpty)
                    ErrorView(
                      friendlyMessage: error,
                      technicalDetails: state.technicalError,
                      onRetry: () => state.refreshAll(),
                    )
                  else if (allTranslations.isEmpty)
                    _buildEmptyState()
                  else if (filteredTranslations.isEmpty)
                    _buildNoResultsState()
                  else if (_viewMode == LessonViewMode.folders)
                    _buildFolderSessionsView(groupedByFolder)
                  else if (_viewMode == LessonViewMode.byLesson)
                    _buildGroupedView(groupedByTitle)
                  else
                    _buildFlatListView(filteredTranslations),
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
                'Translation & Lesson Library',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Classroom Spoken Speech • Topic Folders & AI Notes ($count records, newest on top)',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: ClassroomColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => widget.onNavigate(AppRouteItem.translate),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Translation'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: ClassroomColors.terracotta),
              tooltip: 'Refresh library',
              onPressed: () {
                ClassroomState.instance.refreshAll();
                _loadSessions();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(Set<String> languages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by lesson title, topic folder, phrase, or language…',
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
                ),
              ),
              const SizedBox(width: 12),
              // View Mode Selector
              SegmentedButton<LessonViewMode>(
                segments: const [
                  ButtonSegment(
                    value: LessonViewMode.recent,
                    label: Text('Recent First'),
                    icon: Icon(Icons.history_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: LessonViewMode.folders,
                    label: Text('Topic Folders'),
                    icon: Icon(Icons.folder_special_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: LessonViewMode.byLesson,
                    label: Text('By Chapter'),
                    icon: Icon(Icons.menu_book_rounded, size: 16),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (set) {
                  setState(() => _viewMode = set.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Filter Language:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClassroomColors.textDark,
                ),
              ),
              ...languages.map((lang) {
                final isSelected = _selectedLanguageFilter == lang;
                return FilterChip(
                  label: Text(lang == 'ALL' ? 'All Languages' : lang),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedLanguageFilter = lang);
                  },
                  selectedColor: ClassroomColors.terracottaLight,
                  checkmarkColor: ClassroomColors.terracotta,
                  labelStyle: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? ClassroomColors.terracottaDark : ClassroomColors.textDark,
                  ),
                );
              }),
              const SizedBox(width: 12),
              Text(
                'Curriculum:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClassroomColors.textDark,
                ),
              ),
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedCurriculumFilter == 'ALL',
                onSelected: (_) => setState(() => _selectedCurriculumFilter = 'ALL'),
                selectedColor: ClassroomColors.sageLight,
                labelStyle: GoogleFonts.notoSans(fontSize: 12),
              ),
              ChoiceChip(
                label: const Text('Science / EVS'),
                selected: _selectedCurriculumFilter == 'SCIENCE',
                onSelected: (_) => setState(() => _selectedCurriculumFilter = 'SCIENCE'),
                selectedColor: ClassroomColors.sageLight,
                labelStyle: GoogleFonts.notoSans(fontSize: 12),
              ),
              ChoiceChip(
                label: const Text('English Reader'),
                selected: _selectedCurriculumFilter == 'ENGLISH',
                onSelected: (_) => setState(() => _selectedCurriculumFilter = 'ENGLISH'),
                selectedColor: ClassroomColors.sageLight,
                labelStyle: GoogleFonts.notoSans(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSessionsView(Map<String, List<Translation>> groupedByFolder) {
    return Column(
      children: groupedByFolder.entries.map((entry) {
        final folderTag = entry.key;
        final translations = entry.value;
        final notes = _sessionNotesCache[folderTag];
        final isGenerating = _generatingNotesForFolder == folderTag;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ClassroomColors.terracottaLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_special_rounded, color: ClassroomColors.terracotta, size: 22),
              ),
              title: Text(
                folderTag,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.textDark,
                ),
              ),
              subtitle: Text(
                '${translations.length} spoken ${translations.length == 1 ? 'translation' : 'translations'} • ${notes != null ? '✅ AI Study Notes Ready' : 'Notes not yet synthesized'}',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: notes != null ? ClassroomColors.earthySage : ClassroomColors.textMuted,
                  fontWeight: notes != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                // AI Notes Synthesis & PDF Action Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ClassroomColors.creamBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ClassroomColors.borderWarm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: ClassroomColors.terracotta, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'AI Classroom Study Notes',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ClassroomColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (notes != null)
                                ElevatedButton.icon(
                                  onPressed: () => _downloadSessionPdf(folderTag),
                                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                                  label: const Text('Download PDF 📄'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ClassroomColors.terracotta,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: isGenerating ? null : () => _generateNotesForFolder(folderTag),
                                icon: isGenerating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded, size: 15),
                                label: Text(
                                  notes != null ? 'Regenerate AI Notes 🔄' : 'Generate AI Notes from Session ✨',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ClassroomColors.terracottaDark,
                                  side: const BorderSide(color: ClassroomColors.terracotta),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (notes != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ClassroomColors.borderWarm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Summary: ${notes.summaryEn}',
                                style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w500, color: ClassroomColors.textDark),
                              ),
                              if (notes.summaryHi.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  notes.summaryHi,
                                  style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.terracottaDark),
                                ),
                              ],
                              if (notes.keyPoints.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Key Takeaways: ${notes.keyPoints.join(" • ")}',
                                  style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'The teacher taught or translated ${translations.length} expressions in this session. Click "Generate AI Notes from Session" to create structured bilingual study notes with key points and review questions ready for PDF export.',
                          style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // List of translations in this folder
                Text(
                  'Spoken Translations in this Topic Folder (${translations.length}):',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: ClassroomColors.textDark),
                ),
                const SizedBox(height: 8),
                ...translations.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LessonCard(translation: item),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedView(Map<String, List<Translation>> grouped) {
    return Column(
      children: grouped.entries.map((entry) {
        final title = entry.key;
        final list = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: ClassroomColors.warmParchment,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ClassroomColors.borderWarm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_open_rounded,
                      size: 20,
                      color: ClassroomColors.terracotta,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ClassroomColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${list.length} ${list.length == 1 ? 'sentence' : 'sentences'}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ClassroomColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...list.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LessonCard(translation: item),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlatListView(List<Translation> list) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: LessonCard(translation: list[index]),
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(
        4,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: LoadingSkeleton(height: 140, borderRadius: 16),
        ),
      ),
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
              Icons.menu_book_rounded,
              size: 48,
              color: ClassroomColors.textSubtle,
            ),
            const SizedBox(height: 14),
            Text(
              'No Saved Translations Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ClassroomColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The translation library is currently empty. Use the Translate tool to record your first vernacular classroom lesson.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: ClassroomColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => widget.onNavigate(AppRouteItem.translate),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Compose Translation'),
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
              'No lesson translations match your filter',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ClassroomColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try clearing your search query or selecting "All Languages"',
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
