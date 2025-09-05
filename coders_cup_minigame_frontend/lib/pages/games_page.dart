import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coders_cup_minigame_frontend/models/form_field.dart'
    as model_field;
import 'package:coders_cup_minigame_frontend/models/game.dart';
import 'package:coders_cup_minigame_frontend/pages/game_page.dart';
import 'package:coders_cup_minigame_frontend/utils.dart';
import 'package:flutter/material.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  final CollectionReference<Map<String, dynamic>> _gamesRef = FirebaseFirestore
      .instance
      .collection('games')
      .withConverter(
        fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
        toFirestore: (value, _) => value,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _gamesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No games found.'));
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: isLandscape(context)
                  ? MediaQuery.of(context).size.width * 0.2
                  : MediaQuery.of(context).size.width * 0.05,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              // Parse fields defensively
              final id = doc.id;
              final name = (data['name'] as String?) ?? 'Unnamed Game';

              int limit = 0;
              try {
                final rawLimit = data['limit'];
                if (rawLimit is int) {
                  limit = rawLimit;
                } else if (rawLimit is double) {
                  limit = rawLimit.toInt();
                } else if (rawLimit is String) {
                  limit = int.tryParse(rawLimit) ?? 0;
                }
              } catch (_) {
                limit = 0;
              }

              // Parse formFields if present
              final List<model_field.FormField> formFields = [];
              try {
                final rawFields = data['formFields'];
                if (rawFields is Iterable) {
                  for (final f in rawFields) {
                    if (f is Map<String, dynamic>) {
                      final label = (f['label'] as String?) ?? '';
                      final type = (f['type'] as String?) ?? '';
                      formFields.add(
                        model_field.FormField(label: label, type: type),
                      );
                    } else if (f is Map) {
                      final label = (f['label']?.toString()) ?? '';
                      final type = (f['type']?.toString()) ?? '';
                      formFields.add(
                        model_field.FormField(label: label, type: type),
                      );
                    }
                  }
                }
              } catch (_) {
                // ignore parsing errors, leave empty
              }

              final game = Game(id: id, name: name, limit: limit);
              game.formFields = formFields;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                child: ListTile(
                  title: Text(game.name),
                  subtitle: Text(
                    'Limit: ${game.limit} — ${game.formFields.length} fields',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => GamePage(game: game)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
