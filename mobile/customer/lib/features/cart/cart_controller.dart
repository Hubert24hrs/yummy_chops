import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gud_meal_core/gud_meal_core.dart';

/// Display-only cart. Prices shown here are estimates; the server quote is authoritative.
/// One cart holds items from any number of shops: each shop becomes its own order, all paid at once.
class CartItem {
  const CartItem({
    required this.itemId,
    required this.name,
    required this.unitPriceKobo,
    required this.quantity,
    this.selections = const [],
    this.selectionLabels = const [],
    this.notes,
    this.restaurantId = '',
    this.restaurantName = '',
  });

  final String itemId;
  final String name;
  final int unitPriceKobo;
  final int quantity;
  final List<OptionSelection> selections;
  final List<String> selectionLabels;
  final String? notes;

  /// The shop this item is bought from (set by [CartController.add]).
  final String restaurantId;
  final String restaurantName;

  /// Same shop, same item, same choices and notes = the same line.
  String get key {
    final sel = selections.map((s) => '${s.groupId}:${([...s.choiceIds]..sort()).join(',')}').toList()..sort();
    return '$restaurantId#$itemId#${sel.join('|')}#${notes ?? ''}';
  }

  CartItem copyWith({int? quantity, String? restaurantId, String? restaurantName}) => CartItem(
        itemId: itemId,
        name: name,
        unitPriceKobo: unitPriceKobo,
        quantity: quantity ?? this.quantity,
        selections: selections,
        selectionLabels: selectionLabels,
        notes: notes,
        restaurantId: restaurantId ?? this.restaurantId,
        restaurantName: restaurantName ?? this.restaurantName,
      );
}

/// The items of one shop in the cart.
class CartShop {
  const CartShop({required this.restaurantId, required this.restaurantName, required this.items});
  final String restaurantId;
  final String restaurantName;
  final List<CartItem> items;

  int get count => items.fold(0, (n, i) => n + i.quantity);
  int get subtotalKobo => items.fold(0, (n, i) => n + i.unitPriceKobo * i.quantity);

  List<CartLine> toLines() => [
        for (final i in items) CartLine(itemId: i.itemId, quantity: i.quantity, selections: i.selections, notes: i.notes),
      ];
}

class CartState {
  const CartState({this.items = const []});
  final List<CartItem> items;

  int get count => items.fold(0, (n, i) => n + i.quantity);
  int get subtotalKobo => items.fold(0, (n, i) => n + i.unitPriceKobo * i.quantity);
  bool get isEmpty => items.isEmpty;

  /// Every line of every shop (a quote is asked per shop: see [CartShop.toLines]).
  List<CartLine> toLines() => [
        for (final i in items) CartLine(itemId: i.itemId, quantity: i.quantity, selections: i.selections, notes: i.notes),
      ];

  /// The items grouped by shop, shops in the order they were first added.
  List<CartShop> get shops {
    final byShop = <String, List<CartItem>>{};
    final names = <String, String>{};
    for (final i in items) {
      (byShop[i.restaurantId] ??= []).add(i);
      names.putIfAbsent(i.restaurantId, () => i.restaurantName);
    }
    return [for (final e in byShop.entries) CartShop(restaurantId: e.key, restaurantName: names[e.key]!, items: e.value)];
  }

  /// "Suya Lane" for one shop, "2 shops" for several.
  String get title {
    final s = shops;
    if (s.length == 1) return s.single.restaurantName;
    return '${s.length} shops';
  }
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Adds [item] from the given shop; an identical line (same shop, item and choices) adds up its quantity.
  void add(String restaurantId, String restaurantName, CartItem item) {
    final added = item.copyWith(restaurantId: restaurantId, restaurantName: restaurantName);
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.key == added.key);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: (items[idx].quantity + added.quantity).clamp(1, 50));
    } else {
      items.add(added);
    }
    state = CartState(items: items);
  }

  /// Zero or less removes the line.
  void setQuantity(String key, int quantity) {
    state = CartState(items: [
      for (final i in state.items)
        if (i.key != key) i else if (quantity > 0) i.copyWith(quantity: quantity.clamp(1, 50)),
    ]);
  }

  void remove(String key) => setQuantity(key, 0);

  void clear() => state = const CartState();
}

final cartProvider = NotifierProvider<CartController, CartState>(CartController.new);
