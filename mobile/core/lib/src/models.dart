// Yummy Chops API models (mirrors services/api JSON). All money values are integer kobo.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint({required double lat, required double lng}) = _GeoPoint;
  factory GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);
}

@freezed
abstract class RestaurantCard with _$RestaurantCard {
  const factory RestaurantCard({
    required String id,
    @Default('food') String vertical,
    @Default('lagos') String city,
    required String name,
    @Default('') String description,
    @Default(<String>[]) List<String> cuisines,
    @Default('') String area,
    @Default(0) double rating,
    @Default(0) int ratingCount,
    @Default(false) bool isOpen,
    @Default(true) bool isAcceptingOrders,
    @Default(false) bool isFeatured,
    String? coverUrl,
    double? distanceKm,
    int? etaMinutes,
    int? deliveryFeeKobo,
    bool? deliversToLocation,
    @Default(true) bool supportsPickup,
    @Default(true) bool supportsDelivery,
    @Default(<PromoBadge>[]) List<PromoBadge> promotions,
    /// e.g. "Shopper" on a market: someone buys the items for the customer.
    String? badge,
  }) = _RestaurantCard;
  factory RestaurantCard.fromJson(Map<String, dynamic> json) => _$RestaurantCardFromJson(json);
}

@freezed
abstract class OptionChoice with _$OptionChoice {
  const factory OptionChoice({
    required String id,
    required String name,
    @Default(0) int priceDeltaKobo,
    @Default(true) bool isAvailable,
  }) = _OptionChoice;
  factory OptionChoice.fromJson(Map<String, dynamic> json) => _$OptionChoiceFromJson(json);
}

@freezed
abstract class OptionGroup with _$OptionGroup {
  const factory OptionGroup({
    required String id,
    required String name,
    @Default(0) int minSelect,
    @Default(1) int maxSelect,
    @Default(<OptionChoice>[]) List<OptionChoice> choices,
  }) = _OptionGroup;
  factory OptionGroup.fromJson(Map<String, dynamic> json) => _$OptionGroupFromJson(json);
}

@freezed
abstract class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    required String restaurantId,
    required String name,
    @Default('') String description,
    required int priceKobo,
    @Default('main') String kind,
    @Default(<String>[]) List<String> allergens,
    @Default(<String>[]) List<String> dietary,
    @Default(1) int serves,
    @Default(0) int spiceLevel,
    @Default(true) bool isAvailable,
    @Default(<String>[]) List<String> optionGroupIds,
    String? unitLabel,
    /// Products (shops, pharmacies, markets): brand, a picture placeholder and how popular the product is.
    String? brand,
    String? emoji,
    @Default(0) int popularity,
  }) = _MenuItem;
  factory MenuItem.fromJson(Map<String, dynamic> json) => _$MenuItemFromJson(json);
}

@freezed
abstract class MenuCategory with _$MenuCategory {
  const factory MenuCategory({required String id, required String name}) = _MenuCategory;
  factory MenuCategory.fromJson(Map<String, dynamic> json) => _$MenuCategoryFromJson(json);
}

@freezed
abstract class MenuSection with _$MenuSection {
  const factory MenuSection({required MenuCategory category, @Default(<MenuItem>[]) List<MenuItem> items}) = _MenuSection;
  factory MenuSection.fromJson(Map<String, dynamic> json) => _$MenuSectionFromJson(json);
}

@freezed
abstract class RestaurantDetail with _$RestaurantDetail {
  const factory RestaurantDetail({
    required RestaurantCard restaurant,
    @Default('') String address,
    @Default(20) int avgPrepMinutes,
    @Default(<MenuSection>[]) List<MenuSection> sections,
    @Default(<String, OptionGroup>{}) Map<String, OptionGroup> optionGroups,
  }) = _RestaurantDetail;
  factory RestaurantDetail.fromJson(Map<String, dynamic> json) => _$RestaurantDetailFromJson(json);
}

@freezed
abstract class OptionSelection with _$OptionSelection {
  const factory OptionSelection({required String groupId, @Default(<String>[]) List<String> choiceIds}) = _OptionSelection;
  factory OptionSelection.fromJson(Map<String, dynamic> json) => _$OptionSelectionFromJson(json);
}

@freezed
abstract class CartLine with _$CartLine {
  const factory CartLine({
    required String itemId,
    required int quantity,
    @Default(<OptionSelection>[]) List<OptionSelection> selections,
    String? notes,
  }) = _CartLine;
  factory CartLine.fromJson(Map<String, dynamic> json) => _$CartLineFromJson(json);
}

@freezed
abstract class DeliveryAddress with _$DeliveryAddress {
  const factory DeliveryAddress({
    String? label,
    required String line1,
    String? area,
    @Default('Lagos') String city,
    @Default('Lagos') String state,
    required GeoPoint location,
    String? instructions,
    String? contactPhone,
  }) = _DeliveryAddress;
  factory DeliveryAddress.fromJson(Map<String, dynamic> json) => _$DeliveryAddressFromJson(json);
}

@freezed
abstract class PricedLine with _$PricedLine {
  const factory PricedLine({
    required String itemId,
    required String name,
    required int quantity,
    required int lineTotalKobo,
    @Default(<String>[]) List<String> selectionLabels,
  }) = _PricedLine;
  factory PricedLine.fromJson(Map<String, dynamic> json) => _$PricedLineFromJson(json);
}

/// An item a rider collects: name and quantity only.
@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({required String name, @Default(1) int quantity}) = _OrderItem;
  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
}

@freezed
abstract class PriceBreakdown with _$PriceBreakdown {
  const factory PriceBreakdown({
    required int subtotalKobo,
    @Default(0) int deliveryFeeKobo,
    @Default(0) int serviceFeeKobo,
    @Default(0) int smallOrderFeeKobo,
    @Default(0) int vatKobo,
    @Default(0) int discountKobo,
    @Default(0) int codFeeKobo,
    @Default(0) int linehaulFeeKobo,
    @Default(0) int pickupFeeKobo,
    /// Yummy Chops Plus: fees and VAT the member did not pay (informational).
    @Default(0) int plusSavingsKobo,
    required int totalKobo,
    String? voucherCode,
  }) = _PriceBreakdown;
  factory PriceBreakdown.fromJson(Map<String, dynamic> json) => _$PriceBreakdownFromJson(json);
}

@freezed
abstract class Quote with _$Quote {
  const factory Quote({
    required String id,
    required String restaurantName,
    @Default(<PricedLine>[]) List<PricedLine> lines,
    required PriceBreakdown breakdown,
    required String fulfillment,
    required int etaMinutes,
    required DateTime estimatedDeliveryAt,
    required DateTime expiresAt,
  }) = _Quote;
  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);
}

@freezed
abstract class OrderProgress with _$OrderProgress {
  const factory OrderProgress({
    required int step,
    @Default(5) int totalSteps,
    required String label,
    /// Waybills use their own steps (Booked, At the hub, On the way, Arrived, Delivered).
    @Default(<String>[]) List<String> steps,
  }) = _OrderProgress;
  factory OrderProgress.fromJson(Map<String, dynamic> json) => _$OrderProgressFromJson(json);
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    required String shortCode,
    @Default('food') String vertical,
    required String status,
    required String restaurantName,
    @Default('delivery') String fulfillment,
    @Default(<PricedLine>[]) List<PricedLine> lines,
    /// The rider's view: what to collect, as names and quantities (riders never see prices, so no `lines`).
    @Default(<OrderItem>[]) List<OrderItem> items,
    PriceBreakdown? breakdown,
    DeliveryAddress? deliveryAddress,
    OrderProgress? progress,
    String? riderName,
    String? customerName,
    String? restaurantAddress,
    GeoPoint? restaurantLocation,
    DateTime? estimatedDeliveryAt,
    DateTime? readyAt,
    DateTime? createdAt,
    int? riderPayKobo,
    @Default(false) bool reviewed,
    ParcelDetails? parcel,
    @Default(0) int refundTotalKobo,
    @Default(OrderPayment()) OrderPayment payment,
    DateTime? cashCollectedAt,
    // Rider view: cash to take at the door ('cash' = pay on delivery) and the amount (0 when prepaid).
    String? paymentMethod,
    @Default(0) int collectCashKobo,
    /// Interstate waybill details (vertical 'waybill').
    WaybillDetails? waybill,
    /// Rider view of a waybill's rider job: 'first_mile' ends with hub staff, 'last_mile' at the door.
    String? legKind,
    @Default(false) bool hubHandover,
    /// Placed by the host of a group order.
    String? groupOrderId,
  }) = _Order;
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

/// How an order is paid: a gateway (paystack, flutterwave…), the wallet, or cash on delivery.
@freezed
abstract class OrderPayment with _$OrderPayment {
  const factory OrderPayment({String? provider, String? reference, @Default('unpaid') String status, DateTime? paidAt}) =
      _OrderPayment;
  factory OrderPayment.fromJson(Map<String, dynamic> json) => _$OrderPaymentFromJson(json);
}

@freezed
abstract class CheckoutResult with _$CheckoutResult {
  const factory CheckoutResult({
    required String orderId,
    @Default('') String status,
    required String reference,
    /// Null for wallet and pay-on-delivery checkouts: the order is already placed.
    String? authorizationUrl,
    required int amountKobo,
    required String provider,
    String? failoverFrom,
  }) = _CheckoutResult;
  factory CheckoutResult.fromJson(Map<String, dynamic> json) => _$CheckoutResultFromJson(json);
}

/// One payment covering several orders (`POST /v1/checkouts`). [reference] is null for cash,
/// [authorizationUrl] is null for wallet and cash.
@freezed
abstract class MultiCheckoutResult with _$MultiCheckoutResult {
  const factory MultiCheckoutResult({
    required List<String> orderIds,
    required String provider,
    String? reference,
    String? authorizationUrl,
    required int amountKobo,
    @Default('') String paymentStatus,
    @Default([]) List<MultiCheckoutOrder> orders,
  }) = _MultiCheckoutResult;
  factory MultiCheckoutResult.fromJson(Map<String, dynamic> json) => _$MultiCheckoutResultFromJson(json);
}

@freezed
abstract class MultiCheckoutOrder with _$MultiCheckoutOrder {
  const factory MultiCheckoutOrder({
    required String orderId,
    @Default('') String status,
    @Default(0) int amountKobo,
  }) = _MultiCheckoutOrder;
  factory MultiCheckoutOrder.fromJson(Map<String, dynamic> json) => _$MultiCheckoutOrderFromJson(json);
}

@freezed
abstract class PaymentMethodOption with _$PaymentMethodOption {
  const factory PaymentMethodOption({
    required String id,
    required String label,
    @Default(false) bool available,
    String? reason,
    int? balanceKobo,
    int? shortByKobo,
  }) = _PaymentMethodOption;
  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) => _$PaymentMethodOptionFromJson(json);
}

@freezed
abstract class PaymentOptions with _$PaymentOptions {
  const factory PaymentOptions({
    required String orderId,
    required int totalKobo,
    @Default(<PaymentMethodOption>[]) List<PaymentMethodOption> methods,
  }) = _PaymentOptions;
  factory PaymentOptions.fromJson(Map<String, dynamic> json) => _$PaymentOptionsFromJson(json);
}

@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required String kind,
    @Default('') String description,
    String? reference,
    String? orderId,
    required DateTime createdAt,
    @Default('in') String direction,
    required int amountKobo,
  }) = _WalletTransaction;
  factory WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);
}

@freezed
abstract class WalletLimits with _$WalletLimits {
  const factory WalletLimits({
    @Default(50000) int minTopupKobo,
    @Default(10000000) int maxTopupKobo,
    @Default(30000000) int maxBalanceKobo,
  }) = _WalletLimits;
  factory WalletLimits.fromJson(Map<String, dynamic> json) => _$WalletLimitsFromJson(json);
}

/// Cash-on-delivery money collected for a seller (vendor COD on packages).
@freezed
abstract class SellerSummary with _$SellerSummary {
  const factory SellerSummary({
    @Default(0) int codBalanceKobo,
    @Default(0) int pendingPayoutsKobo,
    @Default(0) int availableKobo,
    @Default(100000) int minPayoutKobo,
  }) = _SellerSummary;
  factory SellerSummary.fromJson(Map<String, dynamic> json) => _$SellerSummaryFromJson(json);
}

@freezed
abstract class WalletOverview with _$WalletOverview {
  const factory WalletOverview({
    @Default(0) int balanceKobo,
    @Default(true) bool enabled,
    @Default(WalletLimits()) WalletLimits limits,
    @Default(false) bool refundToWallet,
    @Default(<WalletTransaction>[]) List<WalletTransaction> transactions,
    SellerSummary? seller,
  }) = _WalletOverview;
  factory WalletOverview.fromJson(Map<String, dynamic> json) => _$WalletOverviewFromJson(json);
}

// ------------------------------------------------------------------------------------------ waybill

@freezed
abstract class WaybillParty with _$WaybillParty {
  const factory WaybillParty({
    required String name,
    required String phone,
    String? line1,
    String? area,
    GeoPoint? location,
    String? instructions,
  }) = _WaybillParty;
  factory WaybillParty.fromJson(Map<String, dynamic> json) => _$WaybillPartyFromJson(json);
}

@freezed
abstract class WaybillDetails with _$WaybillDetails {
  const factory WaybillDetails({
    String? trackingCode,
    @Default('') String originCity,
    @Default('') String destinationCity,
    @Default('') String originCityName,
    @Default('') String destinationCityName,
    @Default('') String originHubId,
    @Default('') String destinationHubId,
    @Default('') String originHubName,
    @Default('') String destinationHubName,
    @Default('') String destinationHubAddress,
    @Default('') String destinationHubHours,
    @Default('pickup') String firstMile,
    @Default('door') String lastMile,
    required WaybillParty sender,
    required WaybillParty recipient,
    @Default('small') String size,
    @Default(1) double weightKg,
    @Default('other') String category,
    @Default('') String description,
    int? codAmountKobo,
    @Default('') String carrierName,
    String? stage,
    String? etaFrom,
    String? etaTo,
  }) = _WaybillDetails;
  factory WaybillDetails.fromJson(Map<String, dynamic> json) => _$WaybillDetailsFromJson(json);
}

@freezed
abstract class WaybillQuote with _$WaybillQuote {
  const factory WaybillQuote({
    required String id,
    required WaybillDetails details,
    required PriceBreakdown breakdown,
    @Default('') String etaText,
    required DateTime expiresAt,
  }) = _WaybillQuote;
  factory WaybillQuote.fromJson(Map<String, dynamic> json) => _$WaybillQuoteFromJson(json);
}

@freezed
abstract class WaybillHub with _$WaybillHub {
  const factory WaybillHub({
    required String id,
    required String name,
    required String city,
    @Default('') String address,
    @Default('') String hours,
    @Default(true) bool isSample,
  }) = _WaybillHub;
  factory WaybillHub.fromJson(Map<String, dynamic> json) => _$WaybillHubFromJson(json);
}

@freezed
abstract class WaybillOrigin with _$WaybillOrigin {
  const factory WaybillOrigin({
    required String id,
    required String name,
    @Default(false) bool homePickup,
    @Default(<WaybillHub>[]) List<WaybillHub> dropoffHubs,
  }) = _WaybillOrigin;
  factory WaybillOrigin.fromJson(Map<String, dynamic> json) => _$WaybillOriginFromJson(json);
}

@freezed
abstract class WaybillDestination with _$WaybillDestination {
  const factory WaybillDestination({
    required String city,
    required String name,
    @Default(false) bool doorDelivery,
    @Default(<int>[1, 2]) List<int> transitDays,
    @Default(0) int fromKobo,
    @Default('') String carrier,
    @Default(<WaybillHub>[]) List<WaybillHub> collectionHubs,
  }) = _WaybillDestination;
  factory WaybillDestination.fromJson(Map<String, dynamic> json) => _$WaybillDestinationFromJson(json);
}

@freezed
abstract class WaybillDestinations with _$WaybillDestinations {
  const factory WaybillDestinations({
    @Default(<WaybillHub>[]) List<WaybillHub> dropoffHubs,
    @Default(<WaybillDestination>[]) List<WaybillDestination> destinations,
  }) = _WaybillDestinations;
  factory WaybillDestinations.fromJson(Map<String, dynamic> json) => _$WaybillDestinationsFromJson(json);
}

@freezed
abstract class WaybillScan with _$WaybillScan {
  const factory WaybillScan({required String stage, required String label, required DateTime at, String? place}) =
      _WaybillScan;
  factory WaybillScan.fromJson(Map<String, dynamic> json) => _$WaybillScanFromJson(json);
}

@freezed
abstract class WaybillTracking with _$WaybillTracking {
  const factory WaybillTracking({
    required String trackingCode,
    @Default('') String origin,
    @Default('') String destination,
    @Default('') String label,
    @Default(0) int step,
    @Default(<String>[]) List<String> steps,
    @Default('') String etaText,
    @Default('door') String lastMile,
    @Default(<WaybillScan>[]) List<WaybillScan> milestones,
    @Default(false) bool delivered,
  }) = _WaybillTracking;
  factory WaybillTracking.fromJson(Map<String, dynamic> json) => _$WaybillTrackingFromJson(json);
}

// ------------------------------------------------------------------------------------------ growth (phase 4)

@freezed
abstract class PlusPlan with _$PlusPlan {
  const factory PlusPlan({
    @Default(true) bool enabled,
    required int priceKobo,
    @Default(0) int vatKobo,
    @Default(30) int periodDays,
    @Default(0) int freeDeliveryMinSubtotalKobo,
    @Default(0) int serviceFeeDiscountBps,
    @Default(1) int pointsMultiplier,
    @Default(<String>[]) List<String> benefits,
  }) = _PlusPlan;
  factory PlusPlan.fromJson(Map<String, dynamic> json) => _$PlusPlanFromJson(json);
}

@freezed
abstract class PlusMembership with _$PlusMembership {
  const factory PlusMembership({
    @Default('active') String status,
    required DateTime paidThrough,
    @Default('') String paidThroughText,
    @Default(0) int daysLeft,
    @Default(true) bool autoRenew,
    @Default(false) bool canRenew,
    @Default(0) int periods,
    @Default(0) int savingsKobo,
  }) = _PlusMembership;
  factory PlusMembership.fromJson(Map<String, dynamic> json) => _$PlusMembershipFromJson(json);
}

@freezed
abstract class PlusOverview with _$PlusOverview {
  const factory PlusOverview({required PlusPlan plan, @Default(false) bool member, PlusMembership? membership}) =
      _PlusOverview;
  factory PlusOverview.fromJson(Map<String, dynamic> json) => _$PlusOverviewFromJson(json);
}

@freezed
abstract class RewardVoucher with _$RewardVoucher {
  const factory RewardVoucher({
    required String code,
    @Default('') String description,
    required int valueKobo,
    @Default(0) int minSubtotalKobo,
    DateTime? endsAt,
    @Default('points') String source,
  }) = _RewardVoucher;
  factory RewardVoucher.fromJson(Map<String, dynamic> json) => _$RewardVoucherFromJson(json);
}

@freezed
abstract class PointsEntry with _$PointsEntry {
  const factory PointsEntry({
    required String id,
    required String kind,
    required int points,
    String? orderId,
    String? voucherCode,
    @Default('') String note,
    required DateTime at,
  }) = _PointsEntry;
  factory PointsEntry.fromJson(Map<String, dynamic> json) => _$PointsEntryFromJson(json);
}

@freezed
abstract class RewardsRedeem with _$RewardsRedeem {
  const factory RewardsRedeem({
    @Default(true) bool enabled,
    @Default(500) int stepPoints,
    @Default(50000) int stepValueKobo,
    @Default(0) int redeemablePoints,
    @Default(0) int pointsToNext,
    @Default(0) int minSubtotalKobo,
    @Default(90) int validDays,
  }) = _RewardsRedeem;
  factory RewardsRedeem.fromJson(Map<String, dynamic> json) => _$RewardsRedeemFromJson(json);
}

@freezed
abstract class RewardsReferral with _$RewardsReferral {
  const factory RewardsReferral({
    @Default(true) bool enabled,
    @Default('') String code,
    @Default(0) int friendGetsKobo,
    @Default(0) int youGetKobo,
    @Default(0) int minSubtotalKobo,
    @Default(0) int friendsRewarded,
    @Default(false) bool applied,
    @Default(false) bool canApply,
    @Default('') String shareText,
  }) = _RewardsReferral;
  factory RewardsReferral.fromJson(Map<String, dynamic> json) => _$RewardsReferralFromJson(json);
}

@freezed
abstract class RewardsOverview with _$RewardsOverview {
  const factory RewardsOverview({
    @Default(0) int points,
    @Default(0) int lifetimePoints,
    @Default(0) int pointsValueKobo,
    required RewardsRedeem redeem,
    required RewardsReferral referral,
    @Default(<RewardVoucher>[]) List<RewardVoucher> vouchers,
    @Default(<PointsEntry>[]) List<PointsEntry> history,
  }) = _RewardsOverview;
  factory RewardsOverview.fromJson(Map<String, dynamic> json) => _$RewardsOverviewFromJson(json);
}

@freezed
abstract class GroupMemberView with _$GroupMemberView {
  const factory GroupMemberView({
    required String uid,
    required String name,
    @Default(false) bool isHost,
    @Default(false) bool me,
    @Default(false) bool ready,
    @Default(0) int items,
    @Default(0) int itemsKobo,
  }) = _GroupMemberView;
  factory GroupMemberView.fromJson(Map<String, dynamic> json) => _$GroupMemberViewFromJson(json);
}

@freezed
abstract class GroupLineView with _$GroupLineView {
  const factory GroupLineView({
    required String id,
    required String memberUid,
    @Default('') String member,
    required String itemId,
    required String name,
    required int quantity,
    @Default(<OptionSelection>[]) List<OptionSelection> selections,
    @Default(<String>[]) List<String> options,
    String? notes,
    @Default(0) int lineTotalKobo,
    String? problem,
  }) = _GroupLineView;
  factory GroupLineView.fromJson(Map<String, dynamic> json) => _$GroupLineViewFromJson(json);
}

@freezed
abstract class GroupShareView with _$GroupShareView {
  const factory GroupShareView({
    required String uid,
    required String name,
    @Default(false) bool me,
    @Default(0) int itemsKobo,
    required int amountKobo,
    @Default('unpaid') String status,
    @Default(false) bool paidByHost,
  }) = _GroupShareView;
  factory GroupShareView.fromJson(Map<String, dynamic> json) => _$GroupShareViewFromJson(json);
}

@freezed
abstract class GroupOrderRef with _$GroupOrderRef {
  const factory GroupOrderRef({required String id, @Default('') String shortCode, required String status, @Default(0) int totalKobo}) =
      _GroupOrderRef;
  factory GroupOrderRef.fromJson(Map<String, dynamic> json) => _$GroupOrderRefFromJson(json);
}

@freezed
abstract class GroupMyShare with _$GroupMyShare {
  const factory GroupMyShare({required int amountKobo, @Default(0) int itemsKobo, @Default('unpaid') String status}) =
      _GroupMyShare;
  factory GroupMyShare.fromJson(Map<String, dynamic> json) => _$GroupMyShareFromJson(json);
}

@freezed
abstract class GroupRestaurant with _$GroupRestaurant {
  const factory GroupRestaurant({required String id, required String name}) = _GroupRestaurant;
  factory GroupRestaurant.fromJson(Map<String, dynamic> json) => _$GroupRestaurantFromJson(json);
}

@freezed
abstract class GroupOrder with _$GroupOrder {
  const factory GroupOrder({
    required String id,
    required String code,
    required String status,
    @Default('each') String splitMode,
    @Default(false) bool isHost,
    @Default('') String hostName,
    required GroupRestaurant restaurant,
    @Default('delivery') String fulfillment,
    String? deliveryArea,
    @Default(<GroupMemberView>[]) List<GroupMemberView> members,
    @Default(10) int maxMembers,
    @Default(<GroupLineView>[]) List<GroupLineView> lines,
    @Default(0) int estimatedItemsKobo,
    DateTime? expiresAt,
    GroupOrderRef? order,
    @Default(0) int totalKobo,
    @Default(<GroupShareView>[]) List<GroupShareView> shares,
    GroupMyShare? myShare,
    @Default(0) int paidKobo,
    @Default(0) int remainingKobo,
    DateTime? payBy,
    @Default(false) bool canPay,
    @Default(false) bool canCoverRest,
    String? cancelReason,
  }) = _GroupOrder;
  factory GroupOrder.fromJson(Map<String, dynamic> json) => _$GroupOrderFromJson(json);
}

/// Shown on group cards and screens: what the group is waiting for.
String groupStatusLabel(GroupOrder g) => switch (g.status) {
      'open' => 'Collecting orders',
      'locked' => 'Cart locked by the host',
      'cancelled' => 'Cancelled',
      'expired' => 'Expired',
      _ => switch (g.order?.status) {
          'pending_payment' => 'Waiting for everyone to pay',
          'draft' => g.splitMode == 'host' ? 'Waiting for the host to pay' : 'Order placed',
          final s? => s.replaceAll('_', ' '),
          null => 'Order placed',
        },
    };

// ------------------------------------------------------------------------------------------ WhatsApp (phase 5)

@freezed
abstract class WhatsAppStatus with _$WhatsAppStatus {
  const factory WhatsAppStatus({
    @Default(false) bool enabled,
    @Default(false) bool linked,
    String? number,
    DateTime? linkedAt,
    @Default('') String businessNumber,
    String? chatLink,
  }) = _WhatsAppStatus;
  factory WhatsAppStatus.fromJson(Map<String, dynamic> json) => _$WhatsAppStatusFromJson(json);
}

@freezed
abstract class WhatsAppLinkCode with _$WhatsAppLinkCode {
  const factory WhatsAppLinkCode({
    required String code,
    required DateTime expiresAt,
    @Default('') String businessNumber,
    required String waLink,
  }) = _WhatsAppLinkCode;
  factory WhatsAppLinkCode.fromJson(Map<String, dynamic> json) => _$WhatsAppLinkCodeFromJson(json);
}

@freezed
abstract class TopUpResult with _$TopUpResult {
  const factory TopUpResult({
    required String reference,
    required String provider,
    String? authorizationUrl,
    required int amountKobo,
  }) = _TopUpResult;
  factory TopUpResult.fromJson(Map<String, dynamic> json) => _$TopUpResultFromJson(json);
}

@freezed
abstract class Tracking with _$Tracking {
  const factory Tracking({
    required String status,
    String? riderName,
    GeoPoint? riderLocation,
    int? etaMinutes,
    DateTime? estimatedDeliveryAt,
  }) = _Tracking;
  factory Tracking.fromJson(Map<String, dynamic> json) => _$TrackingFromJson(json);
}

@freezed
abstract class DeliveryOffer with _$DeliveryOffer {
  const factory DeliveryOffer({
    required String id,
    required String orderId,
    required String restaurantName,
    required double distanceToRestaurantKm,
    required int payoutKobo,
    required DateTime expiresAt,
    required GeoPoint pickup,
    GeoPoint? dropoff,
    String? dropoffArea,
  }) = _DeliveryOffer;
  factory DeliveryOffer.fromJson(Map<String, dynamic> json) => _$DeliveryOfferFromJson(json);
}

@freezed
abstract class RiderProfile with _$RiderProfile {
  const factory RiderProfile({
    required String uid,
    required String name,
    @Default('motorcycle') String vehicle,
    @Default('pending') String status,
    @Default(false) bool isOnline,
    @Default(5) double rating,
    @Default(<String>[]) List<String> activeOrderIds,
    @Default(0) int completedDeliveries,
  }) = _RiderProfile;
  factory RiderProfile.fromJson(Map<String, dynamic> json) => _$RiderProfileFromJson(json);
}

@freezed
abstract class Earnings with _$Earnings {
  const factory Earnings({
    required int balanceKobo,
    required int pendingPayoutsKobo,
    required int availableKobo,
    required int deliveriesCompleted,
    // The generated name would be `earned_last7_days_kobo`; the API sends `earned_last_7_days_kobo`.
    @JsonKey(name: 'earned_last_7_days_kobo') required int earnedLast7DaysKobo,
    /// Cash collected at the door that the rider still has to hand in (netted off before withdrawals).
    @Default(0) int cashHeldKobo,
  }) = _Earnings;
  factory Earnings.fromJson(Map<String, dynamic> json) => _$EarningsFromJson(json);
}

@freezed
abstract class ChatApproval with _$ChatApproval {
  const factory ChatApproval({
    required String tool,
    required String toolCallId,
    @Default(<String, dynamic>{}) Map<String, dynamic> preview,
  }) = _ChatApproval;
  factory ChatApproval.fromJson(Map<String, dynamic> json) => _$ChatApprovalFromJson(json);
}

@freezed
abstract class ChatResponse with _$ChatResponse {
  const factory ChatResponse({
    required String threadId,
    required String status,
    String? reply,
    String? agent,
    @Default(<Map<String, dynamic>>[]) List<Map<String, dynamic>> cards,
    ChatApproval? approval,
  }) = _ChatResponse;
  factory ChatResponse.fromJson(Map<String, dynamic> json) => _$ChatResponseFromJson(json);
}


// ------------------------------------------------------------------------------------- multi-service
@freezed
abstract class PromoBadge with _$PromoBadge {
  const factory PromoBadge({required String code, required String label}) = _PromoBadge;
  factory PromoBadge.fromJson(Map<String, dynamic> json) => _$PromoBadgeFromJson(json);
}

/// A Yummy Chops service: food (Order Food), pharmacy, beauty (Beauty & Skin Care), grocery (Shop & Groceries),
/// market (Buy Foodstuff) or parcel (Package Delivery): the home-screen bubbles.
@freezed
abstract class ServiceInfo with _$ServiceInfo {
  const factory ServiceInfo({
    required String id,
    required String name,
    @Default('') String tagline,
    @Default(true) bool available,
    int? merchants,
    @Default(<String>[]) List<String> options,
    @Default(<String>[]) List<String> comingSoon,
    @Default(<String>[]) List<String> cities,
  }) = _ServiceInfo;
  factory ServiceInfo.fromJson(Map<String, dynamic> json) => _$ServiceInfoFromJson(json);
}

@freezed
abstract class BrowseCategory with _$BrowseCategory {
  const factory BrowseCategory({required String id, required String name, @Default('') String emoji, @Default(0) int merchants}) =
      _BrowseCategory;
  factory BrowseCategory.fromJson(Map<String, dynamic> json) => _$BrowseCategoryFromJson(json);
}

/// A neighbourhood with an approximate centre, used for addresses without a map pin.
@freezed
abstract class PlaceArea with _$PlaceArea {
  const factory PlaceArea({required String name, required String city, required double lat, required double lng}) = _PlaceArea;
  factory PlaceArea.fromJson(Map<String, dynamic> json) => _$PlaceAreaFromJson(json);
}

@freezed
abstract class ParcelStop with _$ParcelStop {
  const factory ParcelStop({
    required String name,
    required String phone,
    required String line1,
    String? area,
    @Default('Lagos') String city,
    required GeoPoint location,
    String? instructions,
  }) = _ParcelStop;
  factory ParcelStop.fromJson(Map<String, dynamic> json) => _$ParcelStopFromJson(json);
}

@freezed
abstract class ParcelDetails with _$ParcelDetails {
  const factory ParcelDetails({
    required ParcelStop pickup,
    required ParcelStop dropoff,
    @Default('small') String size,
    @Default('other') String category,
    @Default('') String description,
    @Default('lagos') String city,
    /// Cash the rider collects from the recipient for the sender (vendor cash on delivery).
    int? codAmountKobo,
  }) = _ParcelDetails;
  factory ParcelDetails.fromJson(Map<String, dynamic> json) => _$ParcelDetailsFromJson(json);
}

@freezed
abstract class ParcelQuote with _$ParcelQuote {
  const factory ParcelQuote({
    required String id,
    required ParcelDetails details,
    required PriceBreakdown breakdown,
    required double distanceKm,
    required int etaMinutes,
    required DateTime estimatedDeliveryAt,
    DateTime? scheduledFor,
    required DateTime expiresAt,
  }) = _ParcelQuote;
  factory ParcelQuote.fromJson(Map<String, dynamic> json) => _$ParcelQuoteFromJson(json);
}

@freezed
abstract class VerticalSpend with _$VerticalSpend {
  const factory VerticalSpend({@Default(0) int orders, @Default(0) int spentKobo}) = _VerticalSpend;
  factory VerticalSpend.fromJson(Map<String, dynamic> json) => _$VerticalSpendFromJson(json);
}

@freezed
abstract class FavouriteMerchant with _$FavouriteMerchant {
  const factory FavouriteMerchant({required String id, required String name, @Default(0) int orders}) = _FavouriteMerchant;
  factory FavouriteMerchant.fromJson(Map<String, dynamic> json) => _$FavouriteMerchantFromJson(json);
}

/// Totals across a customer's paid orders (net of refunds), from /v1/me/order-summary.
@freezed
abstract class OrderSummary with _$OrderSummary {
  const factory OrderSummary({
    @Default(0) int ordersCount,
    @Default(0) int completedCount,
    @Default(0) int inProgressCount,
    @Default(0) int totalSpentKobo,
    @Default(0) int thisMonthSpentKobo,
    @Default(0) int refundedKobo,
    @Default(<String, VerticalSpend>{}) Map<String, VerticalSpend> byVertical,
    FavouriteMerchant? favouriteMerchant,
  }) = _OrderSummary;
  factory OrderSummary.fromJson(Map<String, dynamic> json) => _$OrderSummaryFromJson(json);
}

@freezed
abstract class SupportContacts with _$SupportContacts {
  const factory SupportContacts({
    @Default('') String whatsapp,
    @Default('') String phone,
    @Default('') String email,
    @Default('') String hours,
    @Default(true) bool placeholders,
  }) = _SupportContacts;
  factory SupportContacts.fromJson(Map<String, dynamic> json) => _$SupportContactsFromJson(json);
}

/// One thing bought, as a receipt prints it (ADR-0019).
@freezed
abstract class ReceiptLine with _$ReceiptLine {
  const factory ReceiptLine({
    required String name,
    @Default(1) int quantity,
    @Default(0) int amountKobo,
    @Default([]) List<String> details,
  }) = _ReceiptLine;
  factory ReceiptLine.fromJson(Map<String, dynamic> json) => _$ReceiptLineFromJson(json);
}

/// A fee, tax or discount row of a receipt; a discount is negative.
@freezed
abstract class ReceiptCharge with _$ReceiptCharge {
  const factory ReceiptCharge({required String label, @Default(0) int amountKobo}) = _ReceiptCharge;
  factory ReceiptCharge.fromJson(Map<String, dynamic> json) => _$ReceiptChargeFromJson(json);
}

/// What the customer paid for one order. [saved] is true once they have printed it (kept under "My receipts").
@freezed
abstract class Receipt with _$Receipt {
  const factory Receipt({
    required String id,
    required String number,
    required String orderId,
    @Default('') String orderCode,
    String? customerName,
    @Default('food') String service,
    @Default('') String serviceName,
    @Default('') String seller,
    @Default('') String sellerAddress,
    @Default([]) List<String> summary,
    @Default([]) List<ReceiptLine> lines,
    @Default([]) List<ReceiptCharge> charges,
    @Default(0) int totalKobo,
    @Default(0) int savingsKobo,
    @Default(0) int refundedKobo,
    @Default('') String paidWith,
    String? paymentReference,
    DateTime? paidAt,
    DateTime? orderedAt,
    DateTime? issuedAt,
    DateTime? printedAt,
    @Default(0) int printCount,
    @Default(false) bool saved,
  }) = _Receipt;
  factory Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);
}
