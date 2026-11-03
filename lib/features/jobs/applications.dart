part of 'jobs_page.dart';

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.db, required this.uid, this.jobId});
  final FirebaseFirestore db;
  final String uid;
  final String? jobId;
  @override
  Widget build(BuildContext c) {
    final candidates = jobId != null;
    final query = candidates
        ? db
              .collection('applications')
              .where('ownerOrgUid', isEqualTo: uid)
              .where('jobId', isEqualTo: jobId)
        : db.collection('applications').where('studentId', isEqualTo: uid);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          candidates
              ? t(c, 'Senarai calon', 'Candidates')
              : t(c, 'Permohonan Saya', 'My applications'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (c, s) {
          if (s.hasError) {
            return Center(
              child: Text(
                t(
                  c,
                  'Permohonan gagal dimuatkan.',
                  'Could not load applications.',
                ),
              ),
            );
          }
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = s.data!.docs.toList()
            ..sort(
              (a, b) => ((b.data()['submittedAt'] as Timestamp?)?.seconds ?? 0)
                  .compareTo(
                    (a.data()['submittedAt'] as Timestamp?)?.seconds ?? 0,
                  ),
            );
          if (docs.isEmpty) {
            return Center(
              child: Text(
                t(c, 'Belum ada permohonan.', 'No applications yet.'),
              ),
            );
          }
          return ListView(
            children: [
              for (final doc in docs)
                ListTile(
                  title: Text(
                    doc.data()[candidates ? 'displayName' : 'jobTitle'],
                  ),
                  subtitle: Text(
                    '${t(c, "Menunggu keputusan", "Pending decision")} · ${fmt(doc.data()["submittedAt"])} (MYT)',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _JobDetail extends StatefulWidget {
  const _JobDetail({
    required this.doc,
    required this.uid,
    required this.organization,
  });
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;
  final bool organization;
  @override
  State<_JobDetail> createState() => _JobDetailState();
}

class _JobDetailState extends State<_JobDetail> {
  bool busy = false;
  String? message;
  late final db = widget.doc.reference.firestore;
  late final app = db
      .collection('applications')
      .doc('${widget.doc.id}_${widget.uid}');
  late final existing = app.snapshots();
  late final job = widget.doc.reference.snapshots();
  Future<void> apply() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await db.runTransaction((tx) async {
        if ((await tx.get(app)).exists) return;
        final d = (await tx.get(widget.doc.reference)).data();
        final now = DateTime.now();
        if (d == null ||
            d['status'] != 'open' ||
            !(d['deadlineAt'] as Timestamp).toDate().isAfter(now) ||
            !(d['startsAt'] as Timestamp).toDate().isAfter(now) ||
            d['acceptedCount'] >= d['requiredCount']) {
          throw StateError('closed');
        }
        final profile = (await tx.get(db.collection('users').doc(widget.uid)))
            .data()!;
        tx.set(app, {
          'jobId': widget.doc.id,
          'studentId': widget.uid,
          'ownerOrgUid': d['ownerOrgUid'],
          'jobTitle': d['title'],
          'displayName': profile['displayName'],
          'skillIds': profile['skillIds'] ?? [],
          'selectedExperienceSnapshot': [],
          'status': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
        });
        tx.update(widget.doc.reference, {
          'applicantCount': d['applicantCount'] + 1,
        });
      });
    } on StateError {
      if (mounted) {
        setState(
          () => message = t(
            context,
            'Permohonan sudah ditutup.',
            'Applications are closed.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = t(
            context,
            'Gagal menghantar. Semak sambungan dan status iklan.',
            'Could not submit. Check your connection and the job status.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(
    BuildContext c,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: job,
    builder: (c, s) {
      final d = s.data?.data() ?? widget.doc.data();
      return Scaffold(
        appBar: AppBar(title: Text(d['title'])),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(d['description']),
            Text(d['venue']),
            Text('${fmt(d["startsAt"])} – ${fmt(d["endsAt"])} (MYT)'),
            Text(
              'RM ${(d["payAmountSen"] / 100).toStringAsFixed(2)} / ${d["payBasis"]}',
            ),
            Text(
              '${t(c, "Diperlukan", "Places")}: ${d["requiredCount"]} · ${t(c, "Pemohon", "Applicants")}: ${d["applicantCount"]} · ${t(c, "Diterima", "Accepted")}: ${d["acceptedCount"]}',
            ),
            Text(
              '${t(c, "Tarikh tutup", "Deadline")}: ${fmt(d["deadlineAt"])} (MYT)',
            ),
            if (widget.organization)
              FilledButton(
                onPressed: () => Navigator.push(
                  c,
                  MaterialPageRoute(
                    builder: (_) => _ApplicationList(
                      db: db,
                      uid: widget.uid,
                      jobId: widget.doc.id,
                    ),
                  ),
                ),
                child: Text(t(c, 'Senarai calon', 'Candidates')),
              )
            else
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: existing,
                builder: (c, a) {
                  if (a.hasError) {
                    return Text(
                      t(
                        c,
                        'Status permohonan gagal dimuatkan.',
                        'Could not load application status.',
                      ),
                    );
                  }
                  if (!a.hasData) return const LinearProgressIndicator();
                  if (a.data!.exists) {
                    return Text(t(c, 'Menunggu keputusan', 'Pending decision'));
                  }
                  return FilledButton(
                    onPressed: busy || s.hasError ? null : apply,
                    child: Text(t(c, 'Mohon kerja', 'Apply for job')),
                  );
                },
              ),
            if (message != null) Text(message!),
          ],
        ),
      );
    },
  );
}
