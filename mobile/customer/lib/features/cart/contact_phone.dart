import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers.dart';
import '../auth/sign_in_screen.dart' show normaliseNigerianPhone;
import '../profile/account_section.dart' show homeAddress;

/// Shown at checkout while a delivery order has no phone number: the rider must be able to call the customer.
const missingPhoneMessage = 'Add a phone number so the rider can call you';

/// Shown when the number typed is not a Nigerian phone number.
const invalidPhoneMessage = 'Enter a Nigerian phone number, like 0803 000 0000 or +234 803 000 0000';

/// The number the rider calls, in E.164 (+234…), or null when [input] is not a Nigerian phone number.
String? riderContactPhone(String? input) => input == null ? null : normaliseNigerianPhone(input);

/// The phone number used at the last checkout, kept on this phone so the next checkout is filled in. It belongs to
/// the customer who used it: after they sign out, the next person on the phone does not get their number (the rider
/// would call the wrong person).
abstract class ContactPhoneStore {
  /// The number [uid] used last, or null when the last checkout on this phone was someone else's.
  String? phoneFor(String? uid);
  Future<void> save(String phone, {String? uid});
}

/// In memory (tests, and when the phone's storage can't be read). A number given without [uid] is anyone's.
class MemoryContactPhoneStore implements ContactPhoneStore {
  MemoryContactPhoneStore([this.phone, this.uid]);
  String? phone;
  String? uid;

  @override
  String? phoneFor(String? uid) => this.uid == null || this.uid == uid ? phone : null;

  @override
  Future<void> save(String value, {String? uid}) async {
    phone = value;
    this.uid = uid;
  }
}

/// In the app's shared preferences, read once in `main()`.
class SharedPrefsContactPhoneStore implements ContactPhoneStore {
  SharedPrefsContactPhoneStore._(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'checkout_contact_phone';
  static const _uidKey = 'checkout_contact_phone_uid';

  /// The store, or one in memory when the phone's storage can't be read.
  static Future<ContactPhoneStore> open() async {
    try {
      return SharedPrefsContactPhoneStore._(await SharedPreferences.getInstance());
    } catch (_) {
      return MemoryContactPhoneStore();
    }
  }

  @override
  String? phoneFor(String? uid) {
    final owner = _prefs.getString(_uidKey);
    return owner == null || owner == uid ? _prefs.getString(_key) : null;
  }

  @override
  Future<void> save(String value, {String? uid}) async {
    await _prefs.setString(_key, value);
    if (uid == null) {
      await _prefs.remove(_uidKey);
    } else {
      await _prefs.setString(_uidKey, uid);
    }
  }
}

final contactPhoneStoreProvider = Provider<ContactPhoneStore>((ref) => MemoryContactPhoneStore());

/// The number checkout starts with: the address's own contact phone, else the one used last time on this phone,
/// else the Home address's, else the account's (phone sign-in).
String? initialContactPhone({DeliveryAddress? address, String? remembered, List<DeliveryAddress> saved = const [], String? account}) {
  for (final candidate in [address?.contactPhone, remembered, homeAddress(saved)?.contactPhone, account]) {
    if (candidate != null && candidate.trim().isNotEmpty) return candidate.trim();
  }
  return null;
}

/// After an order is placed: the number is kept on this phone, and on the saved address it was delivered to (or the
/// Home address) when that one does not have it yet, so the next checkout is filled in. Never fails the order, and
/// may finish after checkout has gone (everything it needs is read straight away).
Future<void> rememberContactPhone(WidgetRef ref, String phone, {DeliveryAddress? deliveredTo}) async {
  final store = ref.read(contactPhoneStoreProvider);
  final uid = ref.read(authRepositoryProvider).currentUser?.uid;
  final api = ref.read(apiProvider);
  final addresses = ref.read(addressesProvider.future);
  void refresh() {
    try {
      ref.invalidate(addressesProvider);
    } catch (_) {} // checkout has gone: the list is read again next time anyway
  }

  try {
    await store.save(phone, uid: uid);
  } catch (_) {}
  try {
    final saved = await addresses;
    DeliveryAddress? target;
    if (deliveredTo?.id != null) {
      for (final a in saved) {
        if (a.id == deliveredTo!.id) target = a;
      }
    }
    target ??= homeAddress(saved);
    final id = target?.id;
    if (target == null || id == null || riderContactPhone(target.contactPhone) == phone) return;
    await api.updateAddress(id, target.copyWith(contactPhone: phone));
    refresh();
  } catch (_) {
    // The address book is a convenience: the order already has the number.
  }
}
