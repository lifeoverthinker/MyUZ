import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_uz/icons/my_uz_icons.dart';
import 'package:my_uz/theme/app_colors.dart';
import 'package:my_uz/theme/text_style.dart';

// MODELE
import 'package:my_uz/models/class_model.dart';
import 'package:my_uz/models/task_model.dart';

// SEKCJE
import 'components/upcoming_classes.dart';
import 'components/tasks_section.dart';
import 'components/events_section.dart';

/// HomeScreen – Dashboard (Figma – obraz 4)
/// (uproszczona wersja – tylko mocki lokalne, bez repo / dodatkowych plików)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Klucze personalizacji
const String _kPrefOnbMode = 'onb_mode';
const String _kPrefOnbSalutation = 'onb_salutation';
const String _kPrefOnbFirst = 'onb_first';

class _HomeScreenState extends State<HomeScreen> {
  String _greetingName = 'Student';
  bool _loading = true; // ładowanie prefów

  late List<ClassModel> _classes;
  late final List<TaskModel> _tasks;
  late final List<EventModel> _events;

  @override
  void initState() {
    super.initState();
    _buildMocks();
    _loadPrefs();
  }

  void _buildMocks() {
    final now = DateTime.now();
    _classes = [
      ClassModel(
        id: 'c1',
        subject: 'Podstawy systemów dyskretnych',
        room: 'Sala 102',
        lecturer: 'dr A. Nowak',
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        endTime: DateTime(now.year, now.month, now.day, 10, 45),
      ),
      ClassModel(
        id: 'c2',
        subject: 'Analiza matematyczna II',
        room: 'A-29, s. 305',
        lecturer: 'prof. B. Kowalski',
        startTime: DateTime(now.year, now.month, now.day, 11, 0),
        endTime: DateTime(now.year, now.month, now.day, 12, 30),
      ),
      ClassModel(
        id: 'c3',
        subject: 'Programowanie obiektowe',
        room: 'Lab 205',
        lecturer: 'mgr C. Zieliński',
        startTime: DateTime(now.year, now.month, now.day, 13, 15),
        endTime: DateTime(now.year, now.month, now.day, 14, 45),
      ),
    ];
    final now2 = now;
    _tasks = [
      TaskModel(
        id: 't1',
        title: 'Projekt zaliczeniowy',
        subject: 'PPO',
        deadline: now2.add(const Duration(days: 3)),
      ),
      TaskModel(
        id: 't2',
        title: 'Kolokwium – Algebra',
        subject: 'Algebra',
        deadline: now2.add(const Duration(days: 5)),
      ),
      TaskModel(
        id: 't3',
        title: 'Sprawozdanie z laboratorium',
        subject: 'Fizyka',
        deadline: now2.add(const Duration(days: 6)),
      ),
    ];
    _events = const [
      EventModel(id: 'e1', title: 'Juwenalia 2025', description: 'Koncerty i atrakcje na kampusie.'),
      EventModel(id: 'e2', title: 'Dzień sportu', description: 'Turniej siatkówki + biegi.'),
      EventModel(id: 'e3', title: 'Hackathon UZ', description: '24h kodowania – zgłoś zespół.'),
    ];
  }

  Future<void> _loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final mode = p.getString(_kPrefOnbMode);
      final first = p.getString(_kPrefOnbFirst)?.trim();
      final sal = p.getString(_kPrefOnbSalutation)?.trim();
      String name = 'Student';
      if (mode == 'data' && first != null && first.isNotEmpty) {
        name = first;
      } else if (sal != null && sal.isNotEmpty) {
        name = sal;
      }
      if (!mounted) return;
      setState(() {
        _greetingName = name;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const double _footerTopSpacing = 10; // Figma: odstęp treści od stopki
    return Container(
      // Root na biało, żeby przy overscrollu na dole NIE było widać powierzchni tła (#FEF7FF)
      color: Colors.white,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const ClampingScrollPhysics(), // brak bounce = brak "prześwitu" na dole
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: cs.surface, // tylko header ma kolor surface
                    child: _Header(
                      dateText: _plDate(DateTime.now()),
                      greetingName: _greetingName,
                    ),
                  ),
                ),
                // Biała sekcja aż do dołu
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ContentContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UpcomingClassesSection(
                          classes: _classes,
                          onTap: _onTapClass,
                        ),
                        const SizedBox(height: 12),
                        TasksSection(
                          tasks: _tasks,
                          onTap: _onTapTask,
                        ),
                        const SizedBox(height: 12),
                        EventsSection(
                          events: _events,
                          onTap: _onTapEvent,
                        ),
                        const SizedBox(height: _footerTopSpacing),
                        _Footer(color: AppColors.myUZSysLightOutline),
                        const SizedBox(height: kBottomNavigationBarHeight + 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _onTapClass(ClassModel c) => debugPrint('[Home] class tap ${c.id}');
  void _onTapTask(TaskModel t) => debugPrint('[Home] task tap ${t.id}');
  void _onTapEvent(EventModel e) => debugPrint('[Home] event tap ${e.id}');
}

/// HEADER – SafeArea + spacing z Figmy
class _Header extends StatelessWidget {
  final String dateText;
  final String greetingName;
  const _Header({required this.dateText, required this.greetingName});

  static const double _hPad = 16;
  static const double _topAfterSafe = 8;
  static const double _dateToGreeting = 20;
  static const double _greetingToSubtitle = 4;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, _topAfterSafe, _hPad, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + actions
            Container(
              width: 360,
              child: Row(
                mainAxisSize: MainAxisSize.max, // hug szerokość
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      dateText,
                      style: AppTextStyle.myUZLabelLarge.copyWith(
                        color: const Color(0xFF1D192B),
                        height: 1.43,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16), // odstęp od ikonek
                  Row(
                    children: [
                      // Przycisk mapa
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Container(
                          width: 40,
                          height: 40,
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE8DEF8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: Center(
                            child: Icon(MyUz.map_02, size: 24, color: Color(0xFF1D192B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Przycisk mail z kropką
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              clipBehavior: Clip.antiAlias,
                              decoration: ShapeDecoration(
                                color: const Color(0xFFE8DEF8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: Center(
                                child: Icon(MyUz.mail_01, size: 24, color: Color(0xFF1D192B)),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: ShapeDecoration(
                                  color: const Color(0xFFB3261E),
                                  shape: OvalBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: _dateToGreeting),
            Text(
              'Cześć, $greetingName 👋',
              style: AppTextStyle.myUZHeadlineMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: _greetingToSubtitle),
            Text(
              'UZ, Wydział Informatyki',
              style: AppTextStyle.myUZBodySmall.copyWith(
                color: cs.onSurfaceVariant,
                height: 2, // 12px * 2 = 24px jak w Figmie
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Biały panel z zaokrąglonym topem
class _ContentContainer extends StatelessWidget {
  final Widget child;
  const _ContentContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Figma: #FFFFFF
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(top: 24, bottom: 0), // bottom 0 – kontrola spacingu w Column
      child: child,
    );
  }
}

class _Footer extends StatelessWidget {
  final Color color;
  const _Footer({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'MyUZ 2025',
        style: AppTextStyle.myUZLabelLarge.copyWith(
          fontSize: 14,
          height: 1.14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Okrągły przycisk 48x48 (SecondaryContainer)
class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;
  const _ActionCircle({required this.icon, this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final btn = Material(
      color: cs.secondaryContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 24, color: cs.onSecondaryContainer),
        ),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

/// Data PL: Wtorek, 16 lipca
String _plDate(DateTime d) {
  const dni = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'];
  const mies = [
    'stycznia',
    'lutego',
    'marca',
    'kwietnia',
    'maja',
    'czerwca',
    'lipca',
    'sierpnia',
    'września',
    'października',
    'listopada',
    'grudnia'
  ];
  return '${dni[d.weekday - 1]}, ${d.day} ${mies[d.month - 1]}';
}