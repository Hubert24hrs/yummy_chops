import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:gud_meal_rider/providers.dart';
import 'package:gud_meal_rider/screens/kyc_screen.dart';
import 'package:gud_meal_rider/screens/sign_up_screen.dart';

const _kinds = ['plate_number', 'hackney_permit', 'riders_card', 'bike', 'guarantor_1_form', 'guarantor_2_form', 'face'];

Map<String, dynamic> kycJson({
  String status = 'draft',
  List<String> missing = const ['permanent address'],
  String? note,
  List<String> redo = const [],
}) =>
    {
      'uid': 'r9',
      'status': status,
      'full_name': 'Bayo Rider',
      'whatsapp_phone': '+2348033333333',
      'email': 'bayo@gmail.com',
      'residential_address': '12 Admiralty Way, Lekki',
      'permanent_address': '',
      'nin': '',
      'review_note': note,
      'guarantors': [
        for (var i = 0; i < 2; i++) {'name': '', 'phone': '', 'email': '', 'address': '', 'occupation': ''},
      ],
      'documents': {
        for (final kind in _kinds) kind: {'label': kind, 'uploaded': false, 'needs_change': redo.contains(kind)},
      },
      'missing': missing,
      'editable': status == 'draft' || status == 'needs_changes',
    };

class _KycApi extends GudMealApi {
  _KycApi(this.kyc) : super(baseUrl: 'http://fake', token: () async => 't');
  Map<String, dynamic> kyc;
  final uploads = <String>[];
  final saved = <Map<String, dynamic>>[];
  final applications = <Map<String, dynamic>>[];
  Object? submitError;

  @override
  Future<Map<String, dynamic>> riderKyc() async => kyc;

  @override
  Future<Map<String, dynamic>> updateRiderKyc(Map<String, dynamic> details) async {
    saved.add(details);
    return kyc;
  }

  @override
  Future<Map<String, dynamic>> uploadKycDocument(String kind, String base64Data) async {
    uploads.add(kind);
    return kyc;
  }

  @override
  Future<Map<String, dynamic>> submitRiderKyc() async {
    if (submitError != null) throw submitError!;
    return kyc = {...kyc, 'status': 'submitted', 'editable': false};
  }

  @override
  Future<void> applyAsRider(Map<String, dynamic> application) async => applications.add(application);
}

class _FakePhotos implements KycPhotoSource {
  final picks = <(PhotoFrom, bool)>[];

  @override
  Future<Uint8List?> pick(PhotoFrom from, {bool selfie = false}) async {
    picks.add((from, selfie));
    return Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
  }
}

Widget _kycApp(_KycApi api, _FakePhotos photos) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(const GmUser(uid: 'r9'))),
        apiProvider.overrideWithValue(api),
        kycPhotoSourceProvider.overrideWithValue(photos),
      ],
      child: const MaterialApp(home: KycScreen()),
    );

/// The KYC screen's own list (its text fields have scrollables of their own).
final _list = find.byType(Scrollable).first;

void main() {
  testWidgets('a new rider sees what is left and uploads each photo with the camera, the gallery or a selfie',
      (tester) async {
    final api = _KycApi(kycJson());
    final photos = _FakePhotos();
    await tester.pumpWidget(_kycApp(api, photos));
    await tester.pumpAndSettle();
    expect(find.text('Complete your KYC'), findsOneWidget);
    expect(find.textContaining('1 thing still to do'), findsOneWidget);
    expect(find.text('Name: Bayo Rider'), findsOneWidget);

    await tester.tap(find.byTooltip('Take a photo: plate_number'));
    await tester.pumpAndSettle();
    expect(api.uploads, ['plate_number']);
    expect(photos.picks.single, (PhotoFrom.camera, false));

    await tester.scrollUntilVisible(find.byTooltip('Choose a photo: bike'), 300, scrollable: _list);
    await tester.tap(find.byTooltip('Choose a photo: bike'));
    await tester.pumpAndSettle();
    expect(api.uploads.last, 'bike');
    expect(photos.picks.last, (PhotoFrom.gallery, false));

    await tester.scrollUntilVisible(find.byTooltip('Take a selfie'), 300, scrollable: _list);
    await tester.tap(find.byTooltip('Take a selfie'));
    await tester.pumpAndSettle();
    expect(api.uploads.last, 'face');
    expect(photos.picks.last, (PhotoFrom.camera, true)); // the front camera
  });

  testWidgets('submitting saves the typed details first and shows what is still missing', (tester) async {
    final api = _KycApi(kycJson())..submitError = ApiException(422, 'validation_failed', 'Still to do: NIN');
    await tester.pumpWidget(_kycApp(api, _FakePhotos()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('permanent-address')), '4 Ogui Road, Enugu');
    await tester.scrollUntilVisible(find.byKey(const ValueKey('guarantor-1-name')), 300, scrollable: _list);
    await tester.enterText(find.byKey(const ValueKey('guarantor-1-name')), 'Ada Obi');
    final submit = find.byKey(const ValueKey('submit-kyc'));
    await tester.scrollUntilVisible(submit, 300, scrollable: _list);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(api.saved.single['permanent_address'], '4 Ogui Road, Enugu');
    expect((api.saved.single['guarantors'] as List).first['name'], 'Ada Obi');
    expect(api.saved.single.containsKey('nin'), isFalse); // nothing typed: the saved NIN stays as it is
    await tester.scrollUntilVisible(find.byKey(const ValueKey('kyc-message')), -300, scrollable: _list);
    expect(find.text('Still to do: NIN'), findsOneWidget);
  });

  testWidgets('the team asked for changes: their note shows and the item to redo is marked', (tester) async {
    final api = _KycApi(kycJson(status: 'needs_changes', note: 'The plate number photo is blurred', redo: ['plate_number']));
    await tester.pumpWidget(_kycApp(api, _FakePhotos()));
    await tester.pumpAndSettle();
    expect(find.text('Please fix your KYC'), findsOneWidget);
    expect(find.text('The plate number photo is blurred'), findsOneWidget);
    expect(find.text('Please upload this again'), findsOneWidget);
  });

  testWidgets('once submitted nothing can be changed, and a verified rider is told they can go online',
      (tester) async {
    await tester.pumpWidget(_kycApp(_KycApi(kycJson(status: 'submitted', missing: const [])), _FakePhotos()));
    await tester.pumpAndSettle();
    expect(find.text('With the team for review'), findsOneWidget);
    expect(find.byTooltip('Take a photo: plate_number'), findsNothing);
    expect(find.byKey(const ValueKey('submit-kyc')), findsNothing);

    await tester.pumpWidget(_kycApp(_KycApi(kycJson(status: 'verified', missing: const [])), _FakePhotos()));
    await tester.pumpAndSettle();
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('You can go online and take deliveries.'), findsOneWidget);
  });

  testWidgets('signing up creates the account, applies as a rider, refreshes the token and opens the KYC',
      (tester) async {
    final api = _KycApi(kycJson());
    final auth = FakeAuthRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth), apiProvider.overrideWithValue(api)],
      child: MaterialApp.router(
        routerConfig: GoRouter(initialLocation: '/sign-up', routes: [
          GoRoute(path: '/sign-up', builder: (_, _) => const RiderSignUpScreen()),
          GoRoute(path: '/kyc', builder: (_, _) => const Scaffold(body: Text('KYC SCREEN'))),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('name')), 'Bayo Rider');
    await tester.enterText(find.byKey(const ValueKey('phone')), '+2348033333333');
    await tester.enterText(find.byKey(const ValueKey('email')), 'bayo@gmail.com');
    await tester.enterText(find.byKey(const ValueKey('password')), 'secret123');
    await tester.enterText(find.byKey(const ValueKey('address')), '12 Admiralty Way, Lekki');
    final signUp = find.byKey(const ValueKey('sign-up'));
    await tester.ensureVisible(signUp);
    await tester.tap(signUp);
    await tester.pumpAndSettle();
    expect(auth.currentUser?.email, 'bayo@gmail.com');
    expect(api.applications.single, {
      'full_name': 'Bayo Rider',
      'phone': '+2348033333333',
      'email': 'bayo@gmail.com',
      'residential_address': '12 Admiralty Way, Lekki',
      'vehicle': 'motorcycle',
      'city': 'Lagos',
    });
    expect(auth.tokenRefreshes, 1);
    expect(find.text('KYC SCREEN'), findsOneWidget);
  });
}
