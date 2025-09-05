import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class ResponsesPage extends StatelessWidget {
  final String gameId;
  final String gameName;

  const ResponsesPage({super.key, required this.gameId, required this.gameName});

  @override
  Widget build(BuildContext context) {
    final responsesRef = FirebaseFirestore.instance.collection('games').doc(gameId).collection('responses');

    return Scaffold(
      appBar: AppBar(
        title: Text('Responses - $gameName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final snap = await responsesRef.get();
              final rows = <List<dynamic>>[];
              // build header
              final header = <dynamic>['id', 'userName', 'userEmail', 'submittedAt'];
              // collect all answer keys
              final keys = <String>{};
              for (final d in snap.docs) {
                final data = d.data();
                final answers = (data['answers'] as Map<String, dynamic>?) ?? {};
                keys.addAll(answers.keys.cast<String>());
              }
              header.addAll(keys);
              rows.add(header);

              for (final d in snap.docs) {
                final data = d.data();
                final answers = (data['answers'] as Map<String, dynamic>?) ?? {};
                final row = <dynamic>[d.id, data['userName'] ?? '', data['userEmail'] ?? '', data['submittedAt']?.toString() ?? ''];
                for (final k in keys) row.add(answers[k] ?? '');
                rows.add(row);
              }

              final csvStr = const ListToCsvConverter().convert(rows);
              // show in dialog for copy
              await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('CSV'), content: SingleChildScrollView(child: Text(csvStr)), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))]));
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: responsesRef.orderBy('submittedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No responses'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final user = data['userName'] ?? data['userEmail'] ?? 'Unknown';
              final submitted = data['submittedAt']?.toString() ?? '';
              return ListTile(
                title: Text(user),
                subtitle: Text(submitted),
                onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(title: Text(user), content: SingleChildScrollView(child: Text(data.toString())), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))])),
              );
            },
          );
        },
      ),
    );
  }
}
