import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;
import '../config/theme.dart';
import '../models/chapter_notes.dart';
import '../models/curriculum_lesson.dart';
import '../models/language.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/loading_skeleton.dart';

class ChapterNotesScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const ChapterNotesScreen({super.key, required this.onNavigate});

  @override
  State<ChapterNotesScreen> createState() => _ChapterNotesScreenState();
}

class _ChapterNotesScreenState extends State<ChapterNotesScreen> {
  final ApiService _apiService = ApiService();

  List<CurriculumLesson> _lessons = [];
  CurriculumLesson? _selectedLesson;
  Language? _selectedLanguage;

  ChapterNotes? _currentNotes;
  bool _isLoadingLessons = false;
  bool _isLoadingNotes = false;
  bool _isPlayingAudio = false;
  String? _errorMessage;

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

  String _selectedSubjectFilter = 'ALL'; // 'ALL', 'SCIENCE', 'ENGLISH'
  String _aiProvider = 'auto'; // 'auto', 'gemini', 'qwen'
  String? _customApiKey;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoadingLessons = true);

    final state = ClassroomState.instance;
    if (state.languages.isEmpty) {
      await state.refreshAll();
    }

    _selectedLanguage = state.languages.firstWhere(
      (l) => l.languageCode.toLowerCase().startsWith('sat'),
      orElse: () => (state.languages.isNotEmpty ? state.languages.first : null)!,
    );

    await _loadLessonsForCurrentGrade();
  }

  Future<void> _loadLessonsForCurrentGrade() async {
    setState(() => _isLoadingLessons = true);
    final fetched = await _apiService.getCurriculumLessons(grade: _selectedGrade);
    if (mounted) {
      setState(() {
        _lessons = fetched;
        _isLoadingLessons = false;
        if (_lessons.isNotEmpty) {
          _selectedLesson = _lessons.first;
        } else {
          _selectedLesson = null;
          _currentNotes = null;
        }
      });

      if (_selectedLesson != null) {
        _loadNotesForLesson(_selectedLesson!);
      }
    }
  }

  Future<void> _changeGrade(String newGrade) async {
    if (_selectedGrade == newGrade) return;
    VoiceService.instance.stopAudio();
    setState(() {
      _selectedGrade = newGrade;
      _currentNotes = null;
      _errorMessage = null;
    });
    await _loadLessonsForCurrentGrade();
  }

  Future<void> _loadNotesForLesson(CurriculumLesson lesson, {bool forceRefresh = false}) async {
    VoiceService.instance.stopAudio();
    setState(() {
      _isLoadingNotes = true;
      _errorMessage = null;
      _isPlayingAudio = false;
    });

    final targetLangId = _selectedLanguage?.id ?? 1;

    try {
      ChapterNotes? notes;
      if (forceRefresh || _customApiKey != null) {
        notes = await _apiService.generateChapterNotes(
          lessonId: lesson.id,
          targetLanguageId: targetLangId,
          apiKey: _customApiKey,
          provider: _aiProvider,
          forceRefresh: forceRefresh,
        );
      } else {
        notes = await _apiService.getChapterNotes(
          lessonId: lesson.id,
          targetLanguageId: targetLangId,
        );
      }

      if (mounted) {
        setState(() {
          _currentNotes = notes;
          _isLoadingNotes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
          _errorMessage = 'Could not load chapter notes: $e';
        });
      }
    }
  }

  void _toggleAudio() {
    if (_isPlayingAudio) {
      VoiceService.instance.stopAudio();
      setState(() => _isPlayingAudio = false);
    } else {
      final audioBase64 = _currentNotes?.audioBase64;
      if (audioBase64 != null && audioBase64.isNotEmpty) {
        setState(() => _isPlayingAudio = true);
        VoiceService.instance.playBase64Audio(
          audioBase64,
          onDone: () {
            if (mounted) setState(() => _isPlayingAudio = false);
          },
          onError: () {
            if (mounted) setState(() => _isPlayingAudio = false);
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio not available for this chapter summary.')),
        );
      }
    }
  }

  void _downloadNotesPdf() {
    if (_selectedLesson == null) return;
    final langId = _selectedLanguage?.id ?? 1;
    final url = _apiService.getChapterPdfUrl(_selectedLesson!.id, langId);
    try {
      web.window.open(url, '_blank');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open printable PDF worksheet: $e')),
      );
    }
  }

  void _showAiKeyDialog() {
    final controller = TextEditingController(text: _customApiKey ?? '');
    String tempProvider = _aiProvider;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: ClassroomColors.terracotta),
              const SizedBox(width: 10),
              Text(
                'Cloud AI Settings',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bhasha Sangi automatically generates notes using its built-in JCERT Curriculum Engine & Bhashini NMT.\n\nOptionally connect free cloud AI (Gemini 1.5 Flash or Qwen 2.5 via Groq):',
                  style: GoogleFonts.notoSans(fontSize: 13, color: ClassroomColors.textMuted),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tempProvider,
                  decoration: const InputDecoration(
                    labelText: 'AI Model Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Auto (Built-in + Bhashini)')),
                    DropdownMenuItem(value: 'gemini', child: Text('Google Gemini (1.5 Flash)')),
                    DropdownMenuItem(value: 'qwen', child: Text('Qwen 2.5 (via Groq / OpenRouter)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => tempProvider = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'API Key (Optional)',
                    hintText: 'e.g. AIzaSy... or gsk_...',
                    border: OutlineInputBorder(),
                    helperText: 'Leave blank to use default curriculum engine',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _aiProvider = tempProvider;
                  _customApiKey = controller.text.trim().isEmpty ? null : controller.text.trim();
                });
                Navigator.pop(ctx);
                if (_selectedLesson != null) {
                  _loadNotesForLesson(_selectedLesson!, forceRefresh: true);
                }
              },
              child: const Text('Save & Regenerate'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ClassroomState.instance;
    final filteredLessons = _lessons.where((l) {
      if (_selectedSubjectFilter == 'SCIENCE') {
        return l.subject.toLowerCase().contains('science') || l.subject.toLowerCase().contains('evs');
      } else if (_selectedSubjectFilter == 'ENGLISH') {
        return l.subject.toLowerCase().contains('english');
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 20),

              // Controls Bar: Target Language + AI Settings + Subject Filter
              _buildControlsBar(state),

              const SizedBox(height: 18),

              // Chapter Dropdown Selector
              _buildChapterSelector(filteredLessons),

              const SizedBox(height: 22),

              // Main Notes View
              if (_isLoadingNotes)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorBox()
              else if (_currentNotes != null)
                _buildNotesDisplay(_currentNotes!)
              else
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ClassroomColors.terracottaLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: ClassroomColors.terracotta,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_selectedGrade Chapter Notes & AI Pedagogy',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ClassroomColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Jharkhand Board (JCERT / JAC) & CBSE $_selectedGrade Curriculum • Science (EVS) & English Reader with Vernacular Mother Tongue Notes',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: ClassroomColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Cloud AI Settings (Gemini / Qwen)',
          onPressed: _showAiKeyDialog,
        ),
      ],
    );
  }

  Widget _buildControlsBar(ClassroomState state) {
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
          // 1. Class / Grade Level Selector (Class 1 to Class 8)
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 16, color: ClassroomColors.terracotta),
              const SizedBox(width: 8),
              Text(
                'Select Class (1st to 8th):',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.terracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableGrades.map((grade) {
                final isSelected = _selectedGrade == grade;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: isSelected ? Colors.white : ClassroomColors.terracotta,
                    ),
                    label: Text(grade),
                    selected: isSelected,
                    selectedColor: ClassroomColors.terracotta,
                    backgroundColor: ClassroomColors.creamBackground,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : ClassroomColors.textDark,
                    ),
                    onSelected: (val) {
                      if (val) _changeGrade(grade);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: ClassroomColors.borderWarm),
          const SizedBox(height: 14),

          // 2. Target Mother Tongue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target Mother Tongue for Notes:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.terracotta,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ClassroomColors.warmParchment,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Engine: ${_currentNotes?.aiProvider ?? _aiProvider}',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ClassroomColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: state.languages.map((lang) {
                final isSelected = _selectedLanguage?.id == lang.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${lang.languageName} (${lang.nativeName})'),
                    selected: isSelected,
                    selectedColor: ClassroomColors.terracottaLight,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? ClassroomColors.terracottaDark
                          : ClassroomColors.textDark,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedLanguage = lang);
                        if (_selectedLesson != null) {
                          _loadNotesForLesson(_selectedLesson!);
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: ClassroomColors.borderWarm),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Subject Filter: ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClassroomColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              _buildSubjectChip('ALL', 'All Subjects', Icons.auto_stories_rounded),
              const SizedBox(width: 8),
              _buildSubjectChip('SCIENCE', 'Science / EVS', Icons.eco_rounded),
              const SizedBox(width: 8),
              _buildSubjectChip('ENGLISH', 'English Reader', Icons.menu_book_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectChip(String value, String label, IconData icon) {
    final isSelected = _selectedSubjectFilter == value;
    return FilterChip(
      avatar: Icon(
        icon,
        size: 15,
        color: isSelected ? ClassroomColors.terracotta : ClassroomColors.textMuted,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: ClassroomColors.terracottaLight,
      checkmarkColor: ClassroomColors.terracotta,
      labelStyle: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? ClassroomColors.terracottaDark : ClassroomColors.textDark,
      ),
      onSelected: (_) {
        setState(() => _selectedSubjectFilter = value);
      },
    );
  }

  Widget _buildChapterSelector(List<CurriculumLesson> filteredLessons) {
    if (_isLoadingLessons) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(color: ClassroomColors.terracotta),
      );
    }

    if (filteredLessons.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_selectedLesson != null && !filteredLessons.any((l) => l.id == _selectedLesson!.id)) {
      _selectedLesson = filteredLessons.first;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: ClassroomColors.creamBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CurriculumLesson>(
          isExpanded: true,
          value: _selectedLesson,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: ClassroomColors.terracotta),
          items: filteredLessons.map((l) {
            return DropdownMenuItem<CurriculumLesson>(
              value: l,
              child: Text(
                l.lessonTitle,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ClassroomColors.textDark,
                ),
              ),
            );
          }).toList(),
          onChanged: (lesson) {
            if (lesson != null) {
              setState(() => _selectedLesson = lesson);
              _loadNotesForLesson(lesson);
            }
          },
        ),
      ),
    );
  }

  Widget _buildNotesDisplay(ChapterNotes notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Chapter Summary Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ClassroomColors.earthySage.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: ClassroomColors.earthySage.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ClassroomColors.sageLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: ClassroomColors.earthySage,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Chapter Core Summary (पाठ का सार)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ClassroomColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleAudio,
                        icon: Icon(
                          _isPlayingAudio ? Icons.stop_rounded : Icons.volume_up_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _isPlayingAudio ? 'Stop Audio' : 'Listen in ${notes.targetLanguage} 🔊',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ClassroomColors.earthySage,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _downloadNotesPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: Text(
                          'Download PDF 📄',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ClassroomColors.terracotta,
                          side: const BorderSide(color: ClassroomColors.terracotta, width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Vernacular Translated Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClassroomColors.sageLight.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ClassroomColors.earthySage.withOpacity(0.2)),
                ),
                child: SelectableText(
                  notes.summaryTranslated,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ClassroomColors.textDark,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Hindi / English Summary
              Text(
                notes.summaryHi.isNotEmpty ? notes.summaryHi : notes.summaryEn,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: ClassroomColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Key Pedagogical Takeaways
        if (notes.keyPoints.isNotEmpty) ...[
          _buildSectionTitle(Icons.checklist_rounded, 'Key Pedagogical Takeaways (मुख्य बिंदु)'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClassroomColors.borderWarm),
            ),
            child: Column(
              children: notes.keyPoints.map((point) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: ClassroomColors.terracotta,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: ClassroomColors.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 3. Vernacular Vocabulary Table
        if (notes.vocabulary.isNotEmpty) ...[
          _buildSectionTitle(Icons.translate_rounded, 'Chapter Vocabulary & Vernacular Glossary (शब्दावली)'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ClassroomColors.borderWarm),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(2.0),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: ClassroomColors.borderSubtle.withOpacity(0.5)),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: ClassroomColors.warmParchment),
                    children: [
                      _buildTableHeaderCell('English Word'),
                      _buildTableHeaderCell('हिन्दी शब्द'),
                      _buildTableHeaderCell('Child-Friendly Meaning'),
                    ],
                  ),
                  ...notes.vocabulary.map((v) {
                    return TableRow(
                      children: [
                        _buildTableCell(v.wordEn, isBold: true),
                        _buildTableCell(v.wordHi),
                        _buildTableCell(v.meaning),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 4. Classroom Interactive Activity
        _buildSectionTitle(Icons.celebration_rounded, 'Interactive Classroom Activity (कक्षा गतिविधि)'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ClassroomColors.marigoldLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClassroomColors.marigold.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notes.classroomActivity.title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.marigoldDark,
                ),
              ),
              const SizedBox(height: 6),
              if (notes.classroomActivity.instructionsTranslated.isNotEmpty) ...[
                Text(
                  notes.classroomActivity.instructionsTranslated,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ClassroomColors.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                notes.classroomActivity.instructions,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: ClassroomColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 5. Practice Questions & Answers
        if (notes.practiceQuestions.isNotEmpty) ...[
          _buildSectionTitle(Icons.quiz_rounded, 'Practice Questions & Answers (अभ्यास प्रश्न-उत्तर)'),
          const SizedBox(height: 10),
          Column(
            children: notes.practiceQuestions.map((q) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ClassroomColors.borderWarm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Q: ', style: TextStyle(fontWeight: FontWeight.bold, color: ClassroomColors.terracotta)),
                        Expanded(
                          child: Text(
                            q.questionTranslated.isNotEmpty ? q.questionTranslated : q.questionEn,
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: ClassroomColors.textDark),
                          ),
                        ),
                      ],
                    ),
                    if (q.questionHi.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('   ${q.questionHi}', style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('A: ', style: TextStyle(fontWeight: FontWeight.bold, color: ClassroomColors.earthySage)),
                        Expanded(
                          child: Text(
                            q.answerTranslated.isNotEmpty ? q.answerTranslated : q.answerEn,
                            style: GoogleFonts.notoSans(fontSize: 14, color: ClassroomColors.textDark, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 16),

        // Actions: Regenerate with AI button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                if (_selectedLesson != null) {
                  _loadNotesForLesson(_selectedLesson!, forceRefresh: true);
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Regenerate Notes with AI 🔄'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ClassroomColors.terracotta),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ClassroomColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ClassroomColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.notoSans(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: ClassroomColors.textDark,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      children: [
        LoadingSkeleton(height: 180),
        SizedBox(height: 16),
        LoadingSkeleton(height: 140),
        SizedBox(height: 16),
        LoadingSkeleton(height: 200),
      ],
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClassroomColors.terracottaLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(_errorMessage!, style: GoogleFonts.notoSans(color: ClassroomColors.terracottaDark)),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(
        'Please select a chapter above to view its translated AI study notes.',
        style: GoogleFonts.notoSans(color: ClassroomColors.textMuted),
      ),
    );
  }
}
