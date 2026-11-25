import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/flashcard.dart';
import '../models/flashcard_group.dart';
import '../providers/flashcard_provider.dart';

class FlashcardListScreen extends StatefulWidget {
  final int groupId;

  const FlashcardListScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        final group = provider.groups.cast<FlashcardGroup?>().firstWhere(
              (item) => item?.id == widget.groupId,
          orElse: () => null,
        );
        final cards = provider.flashcards.where((card) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) return true;
          return card.korean.toLowerCase().contains(query) ||
              card.translation.toLowerCase().contains(query) ||
              (card.romanization ?? '').toLowerCase().contains(query) ||
              (card.note ?? '').toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              group == null ? 'FlashCards' : group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            leading: IconButton(
              tooltip: 'Volver al estudio',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar por coreano o traducción...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${cards.length} ${cards.length == 1 ? 'FlashCard' : 'FlashCards'}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const Spacer(),
                      const Icon(Icons.touch_app_rounded, size: 17),
                      const SizedBox(width: 5),
                      Text(
                        'Toca para estudiar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: cards.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        provider.flashcards.isEmpty
                            ? 'Este grupo todavía no tiene FlashCards.'
                            : 'No se encontraron tarjetas con esa búsqueda.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    itemCount: cards.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return _buildCardTile(context, provider, card);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardTile(
      BuildContext context,
      FlashcardProvider provider,
      Flashcard card,
      ) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            card.korean.isEmpty ? '?' : card.korean.substring(0, 1),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          card.korean,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((card.romanization ?? '').trim().isNotEmpty)
              Text(card.romanization!, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(card.translation, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opciones de FlashCard',
          onSelected: (value) {
            if (value == 'move') _showMoveDialog(context, provider, card);
          },
          itemBuilder: (_) => const [
            PopupMenuItem<String>(
              value: 'move',
              child: Row(
                children: [
                  Icon(Icons.drive_file_move),
                  SizedBox(width: 10),
                  Text('Mover a otro grupo'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          final selected = provider.selectFlashcardById(card.id);
          if (selected) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showMoveDialog(
      BuildContext context,
      FlashcardProvider provider,
      Flashcard card,
      ) async {
    final destinations = provider.groups
        .where((group) => group.id != card.groupId)
        .toList();

    if (destinations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea otro grupo antes de mover esta FlashCard.')),
      );
      return;
    }

    int? selectedGroupId;
    final destinationId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mover FlashCard'),
        content: SizedBox(
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('¿A qué grupo quieres mover “${card.korean}”?'),
                const SizedBox(height: 12),
                ...destinations.map(
                      (group) => RadioListTile<int>(
                    value: group.id,
                    groupValue: selectedGroupId,
                    title: Text(group.name),
                    subtitle: Text('${group.flashcardCount} FlashCards'),
                    onChanged: (value) => setDialogState(() => selectedGroupId = value),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: selectedGroupId == null
                ? null
                : () => Navigator.pop(dialogContext, selectedGroupId),
            icon: const Icon(Icons.drive_file_move),
            label: const Text('Mover'),
          ),
        ],
      ),
    );

    if (destinationId == null || !mounted) return;

    try {
      await provider.moveFlashcardToGroup(
        flashcardId: card.id,
        destinationGroupId: destinationId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“${card.korean}” se movió al otro grupo.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo mover la FlashCard: $e')),
      );
    }
  }
}
