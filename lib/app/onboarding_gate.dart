import '../features/jobs/jobs_page.dart';
import 'review_queue.dart';

import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.auth,
    required this.uid,
    required this.account,
    required this.signOut,
  });
  final FirebaseAuth auth;
  final String uid;
  final Widget account;
  final VoidCallback signOut;
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  final draftFields = <String, TextEditingController>{
    for (final key in [
      'officialName',
      'organizationType',
      'affiliation',
      'representativeName',
      'representativePosition',
    ])
      key: TextEditingController(),
  };
  static const documents = MethodChannel('siswaworks/documents');
  bool reviewer = false;
  String? rejectionReason;
  String? evidenceName;
  int draftRevision = 0;
  final name = TextEditingController();
  String step = 'loading';
  String? selected;
  String? notice;
  bool busy = false;
  FirebaseFirestore get db =>
      FirebaseFirestore.instanceFor(app: widget.auth.app);
  DocumentReference<Map<String, dynamic>> get profile =>
      db.collection('users').doc(widget.uid);
  User get user {
    final current = widget.auth.currentUser;
    if (current == null || current.uid != widget.uid) {
      throw StateError('Session changed');
    }
    return current;
  }

  String tr(String ms, String en) =>
      Localizations.localeOf(context).languageCode == 'ms' ? ms : en;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final field in draftFields.values) {
      field.dispose();
    }
    name.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      step = 'loading';
      notice = null;
    });
    try {
      await user.reload();
      String next = 'verify';
      if (user.emailVerified) {
        await user.getIdToken(true);
        const server = GetOptions(source: Source.server);
        final snapshot = await profile.get(server);
        final data = snapshot.data();
        if (!snapshot.exists) {
          final intent = await db
              .collection('signup_intents')
              .doc(widget.uid)
              .get(server);
          final type = intent.data()?['accountType'];
          if (type == 'individual' || type == 'organization') {
            await createProfile(type as String);
            await load();
            return;
          }
          next = 'choose';
        } else if (data?['accountType'] == 'individual') {
          reviewer =
              (await db.collection('admins').doc(widget.uid).get(server))
                  .data()?['role'] ==
              'organizationReviewer';
          next = (data?['displayName'] as String? ?? '').trim().isEmpty
              ? 'name'
              : 'individual';
        } else if (data?['accountType'] == 'organization') {
          final request = await db
              .collection('organization_requests')
              .doc(widget.uid)
              .get(server);
          final record = request.data();
          final status = record?['status'];
          rejectionReason = record?['rejectionReason'] as String?;
          if (!request.exists ||
              ['pending', 'draft', 'rejected'].contains(status)) {
            if (!mounted) return;
            evidenceName = record?['evidenceName'] as String?;
            draftRevision = record?['revision'] as int? ?? 0;
            for (final entry in draftFields.entries) {
              entry.value.text = record?[entry.key] as String? ?? '';
            }
          }
          next = !request.exists
              ? 'register'
              : switch (status) {
                  'approved' ||
                  'pending' ||
                  'rejected' ||
                  'withdrawn' ||
                  'draft' => status as String,
                  _ => 'error',
                };
        } else {
          next = 'legacy';
        }
      }
      if (mounted) setState(() => step = next);
    } catch (error) {
  if (error is FirebaseException) {
    debugPrint(
      'Account loading failed: ${error.plugin}/${error.code}',
    );
  } else {
    debugPrint('Account loading failed: ${error.runtimeType}');
  }
  if (mounted) setState(() => step = 'error');
}
  }

  Future<void> act(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => notice = tr(
            'Tindakan gagal. Cuba semula.',
            'Action failed. Try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveDraft({
    Map<Object?, Object?>? file,
    bool submit = false,
  }) async {
    final ref = db.collection('organization_requests').doc(widget.uid);
    final values = {
      for (final field in draftFields.entries)
        field.key: field.value.text.trim(),
    };
    final expected = draftRevision;
    final saved = await db.runTransaction((tx) async {
      final previous = await tx.get(ref);
      if (previous.exists &&
          (![
                'draft',
                'rejected',
                'pending',
              ].contains(previous.data()?['status']) ||
              previous.data()?['revision'] != expected)) {
        return false;
      }
      if (!previous.exists && expected != 0) return false;
      if (file != null) {
        tx.set(ref.collection('documents').doc('evidence'), {
          'name': file['name'],
          'content': Blob(file['bytes'] as Uint8List),
          'revision': expected + 1,
        });
      }
      tx.set(ref, {
        ...values,
        if (file != null || evidenceName != null)
          'evidenceName': file?['name'] ?? evidenceName,
        if (submit) 'submittedAt': FieldValue.serverTimestamp(),
        'status': submit ? 'pending' : 'draft',
        'revision': expected + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!mounted) return;
    if (!saved) {
      setState(
        () => notice = tr(
          'Draf telah berubah. Semak semula untuk memuatkan versi terkini.',
          'Draft changed. Check again to load the latest version.',
        ),
      );
      return;
    }
    setState(() {
      draftRevision = expected + 1;
      step = submit ? 'pending' : 'draft';
      if (file != null) evidenceName = file['name'] as String;
      notice = submit
          ? null
          : file != null
          ? tr(
              'Fail dimuat naik. Draf disimpan.',
              'File uploaded. Draft saved.',
            )
          : tr(
              'Draf disimpan. Anda boleh sambung kemudian.',
              'Draft saved. You can return later.',
            );
    });
  }

  Future<void> confirmType() async {
    final type = selected;
    if (type == null) return;
    await createProfile(type);
    await load();
  }

  Future<void> createProfile(String type) async {
    await db.runTransaction((tx) async {
      final existing = await tx.get(profile);
      if (existing.exists) return;
      tx.set(profile, {
        'accountType': type,
        'displayName': '',
        'skillIds': [],
        'preferredCategoryIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = {
      'verify': tr('Sahkan e-mel anda', 'Verify your email'),
      'choose': tr(
        'Pilih jenis akaun kekal',
        'Choose your permanent account type',
      ),
      'name': tr('Lengkapkan nama paparan', 'Complete your display name'),
      'individual': tr('Semua Kerja', 'All jobs'),
      'register': tr('Pendaftaran organisasi', 'Organization registration'),
      'draft': tr(
        'Draf pendaftaran organisasi',
        'Organization registration draft',
      ),
      'pending': tr(
        'Menunggu semakan organisasi',
        'Organization review pending',
      ),
      'rejected': tr('Pendaftaran ditolak', 'Registration rejected'),
      'withdrawn': tr('Pendaftaran ditarik balik', 'Registration withdrawn'),
      'approved': tr('Ruang organisasi', 'Organization workspace'),
      'legacy': tr(
        'Hubungi penyelaras untuk migrasi akaun lama.',
        'Contact the coordinator to migrate this account.',
      ),
      'error': tr(
        'Status akaun gagal dimuatkan.',
        'Could not load account status.',
      ),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('SiswaWorks'),
        actions: [
          IconButton(
            tooltip: tr('Akaun', 'Account'),
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => widget.account),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (step == 'loading')
              const LinearProgressIndicator()
            else
              Text(
                titles[step]!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            Text(widget.auth.currentUser?.email ?? ''),
            if (['individual', 'approved', 'pending'].contains(step))
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobsPage(
                      db: db,
                      uid: widget.uid,
                      organization: step != 'individual',
                      approved: step == 'approved',
                    ),
                  ),
                ),
                child: Text(
                  step == 'individual'
                      ? tr('Lihat semua kerja', 'Browse all jobs')
                      : tr('Iklan organisasi', 'Organization jobs'),
                ),
              ),
            if (step == 'individual' && reviewer)
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReviewQueue(db: db, uid: widget.uid),
                  ),
                ),
                child: Text(tr('Semakan Organisasi', 'Organization review')),
              ),
            if (step == 'pending')
              OutlinedButton(
                onPressed: busy ? null : () => act(saveDraft),
                child: Text(tr('Buka semula sebagai draf', 'Reopen as draft')),
              ),
            if (step == 'rejected') Text(rejectionReason ?? ''),
            if (step == 'register' ||
                step == 'draft' ||
                step == 'rejected') ...[
              Text(
                tr(
                  'Isi maklumat yang tersedia. E-mel di atas ialah e-mel akaun anda.',
                  'Fill in the details you have. The email above is your account email.',
                ),
              ),
              for (final field in draftFields.entries)
                TextField(
                  controller: field.value,
                  enabled: !busy,
                  onChanged: (_) => setState(() {}),
                  maxLength: 160,
                  decoration: InputDecoration(
                    labelText: switch (field.key) {
                      'officialName' => tr(
                        'Nama rasmi organisasi',
                        'Official organization name',
                      ),
                      'organizationType' => tr(
                        'Jenis organisasi',
                        'Organization type',
                      ),
                      'affiliation' => tr(
                        'Kolej, fakulti atau kampus (pilihan)',
                        'College, faculty or campus (optional)',
                      ),
                      'representativeName' => tr(
                        'Nama wakil',
                        'Representative name',
                      ),
                      _ => tr('Jawatan wakil', 'Representative position'),
                    },
                  ),
                ),
              Text(
                tr('Dokumen pengesahan', 'Verification document'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => act(() async {
                        final saved = await documents.invokeMethod<bool>(
                          'saveTemplate',
                        );
                        if (saved == true && mounted) {
                          setState(
                            () => notice = tr(
                              'Templat disimpan.',
                              'Template saved.',
                            ),
                          );
                        }
                      }),
                child: Text(
                  tr('Muat turun templat PDF', 'Download PDF template'),
                ),
              ),
              Text(
                evidenceName ??
                    tr(
                      'Belum ada dokumen. PDF sahaja, maksimum 900 KB.',
                      'No document yet. PDF only, up to 900 KB.',
                    ),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => act(() async {
                        try {
                          final file = await documents
                              .invokeMapMethod<Object?, Object?>(
                                'pickEvidence',
                              );
                          if (file != null && mounted) {
                            await saveDraft(file: file);
                          }
                        } on PlatformException {
                          if (mounted) {
                            setState(
                              () => notice = tr(
                                'Pilih PDF yang boleh dibaca dan tidak melebihi 900 KB.',
                                'Choose a readable PDF no larger than 900 KB.',
                              ),
                            );
                          }
                        }
                      }),
                child: Text(
                  evidenceName == null
                      ? tr('Muat naik PDF', 'Upload PDF')
                      : tr('Ganti PDF', 'Replace PDF'),
                ),
              ),
              FilledButton(
                onPressed:
                    busy ||
                        evidenceName == null ||
                        draftFields.entries.any(
                          (e) =>
                              e.key != 'affiliation' &&
                              e.value.text.trim().isEmpty,
                        )
                    ? null
                    : () => act(() => saveDraft(submit: true)),
                child: Text(tr('Hantar untuk semakan', 'Submit for review')),
              ),
              FilledButton(
                onPressed: busy ? null : () => act(saveDraft),
                child: Text(tr('Simpan draf', 'Save draft')),
              ),
              if (notice != null)
                TextButton(
                  onPressed: busy ? null : load,
                  child: Text(tr('Semak semula', 'Check again')),
                ),
            ],
            if (step == 'verify')
              FilledButton(
                onPressed: busy
                    ? null
                    : () => act(() async {
                        await user.sendEmailVerification();
                        if (mounted) {
                          setState(
                            () => notice = tr(
                              'Pautan dihantar. Semak peti masuk anda.',
                              'Link sent. Check your inbox.',
                            ),
                          );
                        }
                      }),
                child: Text(
                  tr('Hantar pautan pengesahan', 'Send verification link'),
                ),
              ),
            if (step == 'verify' || step == 'error' || step == 'pending')
              TextButton(
                onPressed: busy ? null : load,
                child: Text(tr('Semak semula', 'Check again')),
              ),
            if (step == 'choose') ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final type in ['individual', 'organization'])
                    ChoiceChip(
                      label: Text(
                        type == 'individual'
                            ? tr('Individu', 'Individual')
                            : tr('Organisasi', 'Organization'),
                      ),
                      selected: selected == type,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => selected = type),
                    ),
                ],
              ),
              FilledButton(
                onPressed: busy || selected == null
                    ? null
                    : () => act(confirmType),
                child: Text(tr('Sahkan jenis akaun', 'Confirm account type')),
              ),
            ],
            if (step == 'name') ...[
              TextField(
                controller: name,
                maxLength: 80,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: tr('Nama paparan', 'Display name'),
                ),
              ),
              FilledButton(
                onPressed: busy || name.text.trim().isEmpty
                    ? null
                    : () => act(() async {
                        await profile.update({
                          'displayName': name.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        await load();
                      }),
                child: Text(tr('Simpan', 'Save')),
              ),
            ],
            if (notice != null) Text(notice!),
            TextButton(
              onPressed: busy ? null : widget.signOut,
              child: Text(tr('Log keluar', 'Sign out')),
            ),
          ],
        ),
      ),
    );
  }
}
