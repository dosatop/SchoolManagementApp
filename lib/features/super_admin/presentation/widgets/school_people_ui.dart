import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ====================================================================
// SHARED UI — super admin school teachers / students / classes pages
// ====================================================================
// Same look as SchoolManagementPage: navy primary, soft grey
// background, white cards with a hairline border.

class SpColors {
  static const primary = Color(0xFF091993);
  static const primaryLight = Color(0xFF2638C4);
  static const background = Color(0xFFF6F7FB);
  static const textDark = Color(0xFF20232E);
  static const textSoft = Color(0xFF6B7080);
  static const border = Color(0xFFE8EAF0);
  static const field = Color(0xFFF1F2F7);

  static const green = Color(0xFF16A34A);
  static const orange = Color(0xFFEA8A0C);
  static const purple = Color(0xFF7C3AED);
  static const blue = Color(0xFF2563EB);
  static const teal = Color(0xFF0D9488);
  static const red = Color(0xFFDC2626);

  static const _palette = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF0D9488),
    Color(0xFFEA8A0C),
    Color(0xFFDB2777),
    Color(0xFF16A34A),
    Color(0xFF0891B2),
    Color(0xFF9333EA),
  ];

  /// Stable colour per name, so a person keeps the same avatar colour.
  static Color forName(String name) {
    var hash = 0;
    for (final c in name.toLowerCase().codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }
}

String spInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

bool spMatches(String query, List<String?> fields) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  for (final f in fields) {
    if (f != null && f.toLowerCase().contains(q)) return true;
  }
  return false;
}

// ====================================================================
// APP BAR
// ====================================================================

PreferredSizeWidget spAppBar({
  required BuildContext context,
  required String title,
  required String schoolName,
  VoidCallback? onRefresh,
  bool refreshing = false,
}) {
  return AppBar(
    elevation: 0,
    scrolledUnderElevation: 0.5,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    foregroundColor: SpColors.textDark,
    titleSpacing: 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: SpColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          schoolName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SpColors.textSoft,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: refreshing
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: SpColors.primary,
                  ),
                ),
              )
            : IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
      ),
    ],
  );
}

// ====================================================================
// SUMMARY CARD (gradient hero)
// ====================================================================

class SpStat {
  final String label;
  final String value;
  const SpStat(this.label, this.value);
}

class SpSummaryCard extends StatelessWidget {
  const SpSummaryCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.stats = const [],
  });

  final IconData icon;
  final String value;
  final String label;
  final List<SpStat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SpColors.primary, SpColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: SpColors.primary.withOpacity(.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0)
                          Container(
                            width: 1,
                            height: 26,
                            color: Colors.white.withOpacity(.16),
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                stats[i].value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stats[i].label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.7),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// SEARCH FIELD
// ====================================================================

class SpSearchField extends StatelessWidget {
  const SpSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14, color: SpColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: SpColors.textSoft, fontSize: 13.5),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: SpColors.textSoft,
              size: 21,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 19),
                    color: SpColors.textSoft,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: SpColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: SpColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: SpColors.primary, width: 1.4),
            ),
          ),
        );
      },
    );
  }
}

// ====================================================================
// FILTER CHIPS (horizontal)
// ====================================================================

class SpFilter {
  final String key;
  final String label;
  final int? count;
  const SpFilter(this.key, this.label, [this.count]);
}

class SpFilterChips extends StatelessWidget {
  const SpFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<SpFilter> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final active = f.key == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(f.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? SpColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? SpColors.primary : SpColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f.label,
                    style: TextStyle(
                      color: active ? Colors.white : SpColors.textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (f.count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withOpacity(.2)
                            : SpColors.field,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${f.count}',
                        style: TextStyle(
                          color: active ? Colors.white : SpColors.textSoft,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ====================================================================
// AVATAR / TAG / CARD
// ====================================================================

class SpAvatar extends StatelessWidget {
  const SpAvatar({super.key, required this.name, this.size = 46, this.text});

  final String name;
  final double size;

  /// Override the initials (e.g. a class short name).
  final String? text;

  @override
  Widget build(BuildContext context) {
    final color = SpColors.forName(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, .18)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Text(
        text ?? spInitials(name),
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * (text != null && text!.length > 3 ? .26 : .34),
          fontWeight: FontWeight.bold,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class SpTag extends StatelessWidget {
  const SpTag(this.text, {super.key, this.color = SpColors.textSoft, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpCard extends StatelessWidget {
  const SpCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SpColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2559).withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SpSectionTitle extends StatelessWidget {
  const SpSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: SpColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: SpColors.textSoft,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// ====================================================================
// LOADING (pulsing skeleton)
// ====================================================================

class SpLoadingList extends StatefulWidget {
  const SpLoadingList({super.key});

  @override
  State<SpLoadingList> createState() => _SpLoadingListState();
}

class _SpLoadingListState extends State<SpLoadingList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, [double r = 8]) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: SpColors.field,
      borderRadius: BorderRadius.circular(r),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: .45, end: 1.0).animate(_c),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _box(double.infinity, 150, 22),
          const SizedBox(height: 16),
          _box(double.infinity, 48, 15),
          const SizedBox(height: 12),
          Row(
            children: [
              _box(70, 34, 20),
              const SizedBox(width: 8),
              _box(110, 34, 20),
              const SizedBox(width: 8),
              _box(90, 34, 20),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 6; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: SpColors.border),
              ),
              child: Row(
                children: [
                  _box(46, 46, 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(140, 13),
                        const SizedBox(height: 8),
                        _box(200, 10),
                        const SizedBox(height: 8),
                        _box(90, 18, 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ====================================================================
// EMPTY / ERROR
// ====================================================================

class SpMessageView extends StatelessWidget {
  const SpMessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = SpColors.primary,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.refresh_rounded,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  /// Inside a list (no full-height centering).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: compact ? 36 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SpColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SpColors.textSoft,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: SpColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (compact) return content;
    return Center(child: SingleChildScrollView(child: content));
  }
}

// ====================================================================
// BOTTOM SHEET
// ====================================================================

Future<T?> showSpSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext, ScrollController) builder,
  double initialSize = .62,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      minChildSize: .35,
      maxChildSize: .94,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: SpColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFD5D8E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(child: builder(context, controller)),
          ],
        ),
      ),
    ),
  );
}

/// Name + subtitle header used at the top of each details sheet.
class SpSheetHeader extends StatelessWidget {
  const SpSheetHeader({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatarText,
    this.tags = const [],
  });

  final String name;
  final String subtitle;
  final String? avatarText;
  final List<Widget> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SpAvatar(name: name, size: 72, text: avatarText),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SpColors.textDark,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: SpColors.textSoft, fontSize: 12.5),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: tags,
          ),
        ],
      ],
    );
  }
}

/// White grouped block of rows inside a sheet.
class SpGroup extends StatelessWidget {
  const SpGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(
          const Divider(height: 1, indent: 62, color: SpColors.border),
        );
      }
      items.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SpColors.border),
      ),
      child: Column(children: items),
    );
  }
}

/// A label/value row. Long-press or tap the copy icon to copy.
class SpInfoRow extends StatelessWidget {
  const SpInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.color = SpColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final Color color;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label copied'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: copyable ? () => _copy(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: SpColors.textSoft,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: SpColors.textDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (copyable)
              IconButton(
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                onPressed: () => _copy(context),
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 17,
                  color: SpColors.textSoft,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small stat tile used in a row inside sheets.
class SpMiniStat extends StatelessWidget {
  const SpMiniStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: SpColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SpColors.textSoft,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// ERROR BANNER (refresh failed but old data is still shown)
// ====================================================================

class SpErrorBanner extends StatelessWidget {
  const SpErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SpColors.red.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SpColors.red.withOpacity(.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: SpColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing saved list. $message',
              style: const TextStyle(color: SpColors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
