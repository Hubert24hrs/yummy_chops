// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GeoPoint _$GeoPointFromJson(Map<String, dynamic> json) => _GeoPoint(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
);

Map<String, dynamic> _$GeoPointToJson(_GeoPoint instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};

_RestaurantCard _$RestaurantCardFromJson(Map<String, dynamic> json) =>
    _RestaurantCard(
      id: json['id'] as String,
      vertical: json['vertical'] as String? ?? 'food',
      city: json['city'] as String? ?? 'lagos',
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      cuisines:
          (json['cuisines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      area: json['area'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      isOpen: json['is_open'] as bool? ?? false,
      isAcceptingOrders: json['is_accepting_orders'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      coverUrl: json['cover_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      deliveryFeeKobo: (json['delivery_fee_kobo'] as num?)?.toInt(),
      deliversToLocation: json['delivers_to_location'] as bool?,
      supportsPickup: json['supports_pickup'] as bool? ?? true,
      supportsDelivery: json['supports_delivery'] as bool? ?? true,
      promotions:
          (json['promotions'] as List<dynamic>?)
              ?.map((e) => PromoBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PromoBadge>[],
      badge: json['badge'] as String?,
    );

Map<String, dynamic> _$RestaurantCardToJson(_RestaurantCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vertical': instance.vertical,
      'city': instance.city,
      'name': instance.name,
      'description': instance.description,
      'cuisines': instance.cuisines,
      'area': instance.area,
      'rating': instance.rating,
      'rating_count': instance.ratingCount,
      'is_open': instance.isOpen,
      'is_accepting_orders': instance.isAcceptingOrders,
      'is_featured': instance.isFeatured,
      'cover_url': ?instance.coverUrl,
      'distance_km': ?instance.distanceKm,
      'eta_minutes': ?instance.etaMinutes,
      'delivery_fee_kobo': ?instance.deliveryFeeKobo,
      'delivers_to_location': ?instance.deliversToLocation,
      'supports_pickup': instance.supportsPickup,
      'supports_delivery': instance.supportsDelivery,
      'promotions': instance.promotions.map((e) => e.toJson()).toList(),
      'badge': ?instance.badge,
    };

_OptionChoice _$OptionChoiceFromJson(Map<String, dynamic> json) =>
    _OptionChoice(
      id: json['id'] as String,
      name: json['name'] as String,
      priceDeltaKobo: (json['price_delta_kobo'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
    );

Map<String, dynamic> _$OptionChoiceToJson(_OptionChoice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price_delta_kobo': instance.priceDeltaKobo,
      'is_available': instance.isAvailable,
    };

_OptionGroup _$OptionGroupFromJson(Map<String, dynamic> json) => _OptionGroup(
  id: json['id'] as String,
  name: json['name'] as String,
  minSelect: (json['min_select'] as num?)?.toInt() ?? 0,
  maxSelect: (json['max_select'] as num?)?.toInt() ?? 1,
  choices:
      (json['choices'] as List<dynamic>?)
          ?.map((e) => OptionChoice.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OptionChoice>[],
);

Map<String, dynamic> _$OptionGroupToJson(_OptionGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'min_select': instance.minSelect,
      'max_select': instance.maxSelect,
      'choices': instance.choices.map((e) => e.toJson()).toList(),
    };

_MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => _MenuItem(
  id: json['id'] as String,
  restaurantId: json['restaurant_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  priceKobo: (json['price_kobo'] as num).toInt(),
  kind: json['kind'] as String? ?? 'main',
  allergens:
      (json['allergens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  dietary:
      (json['dietary'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  serves: (json['serves'] as num?)?.toInt() ?? 1,
  spiceLevel: (json['spice_level'] as num?)?.toInt() ?? 0,
  isAvailable: json['is_available'] as bool? ?? true,
  optionGroupIds:
      (json['option_group_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  unitLabel: json['unit_label'] as String?,
  brand: json['brand'] as String?,
  emoji: json['emoji'] as String?,
  popularity: (json['popularity'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MenuItemToJson(_MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'name': instance.name,
  'description': instance.description,
  'price_kobo': instance.priceKobo,
  'kind': instance.kind,
  'allergens': instance.allergens,
  'dietary': instance.dietary,
  'serves': instance.serves,
  'spice_level': instance.spiceLevel,
  'is_available': instance.isAvailable,
  'option_group_ids': instance.optionGroupIds,
  'unit_label': ?instance.unitLabel,
  'brand': ?instance.brand,
  'emoji': ?instance.emoji,
  'popularity': instance.popularity,
};

_MenuCategory _$MenuCategoryFromJson(Map<String, dynamic> json) =>
    _MenuCategory(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$MenuCategoryToJson(_MenuCategory instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_MenuSection _$MenuSectionFromJson(Map<String, dynamic> json) => _MenuSection(
  category: MenuCategory.fromJson(json['category'] as Map<String, dynamic>),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <MenuItem>[],
);

Map<String, dynamic> _$MenuSectionToJson(_MenuSection instance) =>
    <String, dynamic>{
      'category': instance.category.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

_RestaurantDetail _$RestaurantDetailFromJson(Map<String, dynamic> json) =>
    _RestaurantDetail(
      restaurant: RestaurantCard.fromJson(
        json['restaurant'] as Map<String, dynamic>,
      ),
      address: json['address'] as String? ?? '',
      avgPrepMinutes: (json['avg_prep_minutes'] as num?)?.toInt() ?? 20,
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => MenuSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MenuSection>[],
      optionGroups:
          (json['option_groups'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, OptionGroup.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, OptionGroup>{},
    );

Map<String, dynamic> _$RestaurantDetailToJson(
  _RestaurantDetail instance,
) => <String, dynamic>{
  'restaurant': instance.restaurant.toJson(),
  'address': instance.address,
  'avg_prep_minutes': instance.avgPrepMinutes,
  'sections': instance.sections.map((e) => e.toJson()).toList(),
  'option_groups': instance.optionGroups.map((k, e) => MapEntry(k, e.toJson())),
};

_OptionSelection _$OptionSelectionFromJson(Map<String, dynamic> json) =>
    _OptionSelection(
      groupId: json['group_id'] as String,
      choiceIds:
          (json['choice_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$OptionSelectionToJson(_OptionSelection instance) =>
    <String, dynamic>{
      'group_id': instance.groupId,
      'choice_ids': instance.choiceIds,
    };

_CartLine _$CartLineFromJson(Map<String, dynamic> json) => _CartLine(
  itemId: json['item_id'] as String,
  quantity: (json['quantity'] as num).toInt(),
  selections:
      (json['selections'] as List<dynamic>?)
          ?.map((e) => OptionSelection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OptionSelection>[],
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CartLineToJson(_CartLine instance) => <String, dynamic>{
  'item_id': instance.itemId,
  'quantity': instance.quantity,
  'selections': instance.selections.map((e) => e.toJson()).toList(),
  'notes': ?instance.notes,
};

_DeliveryAddress _$DeliveryAddressFromJson(Map<String, dynamic> json) =>
    _DeliveryAddress(
      label: json['label'] as String?,
      line1: json['line1'] as String,
      area: json['area'] as String?,
      city: json['city'] as String? ?? 'Lagos',
      state: json['state'] as String? ?? 'Lagos',
      location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      instructions: json['instructions'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );

Map<String, dynamic> _$DeliveryAddressToJson(_DeliveryAddress instance) =>
    <String, dynamic>{
      'label': ?instance.label,
      'line1': instance.line1,
      'area': ?instance.area,
      'city': instance.city,
      'state': instance.state,
      'location': instance.location.toJson(),
      'instructions': ?instance.instructions,
      'contact_phone': ?instance.contactPhone,
    };

_PricedLine _$PricedLineFromJson(Map<String, dynamic> json) => _PricedLine(
  itemId: json['item_id'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  lineTotalKobo: (json['line_total_kobo'] as num).toInt(),
  selectionLabels:
      (json['selection_labels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$PricedLineToJson(_PricedLine instance) =>
    <String, dynamic>{
      'item_id': instance.itemId,
      'name': instance.name,
      'quantity': instance.quantity,
      'line_total_kobo': instance.lineTotalKobo,
      'selection_labels': instance.selectionLabels,
    };

_OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => _OrderItem(
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$OrderItemToJson(_OrderItem instance) =>
    <String, dynamic>{'name': instance.name, 'quantity': instance.quantity};

_PriceBreakdown _$PriceBreakdownFromJson(Map<String, dynamic> json) =>
    _PriceBreakdown(
      subtotalKobo: (json['subtotal_kobo'] as num).toInt(),
      deliveryFeeKobo: (json['delivery_fee_kobo'] as num?)?.toInt() ?? 0,
      serviceFeeKobo: (json['service_fee_kobo'] as num?)?.toInt() ?? 0,
      smallOrderFeeKobo: (json['small_order_fee_kobo'] as num?)?.toInt() ?? 0,
      vatKobo: (json['vat_kobo'] as num?)?.toInt() ?? 0,
      discountKobo: (json['discount_kobo'] as num?)?.toInt() ?? 0,
      codFeeKobo: (json['cod_fee_kobo'] as num?)?.toInt() ?? 0,
      linehaulFeeKobo: (json['linehaul_fee_kobo'] as num?)?.toInt() ?? 0,
      pickupFeeKobo: (json['pickup_fee_kobo'] as num?)?.toInt() ?? 0,
      plusSavingsKobo: (json['plus_savings_kobo'] as num?)?.toInt() ?? 0,
      totalKobo: (json['total_kobo'] as num).toInt(),
      voucherCode: json['voucher_code'] as String?,
    );

Map<String, dynamic> _$PriceBreakdownToJson(_PriceBreakdown instance) =>
    <String, dynamic>{
      'subtotal_kobo': instance.subtotalKobo,
      'delivery_fee_kobo': instance.deliveryFeeKobo,
      'service_fee_kobo': instance.serviceFeeKobo,
      'small_order_fee_kobo': instance.smallOrderFeeKobo,
      'vat_kobo': instance.vatKobo,
      'discount_kobo': instance.discountKobo,
      'cod_fee_kobo': instance.codFeeKobo,
      'linehaul_fee_kobo': instance.linehaulFeeKobo,
      'pickup_fee_kobo': instance.pickupFeeKobo,
      'plus_savings_kobo': instance.plusSavingsKobo,
      'total_kobo': instance.totalKobo,
      'voucher_code': ?instance.voucherCode,
    };

_Quote _$QuoteFromJson(Map<String, dynamic> json) => _Quote(
  id: json['id'] as String,
  restaurantName: json['restaurant_name'] as String,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => PricedLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PricedLine>[],
  breakdown: PriceBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
  fulfillment: json['fulfillment'] as String,
  etaMinutes: (json['eta_minutes'] as num).toInt(),
  estimatedDeliveryAt: DateTime.parse(json['estimated_delivery_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$QuoteToJson(_Quote instance) => <String, dynamic>{
  'id': instance.id,
  'restaurant_name': instance.restaurantName,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'breakdown': instance.breakdown.toJson(),
  'fulfillment': instance.fulfillment,
  'eta_minutes': instance.etaMinutes,
  'estimated_delivery_at': instance.estimatedDeliveryAt.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
};

_OrderProgress _$OrderProgressFromJson(Map<String, dynamic> json) =>
    _OrderProgress(
      step: (json['step'] as num).toInt(),
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 5,
      label: json['label'] as String,
      steps:
          (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
    );

Map<String, dynamic> _$OrderProgressToJson(_OrderProgress instance) =>
    <String, dynamic>{
      'step': instance.step,
      'total_steps': instance.totalSteps,
      'label': instance.label,
      'steps': instance.steps,
    };

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: json['id'] as String,
  shortCode: json['short_code'] as String,
  vertical: json['vertical'] as String? ?? 'food',
  status: json['status'] as String,
  restaurantName: json['restaurant_name'] as String,
  fulfillment: json['fulfillment'] as String? ?? 'delivery',
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => PricedLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PricedLine>[],
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OrderItem>[],
  breakdown: json['breakdown'] == null
      ? null
      : PriceBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
  deliveryAddress: json['delivery_address'] == null
      ? null
      : DeliveryAddress.fromJson(
          json['delivery_address'] as Map<String, dynamic>,
        ),
  progress: json['progress'] == null
      ? null
      : OrderProgress.fromJson(json['progress'] as Map<String, dynamic>),
  riderName: json['rider_name'] as String?,
  customerName: json['customer_name'] as String?,
  restaurantAddress: json['restaurant_address'] as String?,
  restaurantLocation: json['restaurant_location'] == null
      ? null
      : GeoPoint.fromJson(json['restaurant_location'] as Map<String, dynamic>),
  estimatedDeliveryAt: json['estimated_delivery_at'] == null
      ? null
      : DateTime.parse(json['estimated_delivery_at'] as String),
  readyAt: json['ready_at'] == null
      ? null
      : DateTime.parse(json['ready_at'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  riderPayKobo: (json['rider_pay_kobo'] as num?)?.toInt(),
  reviewed: json['reviewed'] as bool? ?? false,
  parcel: json['parcel'] == null
      ? null
      : ParcelDetails.fromJson(json['parcel'] as Map<String, dynamic>),
  refundTotalKobo: (json['refund_total_kobo'] as num?)?.toInt() ?? 0,
  payment: json['payment'] == null
      ? const OrderPayment()
      : OrderPayment.fromJson(json['payment'] as Map<String, dynamic>),
  cashCollectedAt: json['cash_collected_at'] == null
      ? null
      : DateTime.parse(json['cash_collected_at'] as String),
  paymentMethod: json['payment_method'] as String?,
  collectCashKobo: (json['collect_cash_kobo'] as num?)?.toInt() ?? 0,
  waybill: json['waybill'] == null
      ? null
      : WaybillDetails.fromJson(json['waybill'] as Map<String, dynamic>),
  legKind: json['leg_kind'] as String?,
  hubHandover: json['hub_handover'] as bool? ?? false,
  groupOrderId: json['group_order_id'] as String?,
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'short_code': instance.shortCode,
  'vertical': instance.vertical,
  'status': instance.status,
  'restaurant_name': instance.restaurantName,
  'fulfillment': instance.fulfillment,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'items': instance.items.map((e) => e.toJson()).toList(),
  'breakdown': ?instance.breakdown?.toJson(),
  'delivery_address': ?instance.deliveryAddress?.toJson(),
  'progress': ?instance.progress?.toJson(),
  'rider_name': ?instance.riderName,
  'customer_name': ?instance.customerName,
  'restaurant_address': ?instance.restaurantAddress,
  'restaurant_location': ?instance.restaurantLocation?.toJson(),
  'estimated_delivery_at': ?instance.estimatedDeliveryAt?.toIso8601String(),
  'ready_at': ?instance.readyAt?.toIso8601String(),
  'created_at': ?instance.createdAt?.toIso8601String(),
  'rider_pay_kobo': ?instance.riderPayKobo,
  'reviewed': instance.reviewed,
  'parcel': ?instance.parcel?.toJson(),
  'refund_total_kobo': instance.refundTotalKobo,
  'payment': instance.payment.toJson(),
  'cash_collected_at': ?instance.cashCollectedAt?.toIso8601String(),
  'payment_method': ?instance.paymentMethod,
  'collect_cash_kobo': instance.collectCashKobo,
  'waybill': ?instance.waybill?.toJson(),
  'leg_kind': ?instance.legKind,
  'hub_handover': instance.hubHandover,
  'group_order_id': ?instance.groupOrderId,
};

_OrderPayment _$OrderPaymentFromJson(Map<String, dynamic> json) =>
    _OrderPayment(
      provider: json['provider'] as String?,
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? 'unpaid',
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
    );

Map<String, dynamic> _$OrderPaymentToJson(_OrderPayment instance) =>
    <String, dynamic>{
      'provider': ?instance.provider,
      'reference': ?instance.reference,
      'status': instance.status,
      'paid_at': ?instance.paidAt?.toIso8601String(),
    };

_CheckoutResult _$CheckoutResultFromJson(Map<String, dynamic> json) =>
    _CheckoutResult(
      orderId: json['order_id'] as String,
      status: json['status'] as String? ?? '',
      reference: json['reference'] as String,
      authorizationUrl: json['authorization_url'] as String?,
      amountKobo: (json['amount_kobo'] as num).toInt(),
      provider: json['provider'] as String,
      failoverFrom: json['failover_from'] as String?,
    );

Map<String, dynamic> _$CheckoutResultToJson(_CheckoutResult instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'status': instance.status,
      'reference': instance.reference,
      'authorization_url': ?instance.authorizationUrl,
      'amount_kobo': instance.amountKobo,
      'provider': instance.provider,
      'failover_from': ?instance.failoverFrom,
    };

_PaymentMethodOption _$PaymentMethodOptionFromJson(Map<String, dynamic> json) =>
    _PaymentMethodOption(
      id: json['id'] as String,
      label: json['label'] as String,
      available: json['available'] as bool? ?? false,
      reason: json['reason'] as String?,
      balanceKobo: (json['balance_kobo'] as num?)?.toInt(),
      shortByKobo: (json['short_by_kobo'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PaymentMethodOptionToJson(
  _PaymentMethodOption instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'available': instance.available,
  'reason': ?instance.reason,
  'balance_kobo': ?instance.balanceKobo,
  'short_by_kobo': ?instance.shortByKobo,
};

_PaymentOptions _$PaymentOptionsFromJson(Map<String, dynamic> json) =>
    _PaymentOptions(
      orderId: json['order_id'] as String,
      totalKobo: (json['total_kobo'] as num).toInt(),
      methods:
          (json['methods'] as List<dynamic>?)
              ?.map(
                (e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <PaymentMethodOption>[],
    );

Map<String, dynamic> _$PaymentOptionsToJson(_PaymentOptions instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'total_kobo': instance.totalKobo,
      'methods': instance.methods.map((e) => e.toJson()).toList(),
    };

_WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    _WalletTransaction(
      id: json['id'] as String,
      kind: json['kind'] as String,
      description: json['description'] as String? ?? '',
      reference: json['reference'] as String?,
      orderId: json['order_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      direction: json['direction'] as String? ?? 'in',
      amountKobo: (json['amount_kobo'] as num).toInt(),
    );

Map<String, dynamic> _$WalletTransactionToJson(_WalletTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'description': instance.description,
      'reference': ?instance.reference,
      'order_id': ?instance.orderId,
      'created_at': instance.createdAt.toIso8601String(),
      'direction': instance.direction,
      'amount_kobo': instance.amountKobo,
    };

_WalletLimits _$WalletLimitsFromJson(Map<String, dynamic> json) =>
    _WalletLimits(
      minTopupKobo: (json['min_topup_kobo'] as num?)?.toInt() ?? 50000,
      maxTopupKobo: (json['max_topup_kobo'] as num?)?.toInt() ?? 10000000,
      maxBalanceKobo: (json['max_balance_kobo'] as num?)?.toInt() ?? 30000000,
    );

Map<String, dynamic> _$WalletLimitsToJson(_WalletLimits instance) =>
    <String, dynamic>{
      'min_topup_kobo': instance.minTopupKobo,
      'max_topup_kobo': instance.maxTopupKobo,
      'max_balance_kobo': instance.maxBalanceKobo,
    };

_SellerSummary _$SellerSummaryFromJson(Map<String, dynamic> json) =>
    _SellerSummary(
      codBalanceKobo: (json['cod_balance_kobo'] as num?)?.toInt() ?? 0,
      pendingPayoutsKobo: (json['pending_payouts_kobo'] as num?)?.toInt() ?? 0,
      availableKobo: (json['available_kobo'] as num?)?.toInt() ?? 0,
      minPayoutKobo: (json['min_payout_kobo'] as num?)?.toInt() ?? 100000,
    );

Map<String, dynamic> _$SellerSummaryToJson(_SellerSummary instance) =>
    <String, dynamic>{
      'cod_balance_kobo': instance.codBalanceKobo,
      'pending_payouts_kobo': instance.pendingPayoutsKobo,
      'available_kobo': instance.availableKobo,
      'min_payout_kobo': instance.minPayoutKobo,
    };

_WalletOverview _$WalletOverviewFromJson(Map<String, dynamic> json) =>
    _WalletOverview(
      balanceKobo: (json['balance_kobo'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      limits: json['limits'] == null
          ? const WalletLimits()
          : WalletLimits.fromJson(json['limits'] as Map<String, dynamic>),
      refundToWallet: json['refund_to_wallet'] as bool? ?? false,
      transactions:
          (json['transactions'] as List<dynamic>?)
              ?.map(
                (e) => WalletTransaction.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <WalletTransaction>[],
      seller: json['seller'] == null
          ? null
          : SellerSummary.fromJson(json['seller'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WalletOverviewToJson(_WalletOverview instance) =>
    <String, dynamic>{
      'balance_kobo': instance.balanceKobo,
      'enabled': instance.enabled,
      'limits': instance.limits.toJson(),
      'refund_to_wallet': instance.refundToWallet,
      'transactions': instance.transactions.map((e) => e.toJson()).toList(),
      'seller': ?instance.seller?.toJson(),
    };

_WaybillParty _$WaybillPartyFromJson(Map<String, dynamic> json) =>
    _WaybillParty(
      name: json['name'] as String,
      phone: json['phone'] as String,
      line1: json['line1'] as String?,
      area: json['area'] as String?,
      location: json['location'] == null
          ? null
          : GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      instructions: json['instructions'] as String?,
    );

Map<String, dynamic> _$WaybillPartyToJson(_WaybillParty instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'line1': ?instance.line1,
      'area': ?instance.area,
      'location': ?instance.location?.toJson(),
      'instructions': ?instance.instructions,
    };

_WaybillDetails _$WaybillDetailsFromJson(Map<String, dynamic> json) =>
    _WaybillDetails(
      trackingCode: json['tracking_code'] as String?,
      originCity: json['origin_city'] as String? ?? '',
      destinationCity: json['destination_city'] as String? ?? '',
      originCityName: json['origin_city_name'] as String? ?? '',
      destinationCityName: json['destination_city_name'] as String? ?? '',
      originHubId: json['origin_hub_id'] as String? ?? '',
      destinationHubId: json['destination_hub_id'] as String? ?? '',
      originHubName: json['origin_hub_name'] as String? ?? '',
      destinationHubName: json['destination_hub_name'] as String? ?? '',
      destinationHubAddress: json['destination_hub_address'] as String? ?? '',
      destinationHubHours: json['destination_hub_hours'] as String? ?? '',
      firstMile: json['first_mile'] as String? ?? 'pickup',
      lastMile: json['last_mile'] as String? ?? 'door',
      sender: WaybillParty.fromJson(json['sender'] as Map<String, dynamic>),
      recipient: WaybillParty.fromJson(
        json['recipient'] as Map<String, dynamic>,
      ),
      size: json['size'] as String? ?? 'small',
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 1,
      category: json['category'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
      codAmountKobo: (json['cod_amount_kobo'] as num?)?.toInt(),
      carrierName: json['carrier_name'] as String? ?? '',
      stage: json['stage'] as String?,
      etaFrom: json['eta_from'] as String?,
      etaTo: json['eta_to'] as String?,
    );

Map<String, dynamic> _$WaybillDetailsToJson(_WaybillDetails instance) =>
    <String, dynamic>{
      'tracking_code': ?instance.trackingCode,
      'origin_city': instance.originCity,
      'destination_city': instance.destinationCity,
      'origin_city_name': instance.originCityName,
      'destination_city_name': instance.destinationCityName,
      'origin_hub_id': instance.originHubId,
      'destination_hub_id': instance.destinationHubId,
      'origin_hub_name': instance.originHubName,
      'destination_hub_name': instance.destinationHubName,
      'destination_hub_address': instance.destinationHubAddress,
      'destination_hub_hours': instance.destinationHubHours,
      'first_mile': instance.firstMile,
      'last_mile': instance.lastMile,
      'sender': instance.sender.toJson(),
      'recipient': instance.recipient.toJson(),
      'size': instance.size,
      'weight_kg': instance.weightKg,
      'category': instance.category,
      'description': instance.description,
      'cod_amount_kobo': ?instance.codAmountKobo,
      'carrier_name': instance.carrierName,
      'stage': ?instance.stage,
      'eta_from': ?instance.etaFrom,
      'eta_to': ?instance.etaTo,
    };

_WaybillQuote _$WaybillQuoteFromJson(Map<String, dynamic> json) =>
    _WaybillQuote(
      id: json['id'] as String,
      details: WaybillDetails.fromJson(json['details'] as Map<String, dynamic>),
      breakdown: PriceBreakdown.fromJson(
        json['breakdown'] as Map<String, dynamic>,
      ),
      etaText: json['eta_text'] as String? ?? '',
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$WaybillQuoteToJson(_WaybillQuote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'details': instance.details.toJson(),
      'breakdown': instance.breakdown.toJson(),
      'eta_text': instance.etaText,
      'expires_at': instance.expiresAt.toIso8601String(),
    };

_WaybillHub _$WaybillHubFromJson(Map<String, dynamic> json) => _WaybillHub(
  id: json['id'] as String,
  name: json['name'] as String,
  city: json['city'] as String,
  address: json['address'] as String? ?? '',
  hours: json['hours'] as String? ?? '',
  isSample: json['is_sample'] as bool? ?? true,
);

Map<String, dynamic> _$WaybillHubToJson(_WaybillHub instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'address': instance.address,
      'hours': instance.hours,
      'is_sample': instance.isSample,
    };

_WaybillOrigin _$WaybillOriginFromJson(Map<String, dynamic> json) =>
    _WaybillOrigin(
      id: json['id'] as String,
      name: json['name'] as String,
      homePickup: json['home_pickup'] as bool? ?? false,
      dropoffHubs:
          (json['dropoff_hubs'] as List<dynamic>?)
              ?.map((e) => WaybillHub.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WaybillHub>[],
    );

Map<String, dynamic> _$WaybillOriginToJson(_WaybillOrigin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'home_pickup': instance.homePickup,
      'dropoff_hubs': instance.dropoffHubs.map((e) => e.toJson()).toList(),
    };

_WaybillDestination _$WaybillDestinationFromJson(Map<String, dynamic> json) =>
    _WaybillDestination(
      city: json['city'] as String,
      name: json['name'] as String,
      doorDelivery: json['door_delivery'] as bool? ?? false,
      transitDays:
          (json['transit_days'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[1, 2],
      fromKobo: (json['from_kobo'] as num?)?.toInt() ?? 0,
      carrier: json['carrier'] as String? ?? '',
      collectionHubs:
          (json['collection_hubs'] as List<dynamic>?)
              ?.map((e) => WaybillHub.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WaybillHub>[],
    );

Map<String, dynamic> _$WaybillDestinationToJson(
  _WaybillDestination instance,
) => <String, dynamic>{
  'city': instance.city,
  'name': instance.name,
  'door_delivery': instance.doorDelivery,
  'transit_days': instance.transitDays,
  'from_kobo': instance.fromKobo,
  'carrier': instance.carrier,
  'collection_hubs': instance.collectionHubs.map((e) => e.toJson()).toList(),
};

_WaybillDestinations _$WaybillDestinationsFromJson(Map<String, dynamic> json) =>
    _WaybillDestinations(
      dropoffHubs:
          (json['dropoff_hubs'] as List<dynamic>?)
              ?.map((e) => WaybillHub.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WaybillHub>[],
      destinations:
          (json['destinations'] as List<dynamic>?)
              ?.map(
                (e) => WaybillDestination.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <WaybillDestination>[],
    );

Map<String, dynamic> _$WaybillDestinationsToJson(
  _WaybillDestinations instance,
) => <String, dynamic>{
  'dropoff_hubs': instance.dropoffHubs.map((e) => e.toJson()).toList(),
  'destinations': instance.destinations.map((e) => e.toJson()).toList(),
};

_WaybillScan _$WaybillScanFromJson(Map<String, dynamic> json) => _WaybillScan(
  stage: json['stage'] as String,
  label: json['label'] as String,
  at: DateTime.parse(json['at'] as String),
  place: json['place'] as String?,
);

Map<String, dynamic> _$WaybillScanToJson(_WaybillScan instance) =>
    <String, dynamic>{
      'stage': instance.stage,
      'label': instance.label,
      'at': instance.at.toIso8601String(),
      'place': ?instance.place,
    };

_WaybillTracking _$WaybillTrackingFromJson(Map<String, dynamic> json) =>
    _WaybillTracking(
      trackingCode: json['tracking_code'] as String,
      origin: json['origin'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      label: json['label'] as String? ?? '',
      step: (json['step'] as num?)?.toInt() ?? 0,
      steps:
          (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      etaText: json['eta_text'] as String? ?? '',
      lastMile: json['last_mile'] as String? ?? 'door',
      milestones:
          (json['milestones'] as List<dynamic>?)
              ?.map((e) => WaybillScan.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WaybillScan>[],
      delivered: json['delivered'] as bool? ?? false,
    );

Map<String, dynamic> _$WaybillTrackingToJson(_WaybillTracking instance) =>
    <String, dynamic>{
      'tracking_code': instance.trackingCode,
      'origin': instance.origin,
      'destination': instance.destination,
      'label': instance.label,
      'step': instance.step,
      'steps': instance.steps,
      'eta_text': instance.etaText,
      'last_mile': instance.lastMile,
      'milestones': instance.milestones.map((e) => e.toJson()).toList(),
      'delivered': instance.delivered,
    };

_PlusPlan _$PlusPlanFromJson(Map<String, dynamic> json) => _PlusPlan(
  enabled: json['enabled'] as bool? ?? true,
  priceKobo: (json['price_kobo'] as num).toInt(),
  vatKobo: (json['vat_kobo'] as num?)?.toInt() ?? 0,
  periodDays: (json['period_days'] as num?)?.toInt() ?? 30,
  freeDeliveryMinSubtotalKobo:
      (json['free_delivery_min_subtotal_kobo'] as num?)?.toInt() ?? 0,
  serviceFeeDiscountBps:
      (json['service_fee_discount_bps'] as num?)?.toInt() ?? 0,
  pointsMultiplier: (json['points_multiplier'] as num?)?.toInt() ?? 1,
  benefits:
      (json['benefits'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$PlusPlanToJson(_PlusPlan instance) => <String, dynamic>{
  'enabled': instance.enabled,
  'price_kobo': instance.priceKobo,
  'vat_kobo': instance.vatKobo,
  'period_days': instance.periodDays,
  'free_delivery_min_subtotal_kobo': instance.freeDeliveryMinSubtotalKobo,
  'service_fee_discount_bps': instance.serviceFeeDiscountBps,
  'points_multiplier': instance.pointsMultiplier,
  'benefits': instance.benefits,
};

_PlusMembership _$PlusMembershipFromJson(Map<String, dynamic> json) =>
    _PlusMembership(
      status: json['status'] as String? ?? 'active',
      paidThrough: DateTime.parse(json['paid_through'] as String),
      paidThroughText: json['paid_through_text'] as String? ?? '',
      daysLeft: (json['days_left'] as num?)?.toInt() ?? 0,
      autoRenew: json['auto_renew'] as bool? ?? true,
      canRenew: json['can_renew'] as bool? ?? false,
      periods: (json['periods'] as num?)?.toInt() ?? 0,
      savingsKobo: (json['savings_kobo'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PlusMembershipToJson(_PlusMembership instance) =>
    <String, dynamic>{
      'status': instance.status,
      'paid_through': instance.paidThrough.toIso8601String(),
      'paid_through_text': instance.paidThroughText,
      'days_left': instance.daysLeft,
      'auto_renew': instance.autoRenew,
      'can_renew': instance.canRenew,
      'periods': instance.periods,
      'savings_kobo': instance.savingsKobo,
    };

_PlusOverview _$PlusOverviewFromJson(Map<String, dynamic> json) =>
    _PlusOverview(
      plan: PlusPlan.fromJson(json['plan'] as Map<String, dynamic>),
      member: json['member'] as bool? ?? false,
      membership: json['membership'] == null
          ? null
          : PlusMembership.fromJson(json['membership'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlusOverviewToJson(_PlusOverview instance) =>
    <String, dynamic>{
      'plan': instance.plan.toJson(),
      'member': instance.member,
      'membership': ?instance.membership?.toJson(),
    };

_RewardVoucher _$RewardVoucherFromJson(Map<String, dynamic> json) =>
    _RewardVoucher(
      code: json['code'] as String,
      description: json['description'] as String? ?? '',
      valueKobo: (json['value_kobo'] as num).toInt(),
      minSubtotalKobo: (json['min_subtotal_kobo'] as num?)?.toInt() ?? 0,
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.parse(json['ends_at'] as String),
      source: json['source'] as String? ?? 'points',
    );

Map<String, dynamic> _$RewardVoucherToJson(_RewardVoucher instance) =>
    <String, dynamic>{
      'code': instance.code,
      'description': instance.description,
      'value_kobo': instance.valueKobo,
      'min_subtotal_kobo': instance.minSubtotalKobo,
      'ends_at': ?instance.endsAt?.toIso8601String(),
      'source': instance.source,
    };

_PointsEntry _$PointsEntryFromJson(Map<String, dynamic> json) => _PointsEntry(
  id: json['id'] as String,
  kind: json['kind'] as String,
  points: (json['points'] as num).toInt(),
  orderId: json['order_id'] as String?,
  voucherCode: json['voucher_code'] as String?,
  note: json['note'] as String? ?? '',
  at: DateTime.parse(json['at'] as String),
);

Map<String, dynamic> _$PointsEntryToJson(_PointsEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'points': instance.points,
      'order_id': ?instance.orderId,
      'voucher_code': ?instance.voucherCode,
      'note': instance.note,
      'at': instance.at.toIso8601String(),
    };

_RewardsRedeem _$RewardsRedeemFromJson(Map<String, dynamic> json) =>
    _RewardsRedeem(
      enabled: json['enabled'] as bool? ?? true,
      stepPoints: (json['step_points'] as num?)?.toInt() ?? 500,
      stepValueKobo: (json['step_value_kobo'] as num?)?.toInt() ?? 50000,
      redeemablePoints: (json['redeemable_points'] as num?)?.toInt() ?? 0,
      pointsToNext: (json['points_to_next'] as num?)?.toInt() ?? 0,
      minSubtotalKobo: (json['min_subtotal_kobo'] as num?)?.toInt() ?? 0,
      validDays: (json['valid_days'] as num?)?.toInt() ?? 90,
    );

Map<String, dynamic> _$RewardsRedeemToJson(_RewardsRedeem instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'step_points': instance.stepPoints,
      'step_value_kobo': instance.stepValueKobo,
      'redeemable_points': instance.redeemablePoints,
      'points_to_next': instance.pointsToNext,
      'min_subtotal_kobo': instance.minSubtotalKobo,
      'valid_days': instance.validDays,
    };

_RewardsReferral _$RewardsReferralFromJson(Map<String, dynamic> json) =>
    _RewardsReferral(
      enabled: json['enabled'] as bool? ?? true,
      code: json['code'] as String? ?? '',
      friendGetsKobo: (json['friend_gets_kobo'] as num?)?.toInt() ?? 0,
      youGetKobo: (json['you_get_kobo'] as num?)?.toInt() ?? 0,
      minSubtotalKobo: (json['min_subtotal_kobo'] as num?)?.toInt() ?? 0,
      friendsRewarded: (json['friends_rewarded'] as num?)?.toInt() ?? 0,
      applied: json['applied'] as bool? ?? false,
      canApply: json['can_apply'] as bool? ?? false,
      shareText: json['share_text'] as String? ?? '',
    );

Map<String, dynamic> _$RewardsReferralToJson(_RewardsReferral instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'code': instance.code,
      'friend_gets_kobo': instance.friendGetsKobo,
      'you_get_kobo': instance.youGetKobo,
      'min_subtotal_kobo': instance.minSubtotalKobo,
      'friends_rewarded': instance.friendsRewarded,
      'applied': instance.applied,
      'can_apply': instance.canApply,
      'share_text': instance.shareText,
    };

_RewardsOverview _$RewardsOverviewFromJson(Map<String, dynamic> json) =>
    _RewardsOverview(
      points: (json['points'] as num?)?.toInt() ?? 0,
      lifetimePoints: (json['lifetime_points'] as num?)?.toInt() ?? 0,
      pointsValueKobo: (json['points_value_kobo'] as num?)?.toInt() ?? 0,
      redeem: RewardsRedeem.fromJson(json['redeem'] as Map<String, dynamic>),
      referral: RewardsReferral.fromJson(
        json['referral'] as Map<String, dynamic>,
      ),
      vouchers:
          (json['vouchers'] as List<dynamic>?)
              ?.map((e) => RewardVoucher.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RewardVoucher>[],
      history:
          (json['history'] as List<dynamic>?)
              ?.map((e) => PointsEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PointsEntry>[],
    );

Map<String, dynamic> _$RewardsOverviewToJson(_RewardsOverview instance) =>
    <String, dynamic>{
      'points': instance.points,
      'lifetime_points': instance.lifetimePoints,
      'points_value_kobo': instance.pointsValueKobo,
      'redeem': instance.redeem.toJson(),
      'referral': instance.referral.toJson(),
      'vouchers': instance.vouchers.map((e) => e.toJson()).toList(),
      'history': instance.history.map((e) => e.toJson()).toList(),
    };

_GroupMemberView _$GroupMemberViewFromJson(Map<String, dynamic> json) =>
    _GroupMemberView(
      uid: json['uid'] as String,
      name: json['name'] as String,
      isHost: json['is_host'] as bool? ?? false,
      me: json['me'] as bool? ?? false,
      ready: json['ready'] as bool? ?? false,
      items: (json['items'] as num?)?.toInt() ?? 0,
      itemsKobo: (json['items_kobo'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$GroupMemberViewToJson(_GroupMemberView instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'is_host': instance.isHost,
      'me': instance.me,
      'ready': instance.ready,
      'items': instance.items,
      'items_kobo': instance.itemsKobo,
    };

_GroupLineView _$GroupLineViewFromJson(Map<String, dynamic> json) =>
    _GroupLineView(
      id: json['id'] as String,
      memberUid: json['member_uid'] as String,
      member: json['member'] as String? ?? '',
      itemId: json['item_id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      selections:
          (json['selections'] as List<dynamic>?)
              ?.map((e) => OptionSelection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OptionSelection>[],
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      notes: json['notes'] as String?,
      lineTotalKobo: (json['line_total_kobo'] as num?)?.toInt() ?? 0,
      problem: json['problem'] as String?,
    );

Map<String, dynamic> _$GroupLineViewToJson(_GroupLineView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'member_uid': instance.memberUid,
      'member': instance.member,
      'item_id': instance.itemId,
      'name': instance.name,
      'quantity': instance.quantity,
      'selections': instance.selections.map((e) => e.toJson()).toList(),
      'options': instance.options,
      'notes': ?instance.notes,
      'line_total_kobo': instance.lineTotalKobo,
      'problem': ?instance.problem,
    };

_GroupShareView _$GroupShareViewFromJson(Map<String, dynamic> json) =>
    _GroupShareView(
      uid: json['uid'] as String,
      name: json['name'] as String,
      me: json['me'] as bool? ?? false,
      itemsKobo: (json['items_kobo'] as num?)?.toInt() ?? 0,
      amountKobo: (json['amount_kobo'] as num).toInt(),
      status: json['status'] as String? ?? 'unpaid',
      paidByHost: json['paid_by_host'] as bool? ?? false,
    );

Map<String, dynamic> _$GroupShareViewToJson(_GroupShareView instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'me': instance.me,
      'items_kobo': instance.itemsKobo,
      'amount_kobo': instance.amountKobo,
      'status': instance.status,
      'paid_by_host': instance.paidByHost,
    };

_GroupOrderRef _$GroupOrderRefFromJson(Map<String, dynamic> json) =>
    _GroupOrderRef(
      id: json['id'] as String,
      shortCode: json['short_code'] as String? ?? '',
      status: json['status'] as String,
      totalKobo: (json['total_kobo'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$GroupOrderRefToJson(_GroupOrderRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'short_code': instance.shortCode,
      'status': instance.status,
      'total_kobo': instance.totalKobo,
    };

_GroupMyShare _$GroupMyShareFromJson(Map<String, dynamic> json) =>
    _GroupMyShare(
      amountKobo: (json['amount_kobo'] as num).toInt(),
      itemsKobo: (json['items_kobo'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'unpaid',
    );

Map<String, dynamic> _$GroupMyShareToJson(_GroupMyShare instance) =>
    <String, dynamic>{
      'amount_kobo': instance.amountKobo,
      'items_kobo': instance.itemsKobo,
      'status': instance.status,
    };

_GroupRestaurant _$GroupRestaurantFromJson(Map<String, dynamic> json) =>
    _GroupRestaurant(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$GroupRestaurantToJson(_GroupRestaurant instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_GroupOrder _$GroupOrderFromJson(Map<String, dynamic> json) => _GroupOrder(
  id: json['id'] as String,
  code: json['code'] as String,
  status: json['status'] as String,
  splitMode: json['split_mode'] as String? ?? 'each',
  isHost: json['is_host'] as bool? ?? false,
  hostName: json['host_name'] as String? ?? '',
  restaurant: GroupRestaurant.fromJson(
    json['restaurant'] as Map<String, dynamic>,
  ),
  fulfillment: json['fulfillment'] as String? ?? 'delivery',
  deliveryArea: json['delivery_area'] as String?,
  members:
      (json['members'] as List<dynamic>?)
          ?.map((e) => GroupMemberView.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GroupMemberView>[],
  maxMembers: (json['max_members'] as num?)?.toInt() ?? 10,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => GroupLineView.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GroupLineView>[],
  estimatedItemsKobo: (json['estimated_items_kobo'] as num?)?.toInt() ?? 0,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  order: json['order'] == null
      ? null
      : GroupOrderRef.fromJson(json['order'] as Map<String, dynamic>),
  totalKobo: (json['total_kobo'] as num?)?.toInt() ?? 0,
  shares:
      (json['shares'] as List<dynamic>?)
          ?.map((e) => GroupShareView.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GroupShareView>[],
  myShare: json['my_share'] == null
      ? null
      : GroupMyShare.fromJson(json['my_share'] as Map<String, dynamic>),
  paidKobo: (json['paid_kobo'] as num?)?.toInt() ?? 0,
  remainingKobo: (json['remaining_kobo'] as num?)?.toInt() ?? 0,
  payBy: json['pay_by'] == null
      ? null
      : DateTime.parse(json['pay_by'] as String),
  canPay: json['can_pay'] as bool? ?? false,
  canCoverRest: json['can_cover_rest'] as bool? ?? false,
  cancelReason: json['cancel_reason'] as String?,
);

Map<String, dynamic> _$GroupOrderToJson(_GroupOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'status': instance.status,
      'split_mode': instance.splitMode,
      'is_host': instance.isHost,
      'host_name': instance.hostName,
      'restaurant': instance.restaurant.toJson(),
      'fulfillment': instance.fulfillment,
      'delivery_area': ?instance.deliveryArea,
      'members': instance.members.map((e) => e.toJson()).toList(),
      'max_members': instance.maxMembers,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'estimated_items_kobo': instance.estimatedItemsKobo,
      'expires_at': ?instance.expiresAt?.toIso8601String(),
      'order': ?instance.order?.toJson(),
      'total_kobo': instance.totalKobo,
      'shares': instance.shares.map((e) => e.toJson()).toList(),
      'my_share': ?instance.myShare?.toJson(),
      'paid_kobo': instance.paidKobo,
      'remaining_kobo': instance.remainingKobo,
      'pay_by': ?instance.payBy?.toIso8601String(),
      'can_pay': instance.canPay,
      'can_cover_rest': instance.canCoverRest,
      'cancel_reason': ?instance.cancelReason,
    };

_WhatsAppStatus _$WhatsAppStatusFromJson(Map<String, dynamic> json) =>
    _WhatsAppStatus(
      enabled: json['enabled'] as bool? ?? false,
      linked: json['linked'] as bool? ?? false,
      number: json['number'] as String?,
      linkedAt: json['linked_at'] == null
          ? null
          : DateTime.parse(json['linked_at'] as String),
      businessNumber: json['business_number'] as String? ?? '',
      chatLink: json['chat_link'] as String?,
    );

Map<String, dynamic> _$WhatsAppStatusToJson(_WhatsAppStatus instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'linked': instance.linked,
      'number': ?instance.number,
      'linked_at': ?instance.linkedAt?.toIso8601String(),
      'business_number': instance.businessNumber,
      'chat_link': ?instance.chatLink,
    };

_WhatsAppLinkCode _$WhatsAppLinkCodeFromJson(Map<String, dynamic> json) =>
    _WhatsAppLinkCode(
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      businessNumber: json['business_number'] as String? ?? '',
      waLink: json['wa_link'] as String,
    );

Map<String, dynamic> _$WhatsAppLinkCodeToJson(_WhatsAppLinkCode instance) =>
    <String, dynamic>{
      'code': instance.code,
      'expires_at': instance.expiresAt.toIso8601String(),
      'business_number': instance.businessNumber,
      'wa_link': instance.waLink,
    };

_TopUpResult _$TopUpResultFromJson(Map<String, dynamic> json) => _TopUpResult(
  reference: json['reference'] as String,
  provider: json['provider'] as String,
  authorizationUrl: json['authorization_url'] as String?,
  amountKobo: (json['amount_kobo'] as num).toInt(),
);

Map<String, dynamic> _$TopUpResultToJson(_TopUpResult instance) =>
    <String, dynamic>{
      'reference': instance.reference,
      'provider': instance.provider,
      'authorization_url': ?instance.authorizationUrl,
      'amount_kobo': instance.amountKobo,
    };

_Tracking _$TrackingFromJson(Map<String, dynamic> json) => _Tracking(
  status: json['status'] as String,
  riderName: json['rider_name'] as String?,
  riderLocation: json['rider_location'] == null
      ? null
      : GeoPoint.fromJson(json['rider_location'] as Map<String, dynamic>),
  etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
  estimatedDeliveryAt: json['estimated_delivery_at'] == null
      ? null
      : DateTime.parse(json['estimated_delivery_at'] as String),
);

Map<String, dynamic> _$TrackingToJson(_Tracking instance) => <String, dynamic>{
  'status': instance.status,
  'rider_name': ?instance.riderName,
  'rider_location': ?instance.riderLocation?.toJson(),
  'eta_minutes': ?instance.etaMinutes,
  'estimated_delivery_at': ?instance.estimatedDeliveryAt?.toIso8601String(),
};

_DeliveryOffer _$DeliveryOfferFromJson(Map<String, dynamic> json) =>
    _DeliveryOffer(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      restaurantName: json['restaurant_name'] as String,
      distanceToRestaurantKm: (json['distance_to_restaurant_km'] as num)
          .toDouble(),
      payoutKobo: (json['payout_kobo'] as num).toInt(),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      pickup: GeoPoint.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: json['dropoff'] == null
          ? null
          : GeoPoint.fromJson(json['dropoff'] as Map<String, dynamic>),
      dropoffArea: json['dropoff_area'] as String?,
    );

Map<String, dynamic> _$DeliveryOfferToJson(_DeliveryOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'restaurant_name': instance.restaurantName,
      'distance_to_restaurant_km': instance.distanceToRestaurantKm,
      'payout_kobo': instance.payoutKobo,
      'expires_at': instance.expiresAt.toIso8601String(),
      'pickup': instance.pickup.toJson(),
      'dropoff': ?instance.dropoff?.toJson(),
      'dropoff_area': ?instance.dropoffArea,
    };

_RiderProfile _$RiderProfileFromJson(Map<String, dynamic> json) =>
    _RiderProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      vehicle: json['vehicle'] as String? ?? 'motorcycle',
      status: json['status'] as String? ?? 'pending',
      isOnline: json['is_online'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 5,
      activeOrderIds:
          (json['active_order_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      completedDeliveries: (json['completed_deliveries'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$RiderProfileToJson(_RiderProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'vehicle': instance.vehicle,
      'status': instance.status,
      'is_online': instance.isOnline,
      'rating': instance.rating,
      'active_order_ids': instance.activeOrderIds,
      'completed_deliveries': instance.completedDeliveries,
    };

_Earnings _$EarningsFromJson(Map<String, dynamic> json) => _Earnings(
  balanceKobo: (json['balance_kobo'] as num).toInt(),
  pendingPayoutsKobo: (json['pending_payouts_kobo'] as num).toInt(),
  availableKobo: (json['available_kobo'] as num).toInt(),
  deliveriesCompleted: (json['deliveries_completed'] as num).toInt(),
  earnedLast7DaysKobo: (json['earned_last_7_days_kobo'] as num).toInt(),
  cashHeldKobo: (json['cash_held_kobo'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$EarningsToJson(_Earnings instance) => <String, dynamic>{
  'balance_kobo': instance.balanceKobo,
  'pending_payouts_kobo': instance.pendingPayoutsKobo,
  'available_kobo': instance.availableKobo,
  'deliveries_completed': instance.deliveriesCompleted,
  'earned_last_7_days_kobo': instance.earnedLast7DaysKobo,
  'cash_held_kobo': instance.cashHeldKobo,
};

_ChatApproval _$ChatApprovalFromJson(Map<String, dynamic> json) =>
    _ChatApproval(
      tool: json['tool'] as String,
      toolCallId: json['tool_call_id'] as String,
      preview:
          json['preview'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$ChatApprovalToJson(_ChatApproval instance) =>
    <String, dynamic>{
      'tool': instance.tool,
      'tool_call_id': instance.toolCallId,
      'preview': instance.preview,
    };

_ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) =>
    _ChatResponse(
      threadId: json['thread_id'] as String,
      status: json['status'] as String,
      reply: json['reply'] as String?,
      agent: json['agent'] as String?,
      cards:
          (json['cards'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const <Map<String, dynamic>>[],
      approval: json['approval'] == null
          ? null
          : ChatApproval.fromJson(json['approval'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatResponseToJson(_ChatResponse instance) =>
    <String, dynamic>{
      'thread_id': instance.threadId,
      'status': instance.status,
      'reply': ?instance.reply,
      'agent': ?instance.agent,
      'cards': instance.cards,
      'approval': ?instance.approval?.toJson(),
    };

_PromoBadge _$PromoBadgeFromJson(Map<String, dynamic> json) =>
    _PromoBadge(code: json['code'] as String, label: json['label'] as String);

Map<String, dynamic> _$PromoBadgeToJson(_PromoBadge instance) =>
    <String, dynamic>{'code': instance.code, 'label': instance.label};

_ServiceInfo _$ServiceInfoFromJson(Map<String, dynamic> json) => _ServiceInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  tagline: json['tagline'] as String? ?? '',
  available: json['available'] as bool? ?? true,
  merchants: (json['merchants'] as num?)?.toInt(),
  options:
      (json['options'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  comingSoon:
      (json['coming_soon'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  cities:
      (json['cities'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$ServiceInfoToJson(_ServiceInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tagline': instance.tagline,
      'available': instance.available,
      'merchants': ?instance.merchants,
      'options': instance.options,
      'coming_soon': instance.comingSoon,
      'cities': instance.cities,
    };

_BrowseCategory _$BrowseCategoryFromJson(Map<String, dynamic> json) =>
    _BrowseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '',
      merchants: (json['merchants'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BrowseCategoryToJson(_BrowseCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'emoji': instance.emoji,
      'merchants': instance.merchants,
    };

_PlaceArea _$PlaceAreaFromJson(Map<String, dynamic> json) => _PlaceArea(
  name: json['name'] as String,
  city: json['city'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
);

Map<String, dynamic> _$PlaceAreaToJson(_PlaceArea instance) =>
    <String, dynamic>{
      'name': instance.name,
      'city': instance.city,
      'lat': instance.lat,
      'lng': instance.lng,
    };

_ParcelStop _$ParcelStopFromJson(Map<String, dynamic> json) => _ParcelStop(
  name: json['name'] as String,
  phone: json['phone'] as String,
  line1: json['line1'] as String,
  area: json['area'] as String?,
  city: json['city'] as String? ?? 'Lagos',
  location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
  instructions: json['instructions'] as String?,
);

Map<String, dynamic> _$ParcelStopToJson(_ParcelStop instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'line1': instance.line1,
      'area': ?instance.area,
      'city': instance.city,
      'location': instance.location.toJson(),
      'instructions': ?instance.instructions,
    };

_ParcelDetails _$ParcelDetailsFromJson(Map<String, dynamic> json) =>
    _ParcelDetails(
      pickup: ParcelStop.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: ParcelStop.fromJson(json['dropoff'] as Map<String, dynamic>),
      size: json['size'] as String? ?? 'small',
      category: json['category'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? 'lagos',
      codAmountKobo: (json['cod_amount_kobo'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ParcelDetailsToJson(_ParcelDetails instance) =>
    <String, dynamic>{
      'pickup': instance.pickup.toJson(),
      'dropoff': instance.dropoff.toJson(),
      'size': instance.size,
      'category': instance.category,
      'description': instance.description,
      'city': instance.city,
      'cod_amount_kobo': ?instance.codAmountKobo,
    };

_ParcelQuote _$ParcelQuoteFromJson(Map<String, dynamic> json) => _ParcelQuote(
  id: json['id'] as String,
  details: ParcelDetails.fromJson(json['details'] as Map<String, dynamic>),
  breakdown: PriceBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
  distanceKm: (json['distance_km'] as num).toDouble(),
  etaMinutes: (json['eta_minutes'] as num).toInt(),
  estimatedDeliveryAt: DateTime.parse(json['estimated_delivery_at'] as String),
  scheduledFor: json['scheduled_for'] == null
      ? null
      : DateTime.parse(json['scheduled_for'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$ParcelQuoteToJson(_ParcelQuote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'details': instance.details.toJson(),
      'breakdown': instance.breakdown.toJson(),
      'distance_km': instance.distanceKm,
      'eta_minutes': instance.etaMinutes,
      'estimated_delivery_at': instance.estimatedDeliveryAt.toIso8601String(),
      'scheduled_for': ?instance.scheduledFor?.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
    };

_VerticalSpend _$VerticalSpendFromJson(Map<String, dynamic> json) =>
    _VerticalSpend(
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      spentKobo: (json['spent_kobo'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VerticalSpendToJson(_VerticalSpend instance) =>
    <String, dynamic>{
      'orders': instance.orders,
      'spent_kobo': instance.spentKobo,
    };

_FavouriteMerchant _$FavouriteMerchantFromJson(Map<String, dynamic> json) =>
    _FavouriteMerchant(
      id: json['id'] as String,
      name: json['name'] as String,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FavouriteMerchantToJson(_FavouriteMerchant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'orders': instance.orders,
    };

_OrderSummary _$OrderSummaryFromJson(Map<String, dynamic> json) =>
    _OrderSummary(
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      inProgressCount: (json['in_progress_count'] as num?)?.toInt() ?? 0,
      totalSpentKobo: (json['total_spent_kobo'] as num?)?.toInt() ?? 0,
      thisMonthSpentKobo: (json['this_month_spent_kobo'] as num?)?.toInt() ?? 0,
      refundedKobo: (json['refunded_kobo'] as num?)?.toInt() ?? 0,
      byVertical:
          (json['by_vertical'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, VerticalSpend.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, VerticalSpend>{},
      favouriteMerchant: json['favourite_merchant'] == null
          ? null
          : FavouriteMerchant.fromJson(
              json['favourite_merchant'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$OrderSummaryToJson(_OrderSummary instance) =>
    <String, dynamic>{
      'orders_count': instance.ordersCount,
      'completed_count': instance.completedCount,
      'in_progress_count': instance.inProgressCount,
      'total_spent_kobo': instance.totalSpentKobo,
      'this_month_spent_kobo': instance.thisMonthSpentKobo,
      'refunded_kobo': instance.refundedKobo,
      'by_vertical': instance.byVertical.map((k, e) => MapEntry(k, e.toJson())),
      'favourite_merchant': ?instance.favouriteMerchant?.toJson(),
    };

_SupportContacts _$SupportContactsFromJson(Map<String, dynamic> json) =>
    _SupportContacts(
      whatsapp: json['whatsapp'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      placeholders: json['placeholders'] as bool? ?? true,
    );

Map<String, dynamic> _$SupportContactsToJson(_SupportContacts instance) =>
    <String, dynamic>{
      'whatsapp': instance.whatsapp,
      'phone': instance.phone,
      'email': instance.email,
      'hours': instance.hours,
      'placeholders': instance.placeholders,
    };

_ReceiptLine _$ReceiptLineFromJson(Map<String, dynamic> json) => _ReceiptLine(
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  amountKobo: (json['amount_kobo'] as num?)?.toInt() ?? 0,
  details:
      (json['details'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ReceiptLineToJson(_ReceiptLine instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'amount_kobo': instance.amountKobo,
      'details': instance.details,
    };

_ReceiptCharge _$ReceiptChargeFromJson(Map<String, dynamic> json) =>
    _ReceiptCharge(
      label: json['label'] as String,
      amountKobo: (json['amount_kobo'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReceiptChargeToJson(_ReceiptCharge instance) =>
    <String, dynamic>{
      'label': instance.label,
      'amount_kobo': instance.amountKobo,
    };

_Receipt _$ReceiptFromJson(Map<String, dynamic> json) => _Receipt(
  id: json['id'] as String,
  number: json['number'] as String,
  orderId: json['order_id'] as String,
  orderCode: json['order_code'] as String? ?? '',
  customerName: json['customer_name'] as String?,
  service: json['service'] as String? ?? 'food',
  serviceName: json['service_name'] as String? ?? '',
  seller: json['seller'] as String? ?? '',
  sellerAddress: json['seller_address'] as String? ?? '',
  summary:
      (json['summary'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => ReceiptLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  charges:
      (json['charges'] as List<dynamic>?)
          ?.map((e) => ReceiptCharge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalKobo: (json['total_kobo'] as num?)?.toInt() ?? 0,
  savingsKobo: (json['savings_kobo'] as num?)?.toInt() ?? 0,
  refundedKobo: (json['refunded_kobo'] as num?)?.toInt() ?? 0,
  paidWith: json['paid_with'] as String? ?? '',
  paymentReference: json['payment_reference'] as String?,
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
  orderedAt: json['ordered_at'] == null
      ? null
      : DateTime.parse(json['ordered_at'] as String),
  issuedAt: json['issued_at'] == null
      ? null
      : DateTime.parse(json['issued_at'] as String),
  printedAt: json['printed_at'] == null
      ? null
      : DateTime.parse(json['printed_at'] as String),
  printCount: (json['print_count'] as num?)?.toInt() ?? 0,
  saved: json['saved'] as bool? ?? false,
);

Map<String, dynamic> _$ReceiptToJson(_Receipt instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'order_id': instance.orderId,
  'order_code': instance.orderCode,
  'customer_name': ?instance.customerName,
  'service': instance.service,
  'service_name': instance.serviceName,
  'seller': instance.seller,
  'seller_address': instance.sellerAddress,
  'summary': instance.summary,
  'lines': instance.lines.map((e) => e.toJson()).toList(),
  'charges': instance.charges.map((e) => e.toJson()).toList(),
  'total_kobo': instance.totalKobo,
  'savings_kobo': instance.savingsKobo,
  'refunded_kobo': instance.refundedKobo,
  'paid_with': instance.paidWith,
  'payment_reference': ?instance.paymentReference,
  'paid_at': ?instance.paidAt?.toIso8601String(),
  'ordered_at': ?instance.orderedAt?.toIso8601String(),
  'issued_at': ?instance.issuedAt?.toIso8601String(),
  'printed_at': ?instance.printedAt?.toIso8601String(),
  'print_count': instance.printCount,
  'saved': instance.saved,
};
