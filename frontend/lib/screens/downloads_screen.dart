import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;
import '../config/theme.dart';
import '../models/classroom_session.dart';
import '../models/curriculum_lesson.dart';
import '../models/language.dart';
import '../services/api_service.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';

enum DownloadTab { chapters, sessions, offlinePacks }

class DownloadsScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const DownloadsScreen({super.key, required this.onNavigate});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final ApiService _apiService = ApiService();

  DownloadTab _currentTab = DownloadTab.chapters;
  List<CurriculumLesson> _lessons = [];
  List<ClassroomSession> _sessions = [];
  bool _isLoading = true;
  String _selectedGrade = 'Class 3';
  final List<String> _availableGrades = const [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
  ];
  String _selectedSubject = 'ALL';
  int _selectedLanguageId = 1; // Default Santali
  String? _generatingSessionFolder;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final lessons = await _apiService.getCurriculumLessons(grade: _selectedGrade);
      final sessions = await _apiService.getSessions();
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeGrade(String newGrade) {
    if (_selectedGrade == newGrade) return;
    setState(() => _selectedGrade = newGrade);
    _loadData();
  }

  void _downloadChapterPdf(int lessonId) {
    final url = _apiService.getChapterPdfUrl(lessonId, _selectedLanguageId);
    try {
      web.window.open(url, '_blank');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF export: $e')),
      );
    }
  }

  void _downloadSessionPdf(String folderTag) {
    final url = _apiService.getSessionPdfUrl(folderTag: folderTag);
    try {
      web.window.open(url, '_blank');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF export: $e')),
      );
    }
  }

  Future<void> _generateSessionNotes(String folderTag) async {
    setState(() => _generatingSessionFolder = folderTag);
    try {
      final res = await _apiService.generateSessionNotes(
        folderTag: folderTag,
        targetLanguageId: _selectedLanguageId,
      );
      if (res != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI study notes created for "$folderTag"!', style: GoogleFonts.notoSans(color: Colors.white)),
            backgroundColor: ClassroomColors.earthySage,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingSessionFolder = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ClassroomState.instance,
      builder: (context, _) {
        final state = ClassroomState.instance;
        final languages = state.languages;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildTabBar(),
                  const SizedBox(height: 20),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: ClassroomColors.terracotta),
                      ),
                    )
                  else if (_currentTab == DownloadTab.chapters)
                    _buildChaptersSection(languages)
                  else if (_currentTab == DownloadTab.sessions)
                    _buildSessionsSection()
                  else
                    _buildOfflinePacksSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ClassroomColors.sageLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_for_offline_rounded,
                color: ClassroomColors.earthySage,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classroom Study Notes & PDF Downloads',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ClassroomColors.textDark,
                  ),
                ),
                Text(
                  'Download print-ready worksheets with Ol Chiki, Devanagari, and English bilingual texts.',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: ClassroomColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: ClassroomColors.terracotta),
          tooltip: 'Refresh downloads',
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: Row(
        children: [
          _buildTabButton(DownloadTab.chapters, '📚 $_selectedGrade Notes (${_lessons.length})'),
          _buildTabButton(DownloadTab.sessions, '🎙️ Spoken Speech Sessions (${_sessions.length})'),
          _buildTabButton(DownloadTab.offlinePacks, '💾 Offline Packs & Sync'),
        ],
      ),
    );
  }

  Widget _buildTabButton(DownloadTab tab, String label) {
    final isSelected = _currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ClassroomColors.terracotta : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : ClassroomColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: Chapter Study Notes ---
  Widget _buildChaptersSection(List<Language> languages) {
    final filtered = _lessons.where((l) {
      if (_selectedSubject == 'SCIENCE') {
        return l.subject.toLowerCase().contains('science') || l.subject.toLowerCase().contains('evs');
      } else if (_selectedSubject == 'ENGLISH') {
        return l.subject.toLowerCase().contains('english');
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Class Selector Choice Chips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ClassroomColors.borderWarm),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_rounded, color: ClassroomColors.terracotta, size: 18),
              const SizedBox(width: 8),
              Text(
                'Class:',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: ClassroomColors.terracottaDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableGrades.map((g) {
                      final isSelected = _selectedGrade == g;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(g),
                          selected: isSelected,
                          selectedColor: ClassroomColors.terracotta,
                          backgroundColor: ClassroomColors.creamBackground,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : ClassroomColors.textDark,
                          ),
                          onSelected: (val) {
                            if (val) _changeGrade(g);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Controls: Subject filter & Target Language
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ClassroomColors.borderWarm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Subject:',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: ClassroomColors.textDark),
                  ),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedSubject == 'ALL',
                    onSelected: (_) => setState(() => _selectedSubject = 'ALL'),
                  ),
                  ChoiceChip(
                    label: const Text('Science / EVS'),
                    selected: _selectedSubject == 'SCIENCE',
                    onSelected: (_) => setState(() => _selectedSubject = 'SCIENCE'),
                  ),
                  ChoiceChip(
                    label: const Text('English Reader'),
                    selected: _selectedSubject == 'ENGLISH',
                    onSelected: (_) => setState(() => _selectedSubject = 'ENGLISH'),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded, color: ClassroomColors.earthySage, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Target Language:',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: ClassroomColors.textDark),
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedLanguageId,
                      items: languages.map((lang) {
                        return DropdownMenuItem<int>(
                          value: lang.id,
                          child: Text(
                            '${lang.languageName} (${lang.script})',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLanguageId = val);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Text('No chapters found for this filter.', style: GoogleFonts.notoSans(color: ClassroomColors.textMuted)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final lesson = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ClassroomColors.borderWarm),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ClassroomColors.warmParchment,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: ClassroomColors.terracotta, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ClassroomColors.sageLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  lesson.subject,
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: ClassroomColors.earthySage),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lesson.gradeLevel,
                                style: GoogleFonts.notoSans(fontSize: 11, color: ClassroomColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lesson.lessonTitle,
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: ClassroomColors.textDark),
                          ),
                          Text(
                            'Complete printable study sheet with bilingual summary, vocabulary, activity, and Q&A.',
                            style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _downloadChapterPdf(lesson.id),
                          icon: const Icon(Icons.file_download_rounded, size: 16),
                          label: const Text('Download PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClassroomColors.terracotta,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => widget.onNavigate(AppRouteItem.worksheets),
                          icon: const Icon(Icons.visibility_rounded, size: 16),
                          label: const Text('View Notes'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ClassroomColors.textDark,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- TAB 2: Spoken Speech Sessions ---
  Widget _buildSessionsSection() {
    if (_sessions.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 30),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClassroomColors.borderWarm),
          ),
          child: Column(
            children: [
              const Icon(Icons.mic_none_rounded, size: 40, color: ClassroomColors.textSubtle),
              const SizedBox(height: 12),
              Text(
                'No Classroom Speech Sessions Recorded Yet',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: ClassroomColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Teach and speak in the Translate section and tag your lecture into a topic folder to generate study notes here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(fontSize: 13, color: ClassroomColors.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => widget.onNavigate(AppRouteItem.translate),
                icon: const Icon(Icons.mic_rounded, size: 18),
                label: const Text('Start Spoken Teaching Session'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final isGenerating = _generatingSessionFolder == session.folderTag;
        final hasNotes = session.hasGeneratedNotes;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClassroomColors.borderWarm),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasNotes ? ClassroomColors.sageLight : ClassroomColors.warmParchment,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasNotes ? Icons.article_rounded : Icons.record_voice_over_rounded,
                  color: hasNotes ? ClassroomColors.earthySage : ClassroomColors.terracotta,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.sessionName,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: ClassroomColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.translationCount} spoken expressions • Medium: ${session.targetLanguage} • ${hasNotes ? "✅ AI Notes Available" : "Oral Discussion Transcripts"}',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: hasNotes ? ClassroomColors.earthySage : ClassroomColors.textMuted,
                        fontWeight: hasNotes ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _downloadSessionPdf(session.folderTag),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Download PDF 📄'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClassroomColors.terracotta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: isGenerating ? null : () => _generateSessionNotes(session.folderTag),
                    icon: isGenerating
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(hasNotes ? 'Regenerate 🔄' : 'Generate Notes ✨'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ClassroomColors.terracottaDark,
                      side: const BorderSide(color: ClassroomColors.terracotta),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 3: Offline Packs & Sync Status ---
  Widget _buildOfflinePacksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
                  const Icon(Icons.offline_pin_rounded, color: ClassroomColors.earthySage, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Offline Teaching Readiness',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: ClassroomColors.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Classroom notes, vocabulary glossaries, and speech audio are stored in local SQLite database cache. Once accessed or generated, teachers can review, play, and print worksheets even when school district internet connectivity is down.',
                style: GoogleFonts.notoSans(fontSize: 13, color: ClassroomColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All Class 3 curriculum notes and transcripts are currently synchronized locally.', style: GoogleFonts.notoSans(color: Colors.white)),
                      backgroundColor: ClassroomColors.earthySage,
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_done_rounded, size: 18),
                label: const Text('Verify Local Offline Cache'),
                style: ElevatedButton.styleFrom(backgroundColor: ClassroomColors.earthySage),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
