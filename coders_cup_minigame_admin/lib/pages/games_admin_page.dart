import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coders_cup_minigame_admin/utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_game_page.dart';
import 'responses_page.dart';

class GamesAdminPage extends StatelessWidget {
  const GamesAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gamesRef = FirebaseFirestore.instance.collection('games');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Games Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: gamesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No games'));

          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: isLandscape(context)
                  ? MediaQuery.of(context).size.width * 0.2
                  : MediaQuery.of(context).size.width * 0.05,
            ),
            child: ListView.builder(
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
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ResponsesPage(gameId: d.id, gameName: name),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddGamePage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
