import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddGamePage extends StatefulWidget {
  const AddGamePage({super.key});

  @override
  State<AddGamePage> createState() => _AddGamePageState();
}

class _AddGamePageState extends State<AddGamePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController(text: '100');
  final List<_FieldEntry> _fields = [
    _FieldEntry(
      labelController: TextEditingController(text: 'Name'),
      type: 'text',
    ),
  ];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    for (final f in _fields) {
      f.labelController.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final limit = int.tryParse(_limitCtrl.text) ?? 0;
      final fields = _fields
          .map((f) => {'label': f.labelController.text.trim(), 'type': f.type})
          .toList();

      await FirebaseFirestore.instance.collection('games').add({
        'name': name,
        'limit': limit,
        'formFields': fields,
        'responsesCount': 0,
      });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Game')),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: MediaQuery.of(context).size.width * 0.05,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _limitCtrl,
                decoration: const InputDecoration(labelText: 'Limit'),
                validator: (v) =>
                    (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Form fields',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Name and Email are captured from Google sign-in automatically; you do not need to add them as form fields.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._fields.asMap().entries.map((entry) {
                final idx = entry.key;
                final field = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: field.labelController,
                          decoration: const InputDecoration(
                            labelText: 'Label',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: field.type,
                          items: const [
                            DropdownMenuItem(
                              value: 'text',
                              child: Text('Text'),
                            ),
                            DropdownMenuItem(
                              value: 'email',
                              child: Text('Email'),
                            ),
                            DropdownMenuItem(
                              value: 'number',
                              child: Text('Number'),
                            ),
                            DropdownMenuItem(
                              value: 'date',
                              child: Text('Date'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => field.type = v);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() => _fields.removeAt(idx));
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _fields.add(
                      _FieldEntry(
                        labelController: TextEditingController(),
                        type: 'text',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add field'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldEntry {
  TextEditingController labelController;
  String type;

  _FieldEntry({required this.labelController, required this.type});
}
