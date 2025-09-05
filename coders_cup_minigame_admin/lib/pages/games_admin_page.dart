import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_game_page.dart';
import 'responses_page.dart';

class GamesAdminPage extends StatelessWidget {
  const GamesAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gamesRef = FirebaseFirestore.instance.collection('games');

    return Scaffold(
      appBar: AppBar(title: const Text('Games Admin')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: gamesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No games'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final name = (data['name'] as String?) ?? 'Unnamed';
              final limit = data['limit']?.toString() ?? '0';
              return ListTile(
                title: Text(name),
                subtitle: Text('Limit: $limit'),
                trailing: IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResponsesPage(gameId: d.id, gameName: name))),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddGamePage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
