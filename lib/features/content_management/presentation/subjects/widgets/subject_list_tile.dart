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
  final VoidCallback onToggleVisibility;
  final VoidCallback onLinkPath;
  final VoidCallback onEditIndexFile;
  final VoidCallback onMove;
  final VoidCallback onToggleFreeze;
  final VoidCallback onToggleLock;
  final VoidCallback onTimeline;
  final VoidCallback onViewJson;
  final VoidCallback onExport;
  final bool isFocused;

  const SubjectListTile({
    super.key,
    required this.subject,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onToggleVisibility,
    required this.onLinkPath,
    required this.onEditIndexFile,
    required this.onMove,
    required this.onToggleFreeze,
    required this.onToggleLock,
    required this.onTimeline,
    required this.onViewJson,
    required this.onExport,
    this.isFocused = false,
  });

  // Metode pembantu untuk menghasilkan warna dinamis yang konsisten berdasarkan judul (hash)
  Color _getThemeColorFromTitle(String title) {
    if (title.isEmpty) return Colors.deepPurple;
    // Kumpulan palet warna menarik yang selaras dengan komponen Topic
    final List<Color> themePalettes = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber.shade900,
      Colors.green.shade700,
      Colors.cyan.shade800,
      Colors.orange.shade800,
    ];
    final int hash = title.hashCode;
    final int index = hash.abs() % themePalettes.length;
    return themePalettes[index];
  }

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

    // Mendapatkan warna utama berbasis judul satu kali untuk seluruh konfigurasi widget
    final Color mainThemeColor = _getThemeColorFromTitle(subject.name);
    final Color cardColor = isSelected
        ? mainThemeColor.withOpacity(
            0.15,
          ) // Menyesuaikan warna seleksi dengan tema judul
        : (isHidden
              ? theme.disabledColor.withOpacity(0.1)
              : (isFrozen
                    ? Colors.lightBlue.shade50
                    : (isLocked ? Colors.grey.shade300 : theme.cardColor)));
    final Color? textColor = isHidden
        ? theme.disabledColor
        : (isLocked ? Colors.grey.shade700 : null);
    final double elevation = isHidden ? 1 : 2;

    // --- MODIFIKASI UKURAN MOBILE FRIENDLY ---
    final double verticalMargin = 4;
    final double horizontalMargin = 8;
    final EdgeInsets padding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    );
    final double iconFontSize = 20;
    final double titleFontSize = 14;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    const double basePopupIconSize = 18.0;
    const double baseLinkIconSize = 14.0;
    final scaledPopupIconSize = basePopupIconSize * textScaleFactor;
    final scaledLinkIconSize = baseLinkIconSize * textScaleFactor;

    final tileContent = Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => provider.toggleSubjectSelection(subject),
        borderRadius: BorderRadius.circular(10),
        splashColor: mainThemeColor.withOpacity(0.1),
        highlightColor: mainThemeColor.withOpacity(0.05),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.shade400
                      : isHidden
                      ? theme.disabledColor.withOpacity(0.1)
                      : mainThemeColor.withOpacity(
                          0.12,
                        ), // Background ikon dinamis mengikuti judul
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color:
                            mainThemeColor, // Warna check mengikuti tema dinamis
                        size: iconFontSize,
                      )
                    else
                      Text(
                        isLocked ? ' ' : subject.icon,
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
                          size: 12 * textScaleFactor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (subject.linkedPath != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Icon(
                              Icons.link,
                              color: isHidden
                                  ? textColor
                                  : mainThemeColor, // Ikon rantai mengikuti tema dinamis
                              size: scaledLinkIconSize,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            subject.name,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: isHidden
                                  ? textColor
                                  : mainThemeColor, // Teks utama menggunakan warna judul dinamis
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 2),
                      _buildSubtitle(context, textColor, textScaleFactor),
                    ],
                    const SizedBox(height: 4),
                    _buildStatsRow(context, textColor),
                  ],
                ),
              ),
              if (!provider.isSelectionMode)
                Theme(
                  data: theme.copyWith(
                    // Mengubah warna teks menu opsi item menjadi warna tema
                    popupMenuTheme: theme.popupMenuTheme.copyWith(
                      textStyle: TextStyle(color: mainThemeColor, fontSize: 14),
                    ),
                    // Mengubah warna ikon utama di dalam widget baris item
                    iconTheme: theme.iconTheme.copyWith(color: mainThemeColor),
                    // Mengubah warna ikon expand panah kecil di SubmenuButton kustom
                    iconButtonTheme: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        foregroundColor: mainThemeColor,
                      ),
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    iconSize: scaledPopupIconSize,
                    icon: Icon(
                      Icons.more_vert,
                      color: isHidden
                          ? textColor
                          : mainThemeColor.withOpacity(
                              0.7,
                            ), // Titik tiga mengikuti aksen warna judul
                    ),
                    padding: const EdgeInsets.all(12.0),
                    onSelected: (value) {
                      if (value == 'rename') onRename();
                      if (value == 'delete') onDelete();
                      if (value == 'toggle_visibility') onToggleVisibility();
                      if (value == 'link_path') onLinkPath();
                      if (value == 'edit_index') onEditIndexFile();
                      if (value == 'move') onMove();
                      if (value == 'toggle_freeze') onToggleFreeze();
                      if (value == 'toggle_lock') onToggleLock();
                      if (value == 'timeline') onTimeline();
                      if (value == 'view_json') onViewJson();
                      if (value == 'export_zip') onExport();
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      _buildMenuItem(
                        'timeline',
                        Icons.timeline,
                        'Lihat Linimasa',
                      ),
                      _buildMenuItem(
                        'move',
                        Icons.move_up_outlined,
                        'Pindahkan',
                      ),
                      _buildMenuItem(
                        'export_zip',
                        Icons.archive_outlined,
                        'Export ke ZIP',
                      ),
                      const PopupMenuDivider(height: 8),
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
                            isFrozen
                                ? Icons.play_arrow_outlined
                                : Icons.ac_unit,
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
                      const PopupMenuDivider(height: 8),
                      _buildMenuItem(
                        'delete',
                        Icons.delete_outline,
                        'Hapus',
                        color: Colors
                            .red, // Opsi hapus tetap merah sebagai warning penanda bahaya
                      ),
                    ],
                  ),
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
      // === MODIFIKASI BORDER DI SINI ===
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isFocused
              ? mainThemeColor // Border solid mengikuti tema dinamis saat aktif
              : mainThemeColor.withOpacity(
                  0.35,
                ), // Border halus tipis saat tidak aktif
          width: isFocused ? 2.0 : 1.0,
        ),
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
      height: 40,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: color, fontSize: 14)),
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
      height: 40,
      child: SubmenuButton(
        menuChildren: children,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Color? textColor) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: textColor, fontSize: 11.0);
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
    final double scaledStatIconSize = (textStyle?.fontSize ?? 11.0);

    return Row(
      children: [
        Icon(
          Icons.chat_bubble_outline,
          size: scaledStatIconSize,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${subject.discussionCount} (${subject.finishedDiscussionCount})',
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

  Widget _buildSubtitle(
    BuildContext context,
    Color? textColor,
    double textScaleFactor,
  ) {
    const double baseFontSize = 11.0;
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
