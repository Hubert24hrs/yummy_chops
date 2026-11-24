import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';

/// The rider's KYC (docs/adr/0027-rider-kyc.md): what a new rider completes before the team verifies them.
final riderKycProvider = FutureProvider<Map<String, dynamic>>((ref) => ref.watch(apiProvider).riderKyc());

/// The printable guarantor form on the website.
final guarantorFormUri = Uri.parse('https://yummy247.com/ride/guarantor-form');

enum PhotoFrom { camera, gallery }

/// Takes or picks a photo for the KYC, already made smaller for the upload. A fake in tests.
abstract class KycPhotoSource {
  Future<Uint8List?> pick(PhotoFrom from, {bool selfie = false});
}

class ImagePickerSource implements KycPhotoSource {
  final _picker = ImagePicker();

  @override
  Future<Uint8List?> pick(PhotoFrom from, {bool selfie = false}) async {
    final file = await _picker.pickImage(
      source: from == PhotoFrom.camera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 75,
    );
    return file?.readAsBytes();
  }
}

final kycPhotoSourceProvider = Provider<KycPhotoSource>((ref) => ImagePickerSource());

/// The vehicle papers and photos, in the order the API lists them.
const vehicleDocuments = ['plate_number', 'hackney_permit', 'riders_card', 'bike'];
const guarantorFields = {
  'name': 'Full name',
  'phone': 'Phone number',
  'email': 'Email',
  'address': 'Address',
  'occupation': 'Occupation',
};

/// What the KYC's status means for the rider: a title and a line under it.
(String, String) kycStatusText(Map<String, dynamic> kyc) {
  final missing = (kyc['missing'] as List?)?.length ?? 0;
  final note = (kyc['review_note'] as String?)?.trim() ?? '';
  return switch (kyc['status']) {
    'verified' => ('Verified', 'You can go online and take deliveries.'),
    'submitted' => ('With the team for review', 'We check everything and let you know. No changes meanwhile.'),
    'needs_changes' => ('Please fix your KYC', note.isEmpty ? 'The team asked for changes: see the items marked below.' : note),
    'rejected' => ('Not approved', note.isEmpty ? 'Your sign-up was not approved.' : note),
    _ => (
        'Complete your KYC',
        missing == 0
            ? 'All done: submit it for checking.'
            : '${missing == 1 ? '1 thing' : '$missing things'} still to do. Your answers are saved as you go.',
      ),
  };
}

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  final _address = TextEditingController();
  final _nin = TextEditingController();
  final _guarantors = [
    for (var i = 0; i < 2; i++) {for (final field in guarantorFields.keys) field: TextEditingController()},
  ];
  bool _filled = false;
  bool _saving = false;
  String? _uploading;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _address.dispose();
    _nin.dispose();
    for (final g in _guarantors) {
      for (final c in g.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  /// The typed fields start from what was saved (once: the rider's typing is never overwritten).
  void _fill(Map<String, dynamic> kyc) {
    if (_filled) return;
    _filled = true;
    _address.text = (kyc['permanent_address'] as String?) ?? '';
    final saved = (kyc['guarantors'] as List?) ?? const [];
    for (var i = 0; i < _guarantors.length && i < saved.length; i++) {
      final g = Map<String, dynamic>.from(saved[i] as Map);
      for (final field in guarantorFields.keys) {
        _guarantors[i][field]!.text = (g[field] as String?) ?? '';
      }
    }
  }

  Map<String, dynamic> _details() => {
        'permanent_address': _address.text.trim(),
        if (_nin.text.trim().isNotEmpty) 'nin': _nin.text.trim(),
        'guarantors': [
          for (final g in _guarantors) {for (final e in g.entries) e.key: e.value.text.trim()},
        ],
      };

  void _say(String message, {bool error = false}) => setState(() {
        _message = message;
        _messageIsError = error;
      });

  Future<bool> _save({bool quiet = false}) async {
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).updateRiderKyc(_details());
      _nin.clear(); // saved: from now on only its last four digits are shown
      ref.invalidate(riderKycProvider);
      if (!quiet) _say('Saved.');
      return true;
    } on ApiException catch (e) {
      _say(e.message, error: true);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _upload(String kind, PhotoFrom from) async {
    final bytes = await ref.read(kycPhotoSourceProvider).pick(from, selfie: kind == 'face');
    if (bytes == null || !mounted) return;
    setState(() => _uploading = kind);
    try {
      await ref.read(apiProvider).uploadKycDocument(kind, base64Encode(bytes));
      ref.invalidate(riderKycProvider);
      _say('Uploaded.');
    } on ApiException catch (e) {
      _say(e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _submit() async {
    if (!await _save(quiet: true)) return;
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).submitRiderKyc();
      ref.invalidate(riderKycProvider);
      ref.invalidate(riderProfileProvider);
      _say('Submitted. We check everything and let you know.');
    } on ApiException catch (e) {
      _say(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyc = ref.watch(riderKycProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your KYC')),
      body: kyc.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
        data: (k) {
          _fill(k);
          final editable = k['editable'] == true;
          final documents = Map<String, dynamic>.from((k['documents'] as Map?) ?? const {});
          Map<String, dynamic> doc(String kind) => Map<String, dynamic>.from((documents[kind] as Map?) ?? {'label': kind});
          final savedNin = (k['nin'] as String?) ?? '';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              KycStatusCard(kyc: k),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _message!,
                    key: const ValueKey('kyc-message'),
                    style: TextStyle(color: _messageIsError ? Theme.of(context).colorScheme.error : null),
                  ),
                ),
              const _Heading('Your details'),
              _ReadOnly('Name', k['full_name']),
              _ReadOnly('WhatsApp number', k['whatsapp_phone']),
              _ReadOnly('Residential address', k['residential_address']),
              TextField(
                key: const ValueKey('permanent-address'),
                controller: _address,
                enabled: editable,
                decoration: const InputDecoration(labelText: 'Permanent address'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('nin'),
                controller: _nin,
                enabled: editable,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                decoration: InputDecoration(
                  labelText: 'NIN (National Identification Number)',
                  helperText: savedNin.isEmpty ? '11 digits' : 'Saved: $savedNin. Type it again only to change it.',
                ),
              ),
              const _Heading('Your vehicle papers'),
              for (final kind in vehicleDocuments)
                KycDocumentTile(
                  kind: kind,
                  doc: doc(kind),
                  editable: editable,
                  busy: _uploading == kind,
                  onPick: (from) => _upload(kind, from),
                ),
              const _Heading('Your two guarantors'),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => launchUrl(guarantorFormUri, mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Print the guarantor form'),
                ),
              ),
              const Text('Each guarantor fills in and signs a printed form. Upload a clear photo of each signed form.'),
              for (var i = 0; i < 2; i++) ...[
                const SizedBox(height: 12),
                Text('Guarantor ${i + 1}', style: Theme.of(context).textTheme.titleMedium),
                for (final field in guarantorFields.entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      key: ValueKey('guarantor-${i + 1}-${field.key}'),
                      controller: _guarantors[i][field.key],
                      enabled: editable,
                      keyboardType: switch (field.key) {
                        'phone' => TextInputType.phone,
                        'email' => TextInputType.emailAddress,
                        _ => TextInputType.text,
                      },
                      decoration: InputDecoration(labelText: field.key == 'email' ? 'Email (if they have one)' : field.value),
                    ),
                  ),
                KycDocumentTile(
                  kind: 'guarantor_${i + 1}_form',
                  doc: doc('guarantor_${i + 1}_form'),
                  editable: editable,
                  busy: _uploading == 'guarantor_${i + 1}_form',
                  onPick: (from) => _upload('guarantor_${i + 1}_form', from),
                ),
              ],
              const _Heading('Face verification'),
              const Text('Take a selfie in good light, looking straight at the camera, with nothing covering your face.'),
              KycDocumentTile(
                kind: 'face',
                doc: doc('face'),
                editable: editable,
                busy: _uploading == 'face',
                selfie: true,
                onPick: (from) => _upload('face', from),
              ),
              if (editable) ...[
                const SizedBox(height: 20),
                OutlinedButton(onPressed: _saving ? null : _save, child: const Text('Save details')),
                const SizedBox(height: 8),
                FilledButton(
                  key: const ValueKey('submit-kyc'),
                  onPressed: _saving || _uploading != null ? null : _submit,
                  child: const Text('Submit for checking'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The KYC's state at the top of the KYC screen and on the home screen.
class KycStatusCard extends StatelessWidget {
  const KycStatusCard({super.key, required this.kyc, this.onTap});
  final Map<String, dynamic> kyc;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (title, body) = kycStatusText(kyc);
    final (icon, color) = switch (kyc['status']) {
      'verified' => (Icons.verified_rounded, GmLight.success),
      'submitted' => (Icons.hourglass_top_rounded, GmLight.info),
      'needs_changes' || 'rejected' => (Icons.error_rounded, GmLight.warning),
      _ => (Icons.badge_rounded, Theme.of(context).colorScheme.primary),
    };
    return Card(
      key: const ValueKey('kyc-status'),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(body),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

/// One document or photo: its state, and buttons to take or choose it while the KYC can be changed.
class KycDocumentTile extends StatelessWidget {
  const KycDocumentTile({
    super.key,
    required this.kind,
    required this.doc,
    required this.editable,
    required this.onPick,
    this.busy = false,
    this.selfie = false,
  });
  final String kind;
  final Map<String, dynamic> doc;
  final bool editable;
  final bool busy;
  final bool selfie;
  final ValueChanged<PhotoFrom> onPick;

  @override
  Widget build(BuildContext context) {
    final label = (doc['label'] as String?) ?? kind;
    final uploaded = doc['uploaded'] == true;
    final redo = doc['needs_change'] == true;
    return ListTile(
      key: ValueKey('kyc-doc-$kind'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        redo ? Icons.error_rounded : (uploaded ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded),
        color: redo ? GmLight.warning : (uploaded ? GmLight.success : null),
      ),
      title: Text(label),
      subtitle: Text(redo ? 'Please upload this again' : (uploaded ? 'Uploaded' : 'To do')),
      trailing: !editable
          ? null
          : busy
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: selfie ? 'Take a selfie' : 'Take a photo: $label',
                      icon: Icon(selfie ? Icons.face_retouching_natural_rounded : Icons.photo_camera_rounded),
                      onPressed: () => onPick(PhotoFrom.camera),
                    ),
                    if (!selfie)
                      IconButton(
                        tooltip: 'Choose a photo: $label',
                        icon: const Icon(Icons.photo_library_rounded),
                        onPressed: () => onPick(PhotoFrom.gallery),
                      ),
                  ],
                ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      );
}

class _ReadOnly extends StatelessWidget {
  const _ReadOnly(this.label, this.value);
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final text = (value as String?)?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: text),
      ])),
    );
  }
}
