import 'package:flutter/material.dart';

/// Bar filter horizontal: chip "Semua" + opsi filter.
///
/// [options]: daftar `(label, value)` — value `null` mewakili opsi "Semua".
/// [selected]: value yang sedang aktif.
/// [onSelected]: dipanggil saat chip ditekan.
class FilterChipBar<T> extends StatelessWidget {
  final List<({String label, T value})> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final Color? activeColor;

  const FilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = activeColor ?? cs.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            _chip(context, options[i], accent),
            if (i < options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, ({String label, T value}) option, Color accent) {
    final cs = Theme.of(context).colorScheme;
    final isActive = option.value == selected;

    return GestureDetector(
      onTap: () => onSelected(option.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? accent.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? accent : cs.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          option.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? accent : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Chip kecil yang menampilkan filter aktif + tombol reset (✕).
class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  final Color? color;

  const ActiveFilterChip({
    super.key,
    required this.label,
    required this.onClear,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_rounded, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 14, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper: helper untuk ikon filter di header (abstraksi umum).
class FilterIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;

  const FilterIconButton({
    super.key,
    required this.onPressed,
    required this.isActive,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = activeColor ?? Theme.of(context).colorScheme.primary;
    return IconButton(
      onPressed: onPressed,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
          size: 20,
          color: isActive ? accent : Colors.white,
        ),
      ),
      tooltip: 'Filter',
    );
  }
}
