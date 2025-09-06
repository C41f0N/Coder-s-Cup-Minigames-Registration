import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coders_cup_minigame_frontend/utils.dart';
import 'package:flutter/material.dart';

class ScoreboardPage extends StatelessWidget {
  final String gameId;
  final String gameName;

  const ScoreboardPage({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context) {
  final responsesRef = FirebaseFirestore.instance
    .collection('games')
    .doc(gameId)
    .collection('responses');

    return Scaffold(
      appBar: AppBar(title: Text('Scoreboard')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: responsesRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          // Build list of entries with parsed scores
          final entries = docs.map((d) {
            final data = d.data();
            final name = (data['userName'] ?? data['userEmail'] ?? 'Unknown')
                .toString();
            final score = data.containsKey('score')
                ? (data['score'] as num?)?.toInt()
                : null;
            return {'id': d.id, 'name': name, 'score': score};
          }).toList();

          // Sort: scores desc, nulls last
          entries.sort((a, b) {
            final sa = a['score'] as int?;
            final sb = b['score'] as int?;
            if (sa == null && sb == null) return 0;
            if (sa == null) return 1;
            if (sb == null) return -1;
            return sb.compareTo(sa);
          });

          if (entries.isEmpty)
            return const Center(child: Text('No one played yet.'));

          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: isLandscape(context)
                  ? MediaQuery.of(context).size.width * 0.2
                  : MediaQuery.of(context).size.width * 0.05,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        gameName,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.07,
                        ),
                      ),
                      Text(
                        'Total Players: ${entries.length}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * 0.02,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final rank = i + 1;
                      final name = e['name'] as String;
                      final score = e['score'] as int?;
                      return ListTile(
                        leading: CircleAvatar(child: Text(rank.toString())),
                        title: Text(name),
                        trailing: Text(
                          score != null ? score.toString() : 'Yet to play',
                          style: TextStyle(
                            fontSize: 16,
                            color: score != null
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: entries.length,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
