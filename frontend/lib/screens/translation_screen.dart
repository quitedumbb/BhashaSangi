import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/language.dart';
import '../models/translation_result.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';

class TranslationScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const TranslationScreen({super.key, required this.onNavigate});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _lessonIdController = TextEditingController();
  final TextEditingController _dialectIdController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _isTranslating = false;
  bool _isListening = false;
  bool _isPlayingAudio = false;
  String? _errorMessage;
  String? _technicalError;
  TranslationResult? _lastResult;
  bool _showAdvancedOptions = false;

  String _selectedSessionTag = 'General Classroom Discussion';
  final List<String> _sessionTags = [
    'General Classroom Discussion',
    "Chapter 1: Poonam's Day Out",
    'Chapter 2: The Plant Fairy',
    "Chapter 3: Water O' Water!",
    'Chapter 4: Our First School',
    "Chapter 5: Chhotu's House",
    'Chapter 6: Foods We Eat',
    'Chapter 7: Saying Without Speaking',
    'Chapter 8: Flying High',
    "Chapter 9: It's Raining",
    'Chapter 10: What is Cooking',
    'English Unit 1: Good Morning',
    'English Unit 2: Bird Talk',
    'English Unit 3: Little by Little',
  ];

  @override
  void initState() {
    super.initState();
    _loadSessionTags();
  }

  Future<void> _loadSessionTags() async {
    try {
      final tags = await _apiService.getSessionTags();
      if (tags.isNotEmpty && mounted) {
        setState(() {
          for (final t in tags) {
            if (!_sessionTags.contains(t)) {
              _sessionTags.add(t);
            }
          }
        });
      }
    } catch (_) {}
  }

  final List<String> _classroomSamplePhrases = [
    'Poonam looked up and saw many animals and birds resting on the village tree.',
    'Sal, Mahua, and Neem trees protect our village soil from drought and wind.',
    'We get fresh water from rain, rivers, ponds, and village tube wells.',
    'Good morning sky, good morning sun, good morning little winds that run.',
    'Little by little each day, a small acorn grows into a mighty forest oak.',
    'Over the mountains, over the plains, over the rivers, here come the trains.',
  ];

  @override
  void dispose() {
    VoiceService.instance.stopListening();
    VoiceService.instance.stopAudio();
    _textController.dispose();
    _lessonIdController.dispose();
    _dialectIdController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    if (_isListening) {
      VoiceService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      final state = ClassroomState.instance;
      final srcCode = state.selectedSourceLanguage?.languageCode.toLowerCase() ?? 'hi';
      final locale = srcCode.startsWith('en')
          ? 'en-IN'
          : (srcCode.startsWith('bn')
              ? 'bn-IN'
              : (srcCode.startsWith('or') ? 'or-IN' : 'hi-IN'));

      setState(() => _isListening = true);
      VoiceService.instance.startListening(
        language: locale,
        onResult: (text) {
          if (mounted) {
            setState(() {
              _textController.text = text;
            });
          }
        },
        onDone: () {
          if (mounted) setState(() => _isListening = false);
        },
        onError: (err) {
          if (mounted) {
            setState(() => _isListening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Speech input error: $err')),
            );
          }
        },
      );
    }
  }

  void _speakTranslatedOutput(TranslationResult result, ClassroomState state) async {
    if (result.audioBase64 != null) {
      setState(() => _isPlayingAudio = true);
      VoiceService.instance.playBase64Audio(
        result.audioBase64!,
        onDone: () {
          if (mounted) setState(() => _isPlayingAudio = false);
        },
        onError: () {
          if (mounted) setState(() => _isPlayingAudio = false);
        },
      );
    } else {
      setState(() => _isPlayingAudio = true);
      final langCode = state.selectedTargetLanguage?.languageCode ?? 'hi';
      final audio = await _apiService.synthesizeSpeech(
        text: result.translatedText,
        languageCode: langCode,
      );
      if (audio != null && mounted) {
        VoiceService.instance.playBase64Audio(
          audio,
          onDone: () {
            if (mounted) setState(() => _isPlayingAudio = false);
          },
          onError: () {
            if (mounted) setState(() => _isPlayingAudio = false);
          },
        );
      } else {
        if (mounted) setState(() => _isPlayingAudio = false);
      }
    }
  }

  void _stopAudio() {
    VoiceService.instance.stopAudio();
    setState(() => _isPlayingAudio = false);
  }

  Future<void> _handleTranslate(ClassroomState state) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please type or paste a classroom sentence to translate.',
            style: GoogleFonts.notoSans(color: Colors.white),
          ),
          backgroundColor: ClassroomColors.terracotta,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final source = state.selectedSourceLanguage;
    final target = state.selectedTargetLanguage;

    if (source == null || target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select both a source and target language first.',
            style: GoogleFonts.notoSans(color: Colors.white),
          ),
          backgroundColor: ClassroomColors.terracotta,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (source.id == target.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Source and target languages are identical. Please choose different languages.',
            style: GoogleFonts.notoSans(color: Colors.white),
          ),
          backgroundColor: ClassroomColors.warningAmber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
      _errorMessage = null;
      _technicalError = null;
      _lastResult = null;
    });

    int? lessonId;
    if (_lessonIdController.text.trim().isNotEmpty) {
      lessonId = int.tryParse(_lessonIdController.text.trim());
    }

    int? dialectId;
    if (_dialectIdController.text.trim().isNotEmpty) {
      dialectId = int.tryParse(_dialectIdController.text.trim());
    }

    final payload = TranslationRequestPayload(
      sourceLanguageId: source.id,
      targetLanguageId: target.id,
      sourceText: text,
      lessonId: lessonId,
      dialectId: dialectId,
      sessionTag: _selectedSessionTag,
    );

    try {
      final result = await _apiService.translate(payload);
      if (mounted) {
        setState(() {
          _lastResult = result;
          _isTranslating = false;
        });

        // Trigger background refresh so Translation Library gets updated
        state.refreshAll();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.friendlyMessage;
          _technicalError = e.technicalDetails;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not communicate with the translation service.';
          _technicalError = e.toString();
          _isTranslating = false;
        });
      }
    }
  }

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.create_new_folder_rounded, color: ClassroomColors.terracotta),
              const SizedBox(width: 8),
              Text('Create Topic Folder', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g., Chapter 3 Discussion, Plant Parts...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ClassroomColors.terracotta),
              onPressed: () {
                final tag = controller.text.trim();
                if (tag.isNotEmpty) {
                  setState(() {
                    if (!_sessionTags.contains(tag)) _sessionTags.insert(0, tag);
                    _selectedSessionTag = tag;
                  });
                  _apiService.createSession(tag, tag);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Create Folder', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFolderTagSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_special_rounded, color: ClassroomColors.terracotta, size: 20),
          const SizedBox(width: 10),
          Text(
            'Save to Folder / Topic:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ClassroomColors.textDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _sessionTags.contains(_selectedSessionTag) ? _selectedSessionTag : null,
                hint: Text('Select or create topic folder', style: GoogleFonts.notoSans(fontSize: 12)),
                items: _sessionTags.map((tag) {
                  return DropdownMenuItem<String>(
                    value: tag,
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSessionTag = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.create_new_folder_rounded, color: ClassroomColors.terracotta, size: 20),
            tooltip: 'Create New Lesson Folder',
            onPressed: _showNewFolderDialog,
          ),
        ],
      ),
    );
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
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Teacher Context
                  _buildTitleSection(),

                  const SizedBox(height: 24),

                  // Language Selectors (Source -> Target)
                  _buildLanguageSelectors(state, languages),

                  const SizedBox(height: 16),

                  // Folder / Topic Tag Selector
                  _buildFolderTagSelector(),

                  // Lesson Text Input Area
                  _buildTextInputArea(),

                  const SizedBox(height: 14),

                  // Quick Classroom Sample Phrases
                  _buildSamplePhrases(),

                  const SizedBox(height: 16),

                  // Optional Fields (lesson_id, dialect_id)
                  _buildAdvancedOptions(),

                  const SizedBox(height: 20),

                  // Primary Translate Button
                  _buildTranslateButton(state),

                  // Error Display
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    _buildErrorBox(),
                  ],

                  // Response Display Area
                  if (_lastResult != null) ...[
                    const SizedBox(height: 24),
                    _buildTranslationResultCard(state, _lastResult!),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleSection() {
    return Column(
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
                Icons.edit_note_rounded,
                color: ClassroomColors.terracotta,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Translate a Lesson',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: ClassroomColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Translate primary textbook sentences into your students’ mother tongue dialect. Directly linked to POST /translate.',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: ClassroomColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelectors(ClassroomState state, List<Language> languages) {
    if (languages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ClassroomColors.marigoldLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ClassroomColors.marigold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: ClassroomColors.marigoldDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No languages loaded yet. Please ensure the backend is running to populate language selections dynamically.',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: ClassroomColors.textDark,
                ),
              ),
            ),
            TextButton(
              onPressed: () => state.refreshAll(),
              child: const Text('Fetch Languages'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final sourceDropdown = _buildDropdown(
          label: 'Source Language',
          value: state.selectedSourceLanguage,
          languages: languages,
          onChanged: (lang) => state.selectSourceLanguage(lang),
          accentColor: ClassroomColors.terracotta,
        );

        final targetDropdown = _buildDropdown(
          label: 'Target Mother Tongue',
          value: state.selectedTargetLanguage,
          languages: languages,
          onChanged: (lang) => state.selectTargetLanguage(lang),
          accentColor: ClassroomColors.earthySage,
        );

        if (isNarrow) {
          return Column(
            children: [
              sourceDropdown,
              const SizedBox(height: 8),
              Center(
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.swap_vert_rounded),
                  tooltip: 'Swap source and target languages',
                  onPressed: state.swapLanguages,
                ),
              ),
              const SizedBox(height: 8),
              targetDropdown,
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: sourceDropdown),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.swap_horiz_rounded),
                  tooltip: 'Swap languages',
                  style: IconButton.styleFrom(
                    backgroundColor: ClassroomColors.warmParchment,
                    foregroundColor: ClassroomColors.textDark,
                  ),
                  onPressed: state.swapLanguages,
                ),
              ),
              Expanded(child: targetDropdown),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required Language? value,
    required List<Language> languages,
    required ValueChanged<Language?> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accentColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: ClassroomColors.creamBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ClassroomColors.borderWarm),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Language>(
              isExpanded: true,
              value: value,
              hint: Text(
                'Select language',
                style: GoogleFonts.notoSans(color: ClassroomColors.textSubtle),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: accentColor),
              items: languages.map((lang) {
                return DropdownMenuItem<Language>(
                  value: lang,
                  child: Row(
                    children: [
                      Text(
                        lang.languageName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ClassroomColors.textDark,
                        ),
                      ),
                      if (lang.nativeName.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${lang.nativeName})',
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            color: ClassroomColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClassroomColors.borderWarm, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Classroom Lesson Text',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ClassroomColors.textDark,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_rounded,
                        color: _isListening ? Colors.red : ClassroomColors.terracotta,
                      ),
                      tooltip: _isListening ? 'Listening… Click to stop' : 'Voice Input (Bhashini Speech-to-Text)',
                      onPressed: _toggleListening,
                    ),
                    if (_textController.text.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          _textController.clear();
                          setState(() {});
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: ClassroomColors.textSubtle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _textController,
              maxLines: 5,
              minLines: 4,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.notoSans(
                fontSize: 16,
                color: ClassroomColors.textDark,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Type or paste what you want to teach…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  size: 14,
                  color: ClassroomColors.textSubtle,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_textController.text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length} words',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: ClassroomColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSamplePhrases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Classroom Sentence Suggestions:',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ClassroomColors.textSubtle,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _classroomSamplePhrases.map((phrase) {
            return InkWell(
              onTap: () {
                _textController.text = phrase;
                setState(() {});
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ClassroomColors.warmParchment.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ClassroomColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: ClassroomColors.terracotta,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phrase.length > 36 ? '${phrase.substring(0, 36)}…' : phrase,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: ClassroomColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Container(
      decoration: BoxDecoration(
        color: ClassroomColors.warmParchment.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClassroomColors.borderSubtle),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _showAdvancedOptions
                        ? Icons.expand_less_rounded
                        : Icons.tune_rounded,
                    size: 18,
                    color: ClassroomColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Optional Metadata (Lesson ID & Dialect ID)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ClassroomColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _showAdvancedOptions ? 'Hide' : 'Show',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: ClassroomColors.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showAdvancedOptions)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lessonIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Lesson ID (optional)',
                        hintText: 'e.g. 1',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _dialectIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Dialect ID (optional)',
                        hintText: 'e.g. 1',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTranslateButton(ClassroomState state) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isTranslating ? null : () => _handleTranslate(state),
        style: ElevatedButton.styleFrom(
          backgroundColor: ClassroomColors.terracotta,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isTranslating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Submitting to Classroom Backend…',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.translate_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Translate',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClassroomColors.terracottaLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClassroomColors.terracotta.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: ClassroomColors.terracotta,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Translation Request Failed',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ClassroomColors.terracottaDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              color: ClassroomColors.textDark,
            ),
          ),
          if (_technicalError != null) ...[
            const SizedBox(height: 8),
            Text(
              _technicalError!,
              style: GoogleFonts.firaCode(
                fontSize: 11,
                color: ClassroomColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranslationResultCard(ClassroomState state, TranslationResult result) {
    final isPending = result.isPending;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? ClassroomColors.marigold : ClassroomColors.earthySage,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPending ? ClassroomColors.marigold : ClassroomColors.earthySage)
                .withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isPending
                          ? ClassroomColors.marigoldLight
                          : ClassroomColors.sageLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPending ? Icons.pending_rounded : Icons.check_circle_rounded,
                      color: isPending
                          ? ClassroomColors.marigoldDark
                          : ClassroomColors.earthySage,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isPending ? 'Backend Received Request' : 'Vernacular Translation',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ClassroomColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? ClassroomColors.marigoldLight
                      : ClassroomColors.sageLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Status: ${result.status}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPending
                        ? ClassroomColors.marigoldDark
                        : ClassroomColors.sageDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Original Text
          Text(
            'Source Lesson Text:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ClassroomColors.textSubtle,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ClassroomColors.creamBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ClassroomColors.borderSubtle),
            ),
            child: SelectableText(
              result.sourceText,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: ClassroomColors.textDark,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // PENDING STATE / RESULT DISPLAY (Exact user instructions: do NOT pretend it's translated)
          if (isPending) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ClassroomColors.marigoldLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ClassroomColors.marigold.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.hourglass_empty_rounded,
                        color: ClassroomColors.marigoldDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Translation Pending / AI Service Notice',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ClassroomColors.marigoldDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“Your request reached Bhasha Sangi.\nThe AI translation service is not connected yet.”',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ClassroomColors.textDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The backend recorded this translation with status "${result.status}". When the BHASHINI / NLLB AI service is plugged into the FastAPI backend, this card will dynamically render real-time vernacular dialect sentences without needing frontend code changes.',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: ClassroomColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Translated Output:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ClassroomColors.earthySage,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isPlayingAudio
                      ? _stopAudio
                      : () => _speakTranslatedOutput(result, state),
                  icon: Icon(
                    _isPlayingAudio ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _isPlayingAudio ? 'Stop Audio' : 'Listen in Mother Tongue 🔊',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClassroomColors.earthySage,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ClassroomColors.sageLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                result.translatedText,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ClassroomColors.textDark,
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ClassroomColors.terracottaLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_rounded, size: 14, color: ClassroomColors.terracotta),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Folder: $_selectedSessionTag',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ClassroomColors.terracottaDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigate(AppRouteItem.lessons),
                icon: const Icon(Icons.library_books_rounded, size: 16),
                label: const Text('View in Library'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
