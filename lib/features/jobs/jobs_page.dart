import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'applications.dart';

String t(BuildContext c, String ms, String en) =>
    Localizations.localeOf(c).languageCode == 'ms' ? ms : en;
DateTime my(DateTime utc) => utc.toUtc().add(const Duration(hours: 8));
String fmt(dynamic ts) => ts == null
    ? '—'
    : my((ts as Timestamp).toDate()).toString().substring(0, 16);

class JobsPage extends StatefulWidget {
  const JobsPage({
    super.key,
    required this.db,
    required this.uid,
    required this.organization,
    required this.approved,
  });
  final FirebaseFirestore db;
  final String uid;
  final bool organization, approved;
  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  late final stream =
      (widget.organization
              ? widget.db
                    .collection('jobs')
                    .where('ownerOrgUid', isEqualTo: widget.uid)
              : widget.db.collection('jobs').where('status', isEqualTo: 'open'))
          .snapshots();
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> edit([QueryDocumentSnapshot<Map<String, dynamic>>? doc]) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _Editor(
            db: widget.db,
            uid: widget.uid,
            doc: doc,
            approved: widget.approved,
          ),
        ),
      );
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.organization
            ? t(c, 'Iklan organisasi', 'Organization jobs')
            : t(c, 'Semua Kerja', 'All jobs'),
      ),
    ),
    body: Column(
      children: [
        if (!widget.organization)
          OutlinedButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) =>
                    _ApplicationList(db: widget.db, uid: widget.uid),
              ),
            ),
            child: Text(t(c, 'Permohonan Saya', 'My applications')),
          ),
        if (widget.organization)
          FilledButton(
            onPressed: () => edit(),
            child: Text(t(c, 'Cipta draf kerja', 'Create job draft')),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (c, s) {
              if (s.hasError) {
                return Center(
                  child: Text(
                    t(c, 'Gagal memuatkan iklan.', 'Could not load jobs.'),
                  ),
                );
              }
              if (!s.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = s.data!.docs.where((doc) {
                final d = doc.data();
                return widget.organization ||
                    ((d['deadlineAt'] as Timestamp).toDate().isAfter(
                          DateTime.now(),
                        ) &&
                        d['acceptedCount'] < d['requiredCount']);
              }).toList();
              if (docs.isEmpty) {
                return Center(
                  child: Text(t(c, 'Belum ada iklan.', 'No jobs available.')),
                );
              }
              return ListView(
                children: [
                  for (final doc in docs)
                    ListTile(
                      title: Text(
                        doc.data()['title'] == ''
                            ? t(c, 'Tanpa tajuk', 'Untitled')
                            : doc.data()['title'],
                      ),
                      subtitle: Text(
                        doc.data()['status'] == 'draft'
                            ? t(c, 'Draf', 'Draft')
                            : '${doc.data()['venue']} · ${fmt(doc.data()['startsAt'])}',
                      ),
                      onTap: () => doc.data()['status'] == 'draft'
                          ? edit(doc)
                          : Navigator.push(
                              c,
                              MaterialPageRoute(
                                builder: (_) => _JobDetail(
                                  doc: doc,
                                  uid: widget.uid,
                                  organization: widget.organization,
                                ),
                              ),
                            ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _Editor extends StatefulWidget {
  const _Editor({
    required this.db,
    required this.uid,
    required this.doc,
    required this.approved,
  });
  final FirebaseFirestore db;
  final String uid;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;
  final bool approved;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final ref = widget.doc?.reference ?? widget.db.collection('jobs').doc();
  late final d = widget.doc?.data() ?? {};
  late int revision = d['revision'] ?? 0;
  late String basis = d['payBasis'] ?? 'shift';
  late final fields = {
    for (final key in [
      'title',
      'description',
      'venue',
      'payAmountSen',
      'requiredCount',
    ])
      key: TextEditingController(
        text: key == 'payAmountSen'
            ? (d[key] == null ? '' : (d[key] / 100).toStringAsFixed(2))
            : d[key]?.toString() ?? (key == 'requiredCount' ? '1' : ''),
      ),
  };
  late final dates = <String, Timestamp?>{
    for (final k in ['startsAt', 'endsAt', 'deadlineAt']) k: d[k],
  };
  bool busy = false;
  String? msg;
  @override
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> pick(String k) async {
    final day = my(dates[k]?.toDate() ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: day.hour, minute: day.minute),
    );
    if (time == null || !mounted) return;
    setState(
      () => dates[k] = Timestamp.fromDate(
        DateTime.utc(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ).subtract(const Duration(hours: 8)),
      ),
    );
  }

  Future<void> save(bool publish) async {
    final count = int.tryParse(fields['requiredCount']!.text);
    final money = fields['payAmountSen']!.text.trim();
    if (count == null ||
        count <= 0 ||
        (money.isNotEmpty &&
            !RegExp(r'^\d{1,8}(\.\d{1,2})?$').hasMatch(money))) {
      setState(
        () => msg = t(
          context,
          'Semak bilangan tempat dan kadar bayaran.',
          'Check places and pay.',
        ),
      );
      return;
    }
    final body = <String, dynamic>{
      for (final k in ['title', 'description', 'venue'])
        k: fields[k]!.text.trim(),
      'ownerOrgUid': widget.uid,
      'status': 'draft',
      'payAmountSen': ((double.tryParse(money) ?? 0) * 100).round(),
      'currency': 'MYR',
      'payBasis': basis,
      'requiredCount': count,
      'acceptedCount': 0,
      'applicantCount': 0,
      ...dates,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (publish &&
        (['title', 'description', 'venue'].any((k) => body[k] == '') ||
            body['payAmountSen'] == 0 ||
            dates.values.any((v) => v == null) ||
            !dates['deadlineAt']!.toDate().isAfter(DateTime.now()) ||
            dates['deadlineAt']!.compareTo(dates['startsAt']!) > 0 ||
            dates['startsAt']!.compareTo(dates['endsAt']!) >= 0 ||
            fmt(dates['startsAt']).substring(0, 10) !=
                fmt(dates['endsAt']).substring(0, 10))) {
      setState(
        () => msg = t(
          context,
          'Lengkapkan maklumat. Tarikh tutup mesti sebelum atau tepat masa mula, dan syif mesti dalam satu hari Malaysia.',
          'Complete all fields. Deadline must be no later than start, and the shift must fit one Malaysian day.',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      msg = null;
    });
    try {
      if (revision == 0) {
        await ref.set({...body, 'revision': 1});
        revision = 1;
      } else {
        await widget.db.runTransaction((tx) async {
          final old = (await tx.get(ref)).data();
          if (old?['status'] != 'draft' || old?['revision'] != revision) {
            throw StateError('stale');
          }
          tx.set(ref, {...body, 'revision': revision + 1});
        });
        revision++;
      }
      if (publish) {
        final month = my(DateTime.now()).toString().substring(0, 7);
        final usage = widget.db
            .collection('monthly_usage')
            .doc(widget.uid)
            .collection('months')
            .doc(month);
        await widget.db.runTransaction((tx) async {
          final job = (await tx.get(ref)).data();
          if (job?['status'] != 'draft' || job?['revision'] != revision) {
            throw StateError('stale');
          }
          final used = (await tx.get(usage)).data()?['count'] ?? 0;
          tx.update(ref, {
            'status': 'open',
            'publishedAt': FieldValue.serverTimestamp(),
            'publishedMonthKey': month,
            'updatedAt': FieldValue.serverTimestamp(),
            'revision': revision + 1,
          });
          tx.set(usage, {
            'count': used + 1,
            'jobId': ref.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => msg = t(
            context,
            'Gagal menyimpan atau menerbitkan. Semak sambungan, versi draf, kelulusan dan kuota.',
            'Could not save or publish. Check connection, draft version, approval and quota.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    final labels = {
      'title': t(c, 'Tajuk', 'Title'),
      'description': t(c, 'Skop tugas', 'Description'),
      'venue': t(c, 'Lokasi', 'Venue'),
      'payAmountSen': t(c, 'Bayaran (RM)', 'Pay (RM)'),
      'requiredCount': t(c, 'Bilangan tempat', 'Places'),
      'startsAt': t(c, 'Mula', 'Start'),
      'endsAt': t(c, 'Tamat', 'End'),
      'deadlineAt': t(c, 'Tarikh tutup', 'Deadline'),
    };
    return Scaffold(
      appBar: AppBar(title: Text(t(c, 'Draf kerja', 'Job draft'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final e in fields.entries)
            TextField(
              controller: e.value,
              enabled: !busy,
              decoration: InputDecoration(labelText: labels[e.key]),
              maxLength: switch (e.key) {
                'description' => 2000,
                'title' => 160,
                'venue' => 240,
                _ => null,
              },
            ),
          DropdownButton<String>(
            value: basis,
            items: [
              for (final b in ['shift', 'hour'])
                DropdownMenuItem(
                  value: b,
                  child: Text(
                    b == 'shift'
                        ? t(c, 'Setiap syif', 'Per shift')
                        : t(c, 'Setiap jam', 'Per hour'),
                  ),
                ),
            ],
            onChanged: busy ? null : (b) => setState(() => basis = b!),
          ),
          for (final k in dates.keys)
            OutlinedButton(
              onPressed: busy ? null : () => pick(k),
              child: Text('${labels[k]} (MYT) · ${fmt(dates[k])}'),
            ),
          OutlinedButton(
            onPressed: busy ? null : () => save(false),
            child: Text(t(c, 'Simpan draf', 'Save draft')),
          ),
          FilledButton(
            onPressed: busy || !widget.approved ? null : () => save(true),
            child: Text(t(c, 'Terbitkan iklan', 'Publish job')),
          ),
          if (busy) const LinearProgressIndicator(),
          if (msg != null) Text(msg!),
        ],
      ),
    );
  }
}
