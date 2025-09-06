import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coders_cup_minigame_admin/utils.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResponsesPage extends StatefulWidget {
  final String gameId;
  final String gameName;

  const ResponsesPage({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  State<ResponsesPage> createState() => _ResponsesPageState();
}

class _ResponsesPageState extends State<ResponsesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  String _formatAnswerValue(dynamic stored) {
    if (stored == null) return '';
    dynamic val = stored;
    String? type;
    if (stored is Map) {
      if (stored.containsKey('value')) val = stored['value'];
      if (stored.containsKey('type'))
        type = stored['type']?.toString().toLowerCase();
    }

    // Handle Firestore Timestamp
    if (val is Timestamp) {
      final dt = val.toDate().toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
    }

    // If type hints at date but stored as string, try parse
    if (type != null && type.contains('date') && val is String) {
      try {
        final dt = DateTime.parse(val).toLocal();
        String two(int n) => n.toString().padLeft(2, '0');
        return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
      } catch (_) {}
    }

    // Numbers
    if (val is num) return val.toString();

    // Default
    return val?.toString() ?? '';
  }

  String _valueForCsv(dynamic stored) {
    // Use the same formatting as display but keep it compact
    return _formatAnswerValue(stored);
  }

  bool _answerMatchesQuery(dynamic stored, String q) {
    final s = (stored is Map && stored.containsKey('value'))
        ? stored['value']
        : stored;
    if (s == null) return false;
    return s.toString().toLowerCase().contains(q);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _editScore(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> data,
  ) async {
    final current = data['score'];
    final ctrl = TextEditingController(
      text: current != null ? current.toString() : '',
    );
    final messenger = ScaffoldMessenger.of(context);
    final res = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set score'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Integer score (leave empty to remove)',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res != true) return;

    final text = ctrl.text.trim();
    try {
      if (text.isEmpty) {
        await docRef.update({'score': FieldValue.delete()});
        messenger.showSnackBar(const SnackBar(content: Text('Score removed')));
      } else {
        final parsed = int.tryParse(text);
        if (parsed == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Invalid integer')),
          );
          return;
        }
        await docRef.update({'score': parsed});
        messenger.showSnackBar(const SnackBar(content: Text('Score updated')));
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update score: $e')),
      );
    }
  }

  Future<void> _deleteResponseById(
    BuildContext context,
    String gameId,
    String responseId,
  ) async {
    final confirm = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete response'),
        content: const Text(
          'Are you sure you want to delete this response? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final messenger = ScaffoldMessenger.of(context);
    // show transient progress snackbar
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Deleting response...'),
        duration: Duration(seconds: 30),
      ),
    );

    final gameRef = FirebaseFirestore.instance.collection('games').doc(gameId);
    final responseRef = gameRef.collection('responses').doc(responseId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final gameSnap = await tx.get(gameRef);
        final data = gameSnap.data() ?? {};
        final current = (data['responsesCount'] is int)
            ? data['responsesCount'] as int
            : int.tryParse(data['responsesCount']?.toString() ?? '') ?? 0;
        final newCount = current > 0 ? current - 1 : 0;
        tx.delete(responseRef);
        tx.update(gameRef, {'responsesCount': newCount});
      });
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Response deleted')));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete response: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsesRef = FirebaseFirestore.instance
        .collection('games')
        .doc(widget.gameId)
        .collection('responses');

    return Scaffold(
      appBar: AppBar(
        title: Text('Responses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              final snap = await responsesRef.get();
              final rows = <List<dynamic>>[];
              // build header
              final header = <dynamic>[
                'id',
                'userName',
                'userEmail',
                'submittedAt',
                'score',
              ];
              // collect all answer keys
              final keys = <String>{};
              for (final d in snap.docs) {
                final data = d.data();
                final answers =
                    (data['answers'] as Map<String, dynamic>?) ?? {};
                keys.addAll(answers.keys.cast<String>());
              }
              header.addAll(keys);
              rows.add(header);

              for (final d in snap.docs) {
                final data = d.data();
                final answers =
                    (data['answers'] as Map<String, dynamic>?) ?? {};
                final row = <dynamic>[
                  d.id,
                  data['userName'] ?? '',
                  data['userEmail'] ?? '',
                  data['submittedAt']?.toString() ?? '',
                  data['score']?.toString() ?? '',
                ];
                for (final k in keys) row.add(_valueForCsv(answers[k]));
                rows.add(row);
              }

              final csvStr = const ListToCsvConverter().convert(rows);
              // show in dialog for copy
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('CSV'),
                  content: SingleChildScrollView(child: SelectableText(csvStr)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(ClipboardData(text: csvStr));
                        Navigator.of(context).pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('CSV copied to clipboard'),
                          ),
                        );
                      },
                      child: const Text('Copy CSV'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: isLandscape(context)
              ? MediaQuery.of(context).size.width * 0.2
              : MediaQuery.of(context).size.width * 0.05,
        ),
        child: Column(
          children: [
            Text(
              widget.gameName,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.height * 0.07,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search responses by name, email or id',
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: responsesRef
                    .orderBy('submittedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  final filtered = docs.where((d) {
                    if (_query.isEmpty) return true;
                    final data = d.data();
                    final user = (data['userName'] ?? data['userEmail'] ?? '')
                        .toString()
                        .toLowerCase();
                    final id = d.id.toLowerCase();
                    if (user.contains(_query) || id.contains(_query))
                      return true;
                    final answers =
                        (data['answers'] as Map<String, dynamic>?) ?? {};
                    for (final v in answers.values) {
                      if (v != null && _answerMatchesQuery(v, _query))
                        return true;
                    }
                    return false;
                  }).toList();

                  if (filtered.isEmpty)
                    return const Center(child: Text('No responses'));

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final d = filtered[i];
                      final data = d.data();
                      final user =
                          data['userName'] ?? data['userEmail'] ?? 'Unknown';
                      final submittedAtRaw = data['submittedAt'];
                      String submitted = '';
                      if (submittedAtRaw != null) {
                        DateTime? dt;
                        if (submittedAtRaw is Timestamp) {
                          dt = submittedAtRaw.toDate();
                        } else if (submittedAtRaw is DateTime) {
                          dt = submittedAtRaw;
                        } else if (submittedAtRaw is int) {
                          dt = DateTime.fromMillisecondsSinceEpoch(
                            submittedAtRaw,
                          );
                        } else {
                          try {
                            dt = DateTime.parse(submittedAtRaw.toString());
                          } catch (_) {
                            dt = null;
                          }
                        }
                        if (dt != null) {
                          final l = dt.toLocal();
                          String two(int n) => n.toString().padLeft(2, '0');
                          submitted =
                              '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
                        } else {
                          submitted = submittedAtRaw.toString();
                        }
                      }
                      final score = data.containsKey('score')
                          ? data['score']
                          : null;
                      return ListTile(
                        title: Text(user),
                        subtitle: Text(submitted),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (score != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  label: Text('Score: ${score.toString()}'),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _editScore(context, d.reference, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteResponseById(
                                context,
                                widget.gameId,
                                d.id,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (context) {
                            final answers =
                                (data['answers'] as Map<String, dynamic>?) ??
                                {};
                            return AlertDialog(
                              title: Text(user),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data['userEmail']?.toString() ?? '',
                                          ),
                                        ),
                                        if (score != null)
                                          Chip(
                                            label: Text(
                                              'Score: ${score.toString()}',
                                            ),
                                          )
                                        else
                                          const Text(
                                            'Yet to play',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Submitted: $submitted'),
                                    const Divider(),
                                    const Text(
                                      'Answers:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...answers.entries.map((e) {
                                      final display = _formatAnswerValue(
                                        e.value,
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(e.key),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 3,
                                              child: Text(display),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _editScore(context, d.reference, data);
                                  },
                                  child: const Text('Edit score'),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
