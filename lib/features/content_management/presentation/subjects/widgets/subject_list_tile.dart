// lib/features/content_management/presentation/subjects/widgets/subject_list_tile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../application/subject_provider.dart';
import '../../../domain/models/subject_model.dart';
import '../../discussions/utils/repetition_code_utils.dart';

class SubjectListTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final VoidCallback onToggleVisibility;
  final VoidCallback onLinkPath;
  final VoidCallback onEditIndexFile;
  final VoidCallback onMove;
  final VoidCallback onToggleFreeze;
  final VoidCallback onToggleLock;
  final VoidCallback onTimeline;
  final VoidCallback onViewJson;
  final bool isFocused;

  const SubjectListTile({
    super.key,
    required this.subject,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    required this.onToggleVisibility,
    required this.onLinkPath,
    required this.onEditIndexFile,
    required this.onMove,
    required this.onToggleFreeze,
    required this.onToggleLock,
    required this.onTimeline,
    required this.onViewJson,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);
    final theme = Theme.of(context);
    final bool hasSubtitle =
        subject.date != null || subject.repetitionCode != null;
    final bool isHidden = subject.isHidden;
    final bool isFrozen = subject.isFrozen;
    final bool isLocked = subject.isLocked;
    final bool isSelected = provider.selectedSubjects.contains(subject);

    final Color cardColor = isSelected
        ? theme.primaryColor.withOpacity(0.2)
        : (isHidden
              ? theme.disabledColor.withOpacity(0.1)
              : (isFrozen
                    ? Colors.lightBlue.shade50
                    : (isLocked ? Colors.grey.shade300 : theme.cardColor)));
    final Color? textColor = isHidden
        ? theme.disabledColor
        : (isLocked ? Colors.grey.shade700 : null);
    final double elevation = isHidden ? 1 : 3;

    final double verticalMargin = 8;
    final double horizontalMargin = 16;
    final EdgeInsets padding = const EdgeInsets.all(16.0);
    final double iconFontSize = 28;
    final double titleFontSize = 18;

    // === PERBAIKAN UTAMA: Hitung Ukuran Ikon ===
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double basePopupIconSize = 24.0;
    const double baseLinkIconSize = 18.0; // Ukuran dasar ikon link
    final scaledPopupIconSize = basePopupIconSize * textScaleFactor;
    final scaledLinkIconSize =
        baseLinkIconSize * textScaleFactor; // Ukuran link diskalakan
    // === AKHIR PERBAIKAN ===

    final tileContent = Material(
      borderRadius: BorderRadius.circular(15),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => provider.toggleSubjectSelection(subject),
        borderRadius: BorderRadius.circular(15),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.shade400
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.primaryColor,
                        size: iconFontSize,
                      )
                    else
                      Text(
                        isLocked ? '🔒' : subject.icon,
                        style: TextStyle(
                          fontSize: iconFontSize,
                          color: textColor,
                        ),
                      ),
                    if (isFrozen && !isSelected)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Icon(
                          Icons.ac_unit,
                          color: Colors.blue.shade700,
                          size:
                              16 * textScaleFactor, // Skalakan ikon kecil juga
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (subject.linkedPath != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.link,
                              color: theme.primaryColor,
                              // Terapkan ukuran ikon link yang diskalakan
                              size: scaledLinkIconSize,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            subject.name,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 4),
                      _buildSubtitle(context, textColor),
                    ],
                    const SizedBox(height: 6),
                    _buildStatsRow(context, textColor),
                  ],
                ),
              ),
              if (!provider.isSelectionMode)
                PopupMenuButton<String>(
                  // Terapkan ukuran ikon titik tiga yang sudah diskalakan
                  iconSize: scaledPopupIconSize,
                  onSelected: (value) {
                    if (value == 'rename') onRename();
                    if (value == 'delete') onDelete();
                    if (value == 'change_icon') onIconChange();
                    if (value == 'toggle_visibility') onToggleVisibility();
                    if (value == 'link_path') onLinkPath();
                    if (value == 'edit_index') onEditIndexFile();
                    if (value == 'move') onMove();
                    if (value == 'toggle_freeze') onToggleFreeze();
                    if (value == 'toggle_lock') onToggleLock();
                    if (value == 'timeline') onTimeline();
                    if (value == 'view_json') onViewJson();
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    _buildMenuItem(
                      'timeline',
                      Icons.timeline,
                      'Lihat Linimasa',
                    ),
                    _buildMenuItem('move', Icons.move_up_outlined, 'Pindahkan'),
                    const PopupMenuDivider(),
                    _buildSubMenu(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      children: [
                        _buildMenuItem(
                          'rename',
                          Icons.drive_file_rename_outline,
                          'Ubah Nama',
                        ),
                        _buildMenuItem(
                          'change_icon',
                          Icons.emoji_emotions_outlined,
                          'Ubah Ikon',
                        ),
                      ],
                    ),
                    _buildSubMenu(
                      icon: Icons.link_outlined,
                      label: 'File & Tautan',
                      children: [
                        if (subject.linkedPath != null &&
                            subject.linkedPath!.isNotEmpty)
                          _buildMenuItem(
                            'edit_index',
                            Icons.code_outlined,
                            'Edit Template Induk',
                          ),
                        _buildMenuItem(
                          'link_path',
                          subject.linkedPath == null
                              ? Icons.link_outlined
                              : Icons.link_off_outlined,
                          subject.linkedPath == null
                              ? 'Link ke PerpusKu'
                              : 'Ubah Link PerpusKu',
                        ),
                        _buildMenuItem(
                          'view_json',
                          Icons.data_object,
                          'Lihat JSON Mentah',
                        ),
                      ],
                    ),
                    _buildSubMenu(
                      icon: Icons.settings_outlined,
                      label: 'Status',
                      children: [
                        _buildMenuItem(
                          'toggle_freeze',
                          isFrozen ? Icons.play_arrow_outlined : Icons.ac_unit,
                          isFrozen ? 'Unfreeze' : 'Freeze',
                        ),
                        _buildMenuItem(
                          'toggle_visibility',
                          isHidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          isHidden ? 'Tampilkan' : 'Sembunyikan',
                        ),
                        _buildMenuItem(
                          'toggle_lock',
                          isLocked
                              ? Icons.lock_open_outlined
                              : Icons.lock_outline,
                          isLocked ? 'Buka Kunci' : 'Kunci Subject',
                        ),
                      ],
                    ),
                    const PopupMenuDivider(),
                    _buildMenuItem(
                      'delete',
                      Icons.delete_outline,
                      'Hapus',
                      color: Colors.red,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    return Card(
      elevation: elevation,
      color: cardColor,
      margin: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: verticalMargin,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isFocused
            ? BorderSide(color: theme.primaryColor, width: 2.5)
            : BorderSide.none,
      ),
      child: tileContent,
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  PopupMenuEntry<String> _buildSubMenu({
    required IconData icon,
    required String label,
    required List<PopupMenuEntry<String>> children,
  }) {
    return PopupMenuItem(
      padding: EdgeInsets.zero,
      enabled: false,
      child: SubmenuButton(
        menuChildren: children,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [Icon(icon), const SizedBox(width: 12), Text(label)],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Color? textColor) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: textColor);
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    final displayOrder = provider.repetitionCodeDisplayOrder;

    final codeEntries = subject.repetitionCodeCounts.entries.toList()
      ..sort((a, b) {
        int indexA = displayOrder.indexOf(a.key);
        int indexB = displayOrder.indexOf(b.key);
        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;
        return indexA.compareTo(indexB);
      });

    // Skalakan ukuran ikon statistik
    final double scaledStatIconSize = (textStyle?.fontSize ?? 12.0);

    return Row(
      children: [
        Icon(
          Icons.chat_bubble_outline,
          size: scaledStatIconSize,
          color: textColor,
        ), // Gunakan ukuran ikon yang diskalakan
        const SizedBox(width: 4),
        Text(
          '${subject.discussionCount} (${subject.finishedDiscussionCount} ✔)',
          style: textStyle,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: codeEntries.map((entry) {
                if (entry.value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${entry.key}:',
                          style: textStyle?.copyWith(
                            color: subject.isHidden
                                ? textColor
                                : getColorForRepetitionCode(entry.key),
                          ),
                        ),
                        TextSpan(
                          text: ' ${entry.value}',
                          style: textStyle?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context, Color? textColor) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double baseFontSize = 12.0;
    final scaledFontSize = baseFontSize * textScaleFactor;
    final scaledIconSize = (baseFontSize * 0.95) * textScaleFactor;

    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: textColor, fontSize: scaledFontSize);

    return RichText(
      text: TextSpan(
        style: subtitleStyle,
        children: [
          if (subject.date != null)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: scaledIconSize,
                  color: subject.isHidden ? textColor : Colors.amber[800],
                ),
              ),
              alignment: PlaceholderAlignment.middle,
            ),
          if (subject.date != null)
            TextSpan(
              text: subject.date,
              style: TextStyle(
                color: subject.isHidden ? textColor : Colors.amber[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          if (subject.date != null && subject.repetitionCode != null)
            const TextSpan(text: '  |  '),
          if (subject.repetitionCode != null)
            WidgetSpan(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.repeat,
                  size: scaledIconSize,
                  color: subject.isHidden
                      ? textColor
                      : getColorForRepetitionCode(subject.repetitionCode!),
                ),
              ),
              alignment: PlaceholderAlignment.middle,
            ),
          if (subject.repetitionCode != null)
            TextSpan(
              text: subject.repetitionCode,
              style: TextStyle(
                color: subject.isHidden
                    ? textColor
                    : getColorForRepetitionCode(subject.repetitionCode!),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
