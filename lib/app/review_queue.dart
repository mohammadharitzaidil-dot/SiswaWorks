import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String _t(BuildContext c, String ms, String en) =>
    Localizations.localeOf(c).languageCode == 'ms' ? ms : en;

class ReviewQueue extends StatelessWidget {
  const ReviewQueue({super.key, required this.db, required this.uid});
  final FirebaseFirestore db;
  final String uid;
  @override
  Widget build(BuildContext context) {
    final title = _t(context, 'Semakan Organisasi', 'Organization review');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('organization_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (c, s) {
          if (s.hasError) {
            return Center(
              child: Text(
                _t(c, 'Gagal memuatkan senarai.', 'Could not load requests.'),
              ),
            );
          }
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = s.data!.docs.toList()
            ..sort(
              (a, b) => (a.data()['submittedAt'] as Timestamp).compareTo(
                b.data()['submittedAt'] as Timestamp,
              ),
            );
          if (docs.isEmpty) {
            return Center(
              child: Text(
                _t(c, 'Tiada permohonan menunggu.', 'No pending requests.'),
              ),
            );
          }
          String normalized(String value) =>
              value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          return ListView(
            children: [
              for (final doc in docs)
                ListTile(
                  title: Text(doc.data()['officialName']),
                  subtitle: Text(doc.data()['representativeName']),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final key = normalized(doc.data()['officialName']);
                    final similar = docs
                        .where(
                          (d) =>
                              d.id != doc.id &&
                              (normalized(d.data()['officialName'])
                                      .contains(key) ||
                                  key.contains(
                                    normalized(d.data()['officialName']),
                                  )),
                        )
                        .map((d) => d.data()['officialName'] as String)
                        .toList();
                    Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) =>
                            _Review(doc: doc, uid: uid, similar: similar),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Review extends StatefulWidget {
  const _Review({required this.doc, required this.uid, required this.similar});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;
  final List<String> similar;
  @override
  State<_Review> createState() => _ReviewState();
}

class _ReviewState extends State<_Review> {
  final reason = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() work) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await work();
    } catch (_) {
      if (mounted) {
        setState(
          () => message = _t(
            context,
            'Operasi gagal. Kembali ke senarai untuk semak versi terkini.',
            'Action failed. Return to the list to review the current version.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> decide(bool approve) async {
    final ref = widget.doc.reference;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          approve
              ? _t(c, 'Luluskan permohonan?', 'Approve request?')
              : _t(c, 'Tolak permohonan?', 'Reject request?'),
        ),
        content: Text(
          approve ? widget.doc.data()['officialName'] : reason.text.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(_t(c, 'Batal', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(_t(c, 'Sahkan', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final updated = await ref.firestore.runTransaction((tx) async {
      final latest = (await tx.get(ref)).data();
      if (latest?['status'] != 'pending' ||
          latest?['revision'] != widget.doc.data()['revision']) {
        return false;
      }
      tx.update(ref, {
        'status': approve ? 'approved' : 'rejected',
        'revision': latest!['revision'] + 1,
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': widget.uid,
        'rejectionReason': approve ? '' : reason.text.trim(),
      });
      return true;
    });
    if (!mounted) return;
    if (updated) {
      Navigator.pop(context);
    } else {
      setState(
        () => message = _t(
          context,
          'Permohonan telah berubah. Buka semula dari senarai.',
          'Request changed. Reopen it from the list.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext c) {
    final d = widget.doc.data();
    final time = (d['updatedAt'] as Timestamp).toDate().toLocal();
    return Scaffold(
      appBar: AppBar(title: Text(d['officialName'])),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.similar.isNotEmpty)
            Text(
              '${_t(c, "Nama serupa", "Similar names")}: ${widget.similar.join(", ")}',
            ),
          for (final row in [
            [_t(c, 'Jenis', 'Type'), d['organizationType']],
            [_t(c, 'Kolej / fakulti', 'Affiliation'), d['affiliation']],
            [_t(c, 'Wakil', 'Representative'), d['representativeName']],
            [_t(c, 'Jawatan', 'Position'), d['representativePosition']],
            [
              _t(c, 'Dikemas kini', 'Updated'),
              time.toString().split('.').first,
            ],
          ])
            ListTile(title: Text(row[0]), subtitle: Text(row[1].toString())),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => run(() async {
                    final ref = widget.doc.reference;
                    final blob = await ref.firestore.runTransaction((tx) async {
                      final current = (await tx.get(ref)).data();
                      if (current?['revision'] != d['revision'] ||
                          current?['status'] != 'pending') {
                        throw StateError('changed');
                      }
                      final file = (await tx.get(
                        ref.collection('documents').doc('evidence'),
                      )).data();
                      return (file!['content'] as Blob).bytes;
                    });
                    if (mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              _Pdf(bytes: blob, title: d['evidenceName']),
                        ),
                      );
                    }
                  }),
            child: Text(
              '${_t(c, "Buka PDF", "Open PDF")} · ${d["evidenceName"]}',
            ),
          ),
          FilledButton(
            onPressed: busy ? null : () => run(() => decide(true)),
            child: Text(_t(c, 'Lulus', 'Approve')),
          ),
          TextField(
            controller: reason,
            enabled: !busy,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _t(c, 'Sebab penolakan', 'Rejection reason'),
            ),
          ),
          OutlinedButton(
            onPressed: busy || reason.text.trim().isEmpty
                ? null
                : () => run(() => decide(false)),
            child: Text(_t(c, 'Tolak', 'Reject')),
          ),
          if (busy) const LinearProgressIndicator(),
          if (message != null) Text(message!),
        ],
      ),
    );
  }
}

class _Pdf extends StatefulWidget {
  const _Pdf({required this.bytes, required this.title});
  final Uint8List bytes;
  final String title;
  @override
  State<_Pdf> createState() => _PdfState();
}

class _PdfState extends State<_Pdf> {
  int page = 0;
  late Future<Map<dynamic, dynamic>?> rendered = render();
  Future<Map<dynamic, dynamic>?> render() =>
      const MethodChannel('siswaworks/documents')
          .invokeMapMethod('renderPage', {'bytes': widget.bytes, 'page': page});
  void turn(int delta) => setState(() {
    page += delta;
    rendered = render();
  });
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<Map<dynamic, dynamic>?>(
      future: rendered,
      builder: (c, s) {
        if (s.hasError) {
          return Center(
            child: Text(
              _t(c, 'PDF tidak dapat dibuka.', 'Unable to open PDF.'),
            ),
          );
        }
        if (s.connectionState != ConnectionState.done || !s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = s.data!;
        final count = data['count'] as int;
        return Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                key: ValueKey(page),
                child: Center(child: Image.memory(data['image'] as Uint8List)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: page > 0 ? () => turn(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${page + 1} / $count'),
                IconButton(
                  onPressed: page + 1 < count ? () => turn(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
