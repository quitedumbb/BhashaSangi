import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/language.dart';
import '../models/learning_card.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../state/classroom_state.dart';
import '../widgets/app_drawer.dart';

enum CardDisplayMode { flashcard, gridList }

class LearningCardsScreen extends StatefulWidget {
  final ValueChanged<AppRouteItem> onNavigate;

  const LearningCardsScreen({super.key, required this.onNavigate});

  @override
  State<LearningCardsScreen> createState() => _LearningCardsScreenState();
}

class _LearningCardsScreenState extends State<LearningCardsScreen> {
  final ApiService _apiService = ApiService();

  List<LearningCard> _cards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isFlipped = false;
  CardDisplayMode _displayMode = CardDisplayMode.flashcard;
  int _selectedLanguageId = 1; // 1 = Santali
  String? _playingWordAudio;

  final Set<int> _masteredCardIds = {};

  @override
  void initState() {
    super.initState();
    _loadDailyCards();
  }

  @override
  void dispose() {
    VoiceService.instance.stopAudio();
    super.dispose();
  }

  Future<void> _loadDailyCards({bool shuffle = false}) async {
    setState(() => _isLoading = true);
    try {
      final cards = await _apiService.getDailyLearningCards(
        targetLanguageId: _selectedLanguageId,
        count: 10,
        shuffle: shuffle,
      );
      if (mounted) {
        setState(() {
          _cards = cards;
          _currentIndex = 0;
          _isFlipped = false;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playPronunciation(String text, String langCode, String identifier) async {
    if (_playingWordAudio == identifier) {
      VoiceService.instance.stopAudio();
      setState(() => _playingWordAudio = null);
      return;
    }

    setState(() => _playingWordAudio = identifier);

    // Call Bhashini TTS
    final audioBase64 = await _apiService.getCardAudio(
      text: text,
      languageCode: langCode,
    );

    if (audioBase64 != null && mounted) {
      VoiceService.instance.playBase64Audio(
        audioBase64,
        onDone: () {
          if (mounted) setState(() => _playingWordAudio = null);
        },
        onError: () {
          if (mounted) setState(() => _playingWordAudio = null);
        },
      );
    } else {
      if (mounted) {
        setState(() => _playingWordAudio = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio pronunciation not available.')),
        );
      }
    }
  }

  void _showAddCustomWordDialog() {
    final wordController = TextEditingController();
    String category = 'Classroom Learning';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: ClassroomColors.terracotta),
                  const SizedBox(width: 8),
                  Text('Translate Any Word (Bhashini)', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter any English word. Bhashini will translate it to Santali (Ol Chiki) and Hindi with example sentences.',
                    style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: wordController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'English Word',
                      hintText: 'e.g., Butterfly, Rainbow, Mountain...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Classroom Learning', child: Text('Classroom Learning')),
                      DropdownMenuItem(value: 'Nature & Science', child: Text('Nature & Science')),
                      DropdownMenuItem(value: 'Everyday Actions', child: Text('Everyday Actions')),
                      DropdownMenuItem(value: 'Food & Nutrition', child: Text('Food & Nutrition')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => category = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: ClassroomColors.terracotta),
                  onPressed: () async {
                    final word = wordController.text.trim();
                    if (word.isEmpty) return;

                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Translating "$word" with Bhashini IndicTrans-v2…')),
                    );

                    final newCard = await _apiService.createCustomLearningCard(
                      wordEn: word,
                      targetLanguageId: _selectedLanguageId,
                      category: category,
                    );

                    if (!mounted) return;
                    if (newCard != null) {
                      setState(() {
                        _cards.insert(0, newCard);
                        _currentIndex = 0;
                        _isFlipped = false;
                      });
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Added "${newCard.wordEn}" (${newCard.wordVernacular}) to daily cards!'),
                          backgroundColor: ClassroomColors.earthySage,
                        ),
                      );
                    }
                  },
                  child: const Text('Translate & Add Card', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
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
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildControlsBar(languages),
                  const SizedBox(height: 20),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: ClassroomColors.terracotta),
                      ),
                    )
                  else if (_cards.isEmpty)
                    _buildEmptyState()
                  else if (_displayMode == CardDisplayMode.flashcard)
                    _buildInteractiveFlipCard()
                  else
                    _buildGridListView(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final masteredCount = _masteredCardIds.length;
    final total = _cards.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ClassroomColors.terracottaLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.style_rounded,
                color: ClassroomColors.terracotta,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Learning Cards (10 Words / Day)',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ClassroomColors.textDark,
                  ),
                ),
                Text(
                  'English → Santali (Ol Chiki) & Hindi vocabulary with Bhashini speech.',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: ClassroomColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (total > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ClassroomColors.sageLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ClassroomColors.earthySage.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: ClassroomColors.earthySage, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$masteredCount of $total Mastered',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: ClassroomColors.earthySage),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControlsBar(List<Language> languages) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClassroomColors.borderWarm),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Target Language Selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate_rounded, color: ClassroomColors.terracotta, size: 18),
              const SizedBox(width: 8),
              Text('Language:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedLanguageId,
                  items: languages.map((l) {
                    return DropdownMenuItem<int>(
                      value: l.id,
                      child: Text(
                        '${l.languageName} (${l.script})',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLanguageId = val);
                      _loadDailyCards();
                    }
                  },
                ),
              ),
            ],
          ),

          // Display Mode & Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Mode Toggle
              SegmentedButton<CardDisplayMode>(
                segments: const [
                  ButtonSegment(
                    value: CardDisplayMode.flashcard,
                    label: Text('Flip Card'),
                    icon: Icon(Icons.flip_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: CardDisplayMode.gridList,
                    label: Text('All 10 Cards'),
                    icon: Icon(Icons.grid_view_rounded, size: 16),
                  ),
                ],
                selected: {_displayMode},
                onSelectionChanged: (set) => setState(() => _displayMode = set.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _loadDailyCards(shuffle: true),
                icon: const Icon(Icons.shuffle_rounded, size: 16),
                label: const Text('10 New Words 🎲'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClassroomColors.terracottaDark,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCustomWordDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Translate Word ➕'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClassroomColors.terracotta,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- FLASHCARD VIEW ---
  Widget _buildInteractiveFlipCard() {
    final card = _cards[_currentIndex];
    final isMastered = _masteredCardIds.contains(card.id);

    return Column(
      children: [
        // Top Card Meta Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ClassroomColors.marigoldLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.category,
                style: ClassroomTheme.highlightFont(fontSize: 11, fontWeight: FontWeight.w700, color: ClassroomColors.marigoldDark),
              ),
            ),
            Text(
              'Card ${_currentIndex + 1} of ${_cards.length}',
              style: ClassroomTheme.highlightFont(fontSize: 12, fontWeight: FontWeight.w600, color: ClassroomColors.textSubtle),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Flip Card Main Container
        InkWell(
          onTap: () => setState(() => _isFlipped = !_isFlipped),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 300),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _isFlipped ? ClassroomColors.sageLight.withOpacity(0.65) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isFlipped ? ClassroomColors.earthySage.withOpacity(0.5) : ClassroomColors.borderWarm,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isFlipped) ...[
                  // FRONT OF CARD: English
                  Text(
                    'ENGLISH WORD',
                    style: ClassroomTheme.highlightFont(fontSize: 12, fontWeight: FontWeight.w700, color: ClassroomColors.terracotta, letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card.wordEn,
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: ClassroomColors.textDark,
                    ),
                  ),
                  if (card.exampleSentenceEn.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: ClassroomColors.creamBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '"${card.exampleSentenceEn}"',
                        style: GoogleFonts.notoSans(fontSize: 13, fontStyle: FontStyle.italic, color: ClassroomColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_rounded, size: 16, color: ClassroomColors.textSubtle),
                      const SizedBox(width: 6),
                      Text(
                        'Tap card to reveal Santali (Ol Chiki) & Hindi translation',
                        style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w500, color: ClassroomColors.textSubtle),
                      ),
                    ],
                  ),
                ] else ...[
                  // BACK OF CARD: Santali + Hindi + Audio
                  Text(
                    '${card.targetLanguageName.toUpperCase()} & HINDI TRANSLATION',
                    style: ClassroomTheme.highlightFont(fontSize: 12, fontWeight: FontWeight.w700, color: ClassroomColors.earthySage, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 14),

                  // Vernacular Word in Ol Chiki
                  SelectableText(
                    card.wordVernacular,
                    style: GoogleFonts.poppins(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: ClassroomColors.textDark,
                    ),
                  ),
                  if (card.romanPhonetic.isNotEmpty) ...[
                    Text(
                      'Phonetic: ${card.romanPhonetic} • ${card.targetLanguageScript}',
                      style: ClassroomTheme.highlightFont(fontSize: 13, fontWeight: FontWeight.w600, color: ClassroomColors.textMuted),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Hindi Word
                  Text(
                    'हिन्दी: ${card.wordHi}',
                    style: GoogleFonts.notoSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ClassroomColors.terracottaDark,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Audio Pronunciation Controls
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _playPronunciation(card.wordVernacular, card.targetLanguageCode, '${card.id}_ver'),
                        icon: Icon(
                          _playingWordAudio == '${card.id}_ver' ? Icons.stop_rounded : Icons.volume_up_rounded,
                          size: 16,
                        ),
                        label: Text('Listen in ${card.targetLanguageName} 🔊', style: GoogleFonts.poppins(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ClassroomColors.earthySage,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _playPronunciation(card.wordHi, 'hi', '${card.id}_hi'),
                        icon: Icon(
                          _playingWordAudio == '${card.id}_hi' ? Icons.stop_rounded : Icons.volume_up_rounded,
                          size: 16,
                        ),
                        label: Text('Listen in Hindi 🔊', style: GoogleFonts.poppins(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ClassroomColors.terracottaDark,
                        ),
                      ),
                    ],
                  ),

                  if (card.exampleSentenceVernacular.isNotEmpty || card.exampleSentenceHi.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          if (card.exampleSentenceVernacular.isNotEmpty)
                            Text(
                              card.exampleSentenceVernacular,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(fontSize: 14, fontWeight: FontWeight.w600, color: ClassroomColors.textDark),
                            ),
                          if (card.exampleSentenceHi.isNotEmpty)
                            Text(
                              card.exampleSentenceHi,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Navigation & Mastered Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: _currentIndex > 0
                  ? () => setState(() {
                        _currentIndex--;
                        _isFlipped = false;
                      })
                  : null,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Previous'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  if (isMastered) {
                    _masteredCardIds.remove(card.id);
                  } else {
                    _masteredCardIds.add(card.id);
                  }
                });
              },
              icon: Icon(
                isMastered ? Icons.check_circle_rounded : Icons.star_border_rounded,
                size: 16,
              ),
              label: Text(isMastered ? 'Mastered ⭐' : 'Mark Mastered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isMastered ? ClassroomColors.earthySage : ClassroomColors.terracotta,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _currentIndex < _cards.length - 1
                  ? () => setState(() {
                        _currentIndex++;
                        _isFlipped = false;
                      })
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Next Card'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ClassroomColors.slateChalkboard,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- ALL 10 CARDS GRID/LIST VIEW ---
  Widget _buildGridListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s 10 Vocabulary Words (English • Santali • Hindi):',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: ClassroomColors.textDark),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cards.length,
          itemBuilder: (context, index) {
            final card = _cards[index];
            final isMastered = _masteredCardIds.contains(card.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ClassroomColors.borderWarm),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ClassroomColors.warmParchment,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: ClassroomColors.terracotta),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              card.wordEn,
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: ClassroomColors.textDark),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ClassroomColors.sageLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                card.category,
                                style: GoogleFonts.notoSans(fontSize: 10, fontWeight: FontWeight.w600, color: ClassroomColors.earthySage),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Santali: ',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: ClassroomColors.textMuted),
                            ),
                            Text(
                              card.wordVernacular,
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: ClassroomColors.terracottaDark),
                            ),
                            if (card.romanPhonetic.isNotEmpty) ...[
                              Text(' (${card.romanPhonetic})', style: GoogleFonts.notoSans(fontSize: 12, color: ClassroomColors.textSubtle)),
                            ],
                            const SizedBox(width: 12),
                            Text(
                              'Hindi: ',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: ClassroomColors.textMuted),
                            ),
                            Text(
                              card.wordHi,
                              style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600, color: ClassroomColors.textDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _playingWordAudio == '${card.id}_ver' ? Icons.stop_rounded : Icons.volume_up_rounded,
                          color: ClassroomColors.earthySage,
                        ),
                        tooltip: 'Pronounce in ${card.targetLanguageName}',
                        onPressed: () => _playPronunciation(card.wordVernacular, card.targetLanguageCode, '${card.id}_ver'),
                      ),
                      IconButton(
                        icon: Icon(
                          isMastered ? Icons.star_rounded : Icons.star_border_rounded,
                          color: isMastered ? ClassroomColors.earthySage : ClassroomColors.textSubtle,
                        ),
                        tooltip: isMastered ? 'Mastered' : 'Mark as Mastered',
                        onPressed: () {
                          setState(() {
                            if (isMastered) {
                              _masteredCardIds.remove(card.id);
                            } else {
                              _masteredCardIds.add(card.id);
                            }
                          });
                        },
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.style_outlined, size: 48, color: ClassroomColors.textSubtle),
            const SizedBox(height: 14),
            Text('No learning cards loaded', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadDailyCards(),
              child: const Text('Load 10 Daily Cards'),
            ),
          ],
        ),
      ),
    );
  }
}
