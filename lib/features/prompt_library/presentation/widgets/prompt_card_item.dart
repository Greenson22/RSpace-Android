import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../application/prompt_provider.dart';
import '../../domain/models/prompt_concept_model.dart';
import 'prompt_dialogs.dart';

class PromptCardItem extends StatelessWidget {
  final PromptConcept prompt;
  final int index;

  const PromptCardItem({super.key, required this.prompt, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<PromptProvider>(context, listen: false);
    final color = Colors.primaries[index % Colors.primaries.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(context, prompt),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.article_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildPopupMenu(context, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, PromptProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        final currentCategory = provider.selectedCategory;
        if (currentCategory == null) return;

        switch (value) {
          case 'duplicate':
            _handleDuplicate(context, provider, currentCategory);
            break;
          case 'move':
            _handleMove(context, provider, currentCategory);
            break;
          case 'copy':
            _handleCopy(context, provider);
            break;
          case 'delete':
            _showDeleteConfirmation(context, provider);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20, color: Colors.grey),
              SizedBox(width: 12),
              Text('Duplikat'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'move',
          child: Row(
            children: [
              Icon(
                Icons.drive_file_move_outlined,
                size: 20,
                color: Colors.grey,
              ),
              SizedBox(width: 12),
              Text('Pindah ke...'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.file_copy_outlined, size: 20, color: Colors.grey),
              SizedBox(width: 12),
              Text('Salin ke...'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Hapus', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleDuplicate(
    BuildContext context,
    PromptProvider provider,
    String currentCategory,
  ) async {
    try {
      await provider.duplicatePrompt(currentCategory, prompt);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt berhasil diduplikasi.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal duplikasi: $e')));
      }
    }
  }

  Future<void> _handleMove(
    BuildContext context,
    PromptProvider provider,
    String currentCategory,
  ) async {
    final target = await showSelectTopicDialog(
      context,
      provider.categories,
      currentCategory: currentCategory,
      title: 'Pindah ke Topik...',
    );
    if (target != null && context.mounted) {
      try {
        await provider.movePrompt(currentCategory, target, prompt);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Prompt dipindahkan ke "$target"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal memindahkan: $e')));
        }
      }
    }
  }

  Future<void> _handleCopy(
    BuildContext context,
    PromptProvider provider,
  ) async {
    final target = await showSelectTopicDialog(
      context,
      provider.categories,
      title: 'Salin ke Topik...',
    );
    if (target != null && context.mounted) {
      try {
        await provider.copyPromptToCategory(target, prompt);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Prompt disalin ke "$target"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyalin: $e')));
        }
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, PromptProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Prompt'),
        content: Text(
          'Apakah Anda yakin ingin menghapus prompt "${prompt.title}"?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final currentCategory = provider.selectedCategory;
              if (currentCategory != null) {
                try {
                  await provider.deletePrompt(currentCategory, prompt);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prompt berhasil dihapus.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menghapus: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, PromptConcept prompt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(prompt.title)),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pop(ctx);
                showEditPromptDialog(context, prompt);
              },
              tooltip: 'Edit Prompt',
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt.description,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Isi Prompt:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MarkdownBody(
                    data: prompt.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prompt.content));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Isi prompt disalin!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin'),
          ),
        ],
      ),
    );
  }
}
