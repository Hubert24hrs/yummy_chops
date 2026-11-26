// Response and request shapes of gudmeal-api (see openapi.json). All money values are integer kobo.

export type Kobo = number;

export type OrderStatus =
  | "draft" | "pending_payment" | "paid" | "submitted_to_restaurant" | "restaurant_accepted" | "preparing"
  | "ready_for_pickup" | "rider_assigned" | "picked_up" | "in_transit" | "delivered" | "completed"
  | "cancelled" | "refund_pending" | "partially_refunded" | "refunded" | "disputed";

export type Fulfillment = "delivery" | "pickup";
export type ItemKind = "main" | "combo" | "side" | "snack" | "drink" | "dessert" | "extra" | "product";
/** Yummy Chops services: food, pharmacy, beauty, grocery and market are sold by merchants; parcels are courier jobs. */
/** A service that shops sell through: restaurants (Order Food), pharmacies, beauty & skin care shops, supermarkets
 * (Shop & Groceries) and market shoppers (Buy Foodstuff). */
export type MerchantVertical = "food" | "beauty" | "grocery" | "pharmacy" | "market";
export type Vertical = MerchantVertical | "parcel" | "waybill";

export interface GeoPoint { lat: number; lng: number }

export interface OpeningHours {
  timezone: string;
  weekly: Record<string, { open: string; close: string }[]>;
  closed_dates: string[];
}

export interface PromoBadge { code: string; label: string }

export interface RestaurantCard {
  id: string; vertical: MerchantVertical; city: string; promotions: PromoBadge[]; name: string; slug: string; description: string; cuisines: string[]; tags: string[];
  image_url: string | null; cover_url: string | null; area: string; rating: number; rating_count: number;
  price_level: number; is_open: boolean; is_accepting_orders: boolean; is_featured: boolean;
  next_opening_at: string | null; distance_km: number | null; eta_minutes: number | null;
  delivery_fee_kobo: Kobo | null; min_order_kobo: Kobo; supports_delivery: boolean; supports_pickup: boolean;
  delivers_to_location: boolean | null;
  /** The shop's public pin (for maps). */
  location?: GeoPoint | null;
  /** A short label for the kind of shop, e.g. "Shopper" for market shopping. */
  badge?: string | null;
}

/** One hero dish on the Discover carousel (GET /v1/discover/dishes). Prices and fees come from the API as set. */
export interface DiscoverDish {
  item_id: string; restaurant_id: string; restaurant_name: string; area: string; city: string; name: string;
  description: string; price_kobo: Kobo; image_url: string | null;
  /** Illustrated-plate family: rice, soup_swallow, broth, skewers, grill, pizza, wrap, bites, bowl or plate. */
  art: string; kind: string; tags: string[]; dietary: string[]; allergens: string[]; spice_level: number; serves: number;
  prep_minutes: number | null;
  /** How many times the dish has been ordered. */
  likes: number;
  /** The kitchen's rating out of 5. */
  rating: number; rating_count: number;
  /** Short line above the title, e.g. "#1 Most loved dish" or "New kitchen · Lekki". */
  eyebrow: string; has_options: boolean; is_available: boolean; is_open: boolean; is_accepting_orders: boolean;
  is_new_kitchen: boolean; distance_km?: number | null; eta_minutes?: number | null; delivery_fee_kobo?: Kobo | null;
  delivers_to_location?: boolean | null;
}
export type DiscoverSectionId = "most_loved" | "new_kitchens" | "top_rated";
export interface DiscoverSection { id: DiscoverSectionId; title: string; subtitle: string; dishes: DiscoverDish[] }
export interface DiscoverFeed { city: string | null; generated_at: string; sections: DiscoverSection[] }

export interface OptionChoice { id: string; name: string; price_delta_kobo: Kobo; is_available: boolean }
export interface OptionGroup {
  id: string; restaurant_id: string; name: string; min_select: number; max_select: number; choices: OptionChoice[];
}
export interface MenuCategory { id: string; name: string; position: number }
export interface MenuItem {
  id: string; restaurant_id: string; category_id: string; name: string; description: string; price_kobo: Kobo;
  image_url: string | null; kind: ItemKind; tags: string[]; dietary: string[]; allergens: string[]; serves: number;
  spice_level: number; is_available: boolean; is_active: boolean; popularity: number; option_group_ids: string[];
  prep_minutes: number | null; position: number;
  /** Size or measure: "75 cl x 12", "derica", "12 tablets". */
  unit_label?: string | null;
  brand?: string | null;
  /** A picture until the shop uploads a photo. */
  emoji?: string | null;
  /** Prescription-only: customers never see these and cannot order them online. */
  requires_prescription?: boolean;
}
export interface MenuSection { category: MenuCategory; items: MenuItem[] }
export interface RestaurantDetail {
  restaurant: RestaurantCard; address: string; location: GeoPoint; opening_hours: OpeningHours;
  avg_prep_minutes: number; sections: MenuSection[]; option_groups: Record<string, OptionGroup>;
}

export interface Restaurant {
  id: string; vertical?: MerchantVertical; name: string; slug: string; description: string; cuisines: string[]; area: string; address: string;
  location: GeoPoint; rating: number; rating_count: number; avg_prep_minutes: number; opening_hours: OpeningHours;
  is_accepting_orders: boolean; status: "pending" | "active" | "suspended"; min_order_kobo: Kobo;
  supports_delivery: boolean; supports_pickup: boolean; image_url: string | null; cover_url: string | null;
  owner_uid: string | null; commission_bps: number | null; phone: string | null;
  /** A branch of a business (ADR-0028): its business ID, the branch's name and its manager's number. A branch sells
   * the menu of `menu_restaurant_id` (the main branch). */
  business_id?: string | null; branch_name?: string | null; manager_phone?: string | null; menu_restaurant_id?: string | null;
}

export interface DeliveryAddress {
  label?: string | null; line1: string; area?: string | null; city?: string; state?: string; location: GeoPoint;
  instructions?: string | null; contact_phone?: string | null;
  /** Google place ID when the address came from search. */
  place_id?: string | null;
}
export interface SavedAddress extends DeliveryAddress { id: string }

export interface OptionSelection { group_id: string; choice_ids: string[] }
export interface CartLine { item_id: string; quantity: number; selections: OptionSelection[]; notes?: string | null }

export interface QuoteRequest {
  restaurant_id: string; lines: CartLine[]; fulfillment: Fulfillment; delivery_address?: DeliveryAddress | null;
  scheduled_for?: string | null; voucher_code?: string | null;
}

export interface PricedLine {
  item_id: string; name: string; kind: ItemKind; quantity: number; unit_price_kobo: Kobo;
  options_unit_price_kobo: Kobo; line_total_kobo: Kobo; selections: OptionSelection[]; selection_labels: string[];
  notes: string | null;
}
export interface PriceBreakdown {
  subtotal_kobo: Kobo; delivery_fee_kobo: Kobo; service_fee_kobo: Kobo; small_order_fee_kobo: Kobo; vat_kobo: Kobo;
  discount_kobo: Kobo; total_kobo: Kobo; discount_funded_by: "platform" | "restaurant" | null; voucher_code: string | null;
  /** Cash-on-delivery collection fee (packages). */
  cod_fee_kobo?: Kobo;
  /** Waybill: carrying the package between cities, and the rider pickup from the sender. */
  linehaul_fee_kobo?: Kobo; pickup_fee_kobo?: Kobo;
  /** Yummy Chops Plus: fees and VAT the member did not pay on this order (informational). */
  plus_savings_kobo?: Kobo;
}
export interface Quote {
  id: string; restaurant_id: string; restaurant_name: string; lines: PricedLine[]; breakdown: PriceBreakdown;
  fulfillment: Fulfillment; delivery_address: DeliveryAddress | null; distance_km: number | null; eta_minutes: number;
  estimated_delivery_at: string; scheduled_for: string | null; created_at: string; expires_at: string;
  /** Road distance the delivery fee used, and whether Google measured it. */
  road_distance_km?: number | null; route_source?: "google" | "estimate" | null;
}

export interface Order {
  id: string; short_code: string; vertical?: Vertical; parcel?: ParcelDetails | null; customer_id: string; customer_name: string | null; restaurant_id: string;
  restaurant_name: string; restaurant_address: string; restaurant_location: GeoPoint; status: OrderStatus;
  fulfillment: Fulfillment; lines: PricedLine[]; breakdown: PriceBreakdown; delivery_address: DeliveryAddress | null;
  distance_km: number | null; scheduled_for: string | null;
  payment: {
    provider: string | null; reference: string | null; status: string; paid_at: string | null;
    /** A split card payment: the business's share, sent straight to its bank account by Paystack (ADR-0028). */
    split_to_business_kobo?: Kobo;
  };
  rider_id: string | null; rider_name: string | null; prep_minutes: number | null; estimated_delivery_at: string | null;
  accepted_at: string | null; ready_at: string | null; picked_up_at: string | null; delivered_at: string | null;
  completed_at: string | null; cancelled_at: string | null; cancellation_reason: string | null;
  refund_total_kobo: Kobo; reviewed: boolean; channel: string; created_at: string; updated_at: string;
  /** Placed by the host of a group order (split bill). */
  group_order_id?: string | null;
  /** Set when the rider took cash at the door (pay on delivery and/or a package's COD amount). */
  cash_collected_at?: string | null;
  /** Waybill orders: steps are the waybill's own (Booked, At the hub, On the way, Arrived, Delivered). */
  progress: { step: number; total_steps: number; label: string; steps?: string[] };
  audience: "customer" | "restaurant" | "rider" | "staff";
  waybill?: WaybillDetails | null;
  // restaurant view
  restaurant_earning_kobo?: Kobo; commission_kobo?: Kobo;
  /** The rider on the way to the shop or with the order: their number, and about how many minutes away they are
   * while coming to collect it (null when unknown). */
  rider?: { name: string; phone: string | null; eta_minutes: number | null; verified: boolean } | null;
  // rider view: what to collect at the door, and waybill legs (first mile ends with hub staff)
  payment_method?: "cash" | "prepaid"; collect_cash_kobo?: Kobo;
  leg_kind?: "first_mile" | "last_mile" | null; hub_handover?: boolean;
  // staff view
  settlement?: { commission_bps: number; commission_kobo: Kobo; rider_pay_kobo: Kobo; restaurant_earning_kobo: Kobo };
}

export interface OrderEvent {
  id: string; order_id: string; from_status: OrderStatus | null; to_status: OrderStatus; actor_type: string;
  actor_id: string; reason: string | null; at: string; metadata: Record<string, unknown>;
}

export interface Tracking {
  order_id: string; status: OrderStatus; rider_name: string | null;
  /** Only while a rider is on this delivery (the API enforces it). */
  rider_location: GeoPoint | null;
  eta_minutes: number | null; updated_at: string | null; estimated_delivery_at: string | null;
  /** "google" = measured with live traffic, "estimate" = Yummy Chops' own estimate. */
  eta_source?: MapSource | null;
  /** Current leg as a Google encoded polyline (decode with `decodePolyline`). */
  route_polyline?: string | null;
  pickup_location?: GeoPoint | null; dropoff_location?: GeoPoint | null;
}

export interface CheckoutResult {
  order_id: string; status: string; provider: string; reference: string;
  /** Null for wallet and pay-on-delivery checkouts (nothing to open). */
  authorization_url: string | null;
  amount_kobo: Kobo; payment_status?: string;
  /** Set when the default gateway was down and the backup gateway took the payment. */
  failover_from?: string;
}
/** `POST /v1/checkouts`: one payment covering several of the customer's orders (one per shop). */
export interface MultiCheckoutResult {
  order_ids: string[]; provider: string;
  /** The one payment covering all the orders; null for pay on delivery. */
  reference: string | null;
  /** Open this for card payments; null for wallet and pay on delivery. */
  authorization_url: string | null;
  amount_kobo: Kobo; currency: string;
  /** "succeeded" for wallet, "pending" for card and cash. */
  payment_status: string;
  orders: { order_id: string; status: string; amount_kobo: Kobo }[];
  failover_from?: string;
}
export interface PaymentView {
  id: string; order_id: string | null; /** "basket": one payment for several orders (one per shop); `order_id` is null. */
  purpose?: "order" | "basket" | "wallet_topup" | "plus" | "group_share"; provider: string; reference: string;
  amount_kobo: Kobo; status: string; paid_at: string | null; refunded_kobo: Kobo; created_at: string;
  failure_reason: string | null; channel: string | null;
}

export type PaymentMethodId = "card" | "wallet" | "cash";
export interface PaymentMethodOption {
  id: PaymentMethodId; label: string; available: boolean; reason: string | null;
  provider?: string; balance_kobo?: Kobo; short_by_kobo?: Kobo;
}
export interface PaymentOptions { order_id: string; total_kobo: Kobo; methods: PaymentMethodOption[] }

export interface WalletTransaction {
  id: string; kind: string; reference: string | null; order_id: string | null; description: string;
  created_at: string; direction: "in" | "out"; amount_kobo: Kobo;
}
export interface SellerSummary {
  cod_balance_kobo: Kobo; pending_payouts_kobo: Kobo; available_kobo: Kobo; min_payout_kobo: Kobo;
}
export interface WalletOverview {
  balance_kobo: Kobo; currency: "NGN"; enabled: boolean;
  limits: { min_topup_kobo: Kobo; max_topup_kobo: Kobo; max_balance_kobo: Kobo };
  refund_to_wallet: boolean; transactions: WalletTransaction[]; seller: SellerSummary | null;
}
export interface TopUpResult {
  provider: string; reference: string; authorization_url: string | null; amount_kobo: Kobo; failover_from?: string;
}
export interface SellerPayout {
  id: string; vendor_id: string; amount_kobo: Kobo; bank_name: string; account_number: string; account_name: string;
  status: "requested" | "paid" | "rejected"; reference: string | null; decision_note: string | null;
  requested_at: string; decided_at: string | null; paid_at: string | null;
}
export interface SellerOverview extends SellerSummary { transactions: WalletTransaction[]; payouts: SellerPayout[] }
export interface CashOverview {
  riders: { rider_id: string; name: string; phone: string | null; cash_held_kobo: Kobo; earnings_kobo: Kobo; over_limit: boolean }[];
  rider_cash_limit_kobo: Kobo;
  carriers?: { carrier_id: string; name: string; owed_kobo: Kobo }[];
  totals: { cash_with_riders_kobo: Kobo; wallet_balances_kobo: Kobo; seller_balances_kobo: Kobo; carrier_balances_kobo?: Kobo };
}

// ---------------------------------------------------------------- interstate waybill
export type WaybillStage =
  | "awaiting_dropoff" | "pickup_scheduled" | "picked_up" | "at_origin_hub" | "departed" | "at_destination_hub"
  | "out_for_delivery" | "ready_for_collection" | "delivered" | "cancelled";
export interface WaybillParty {
  name: string; phone: string; line1?: string | null; area?: string | null; location?: GeoPoint | null; instructions?: string | null;
}
export interface WaybillMilestone { stage: WaybillStage; at: string; hub_id: string | null; note: string | null }
export interface WaybillDetails {
  tracking_code: string | null; lane_id: string; carrier_id: string; carrier_name: string;
  origin_city: string; destination_city: string; origin_city_name: string; destination_city_name: string;
  origin_hub_id: string; destination_hub_id: string; origin_hub_name: string; destination_hub_name: string;
  destination_hub_address: string; destination_hub_hours: string;
  first_mile: "pickup" | "dropoff"; last_mile: "door" | "collect"; sender: WaybillParty; recipient: WaybillParty;
  size: ParcelSize; weight_kg: number; category: ParcelCategory; description: string;
  declared_value_kobo: Kobo | null; cod_amount_kobo: Kobo | null; eta_from: string; eta_to: string;
  stage: WaybillStage | null; milestones: WaybillMilestone[];
  first_mile_order_id: string | null; last_mile_order_id: string | null; trip_reference: string | null;
}
export interface WaybillQuoteRequest {
  origin_city: string; destination_city: string; first_mile: "pickup" | "dropoff"; last_mile: "door" | "collect";
  origin_hub_id?: string | null; destination_hub_id?: string | null; sender: WaybillParty; recipient: WaybillParty;
  size: ParcelSize; weight_kg: number; category?: ParcelCategory; description?: string;
  declared_value_kobo?: Kobo | null; cod_amount_kobo?: Kobo | null;
}
export interface WaybillQuote {
  id: string; details: WaybillDetails; breakdown: PriceBreakdown; pickup_km: number | null; delivery_km: number | null;
  created_at: string; expires_at: string; order_id: string | null; eta_text: string;
}
export interface WaybillHub {
  id: string; name: string; city: string; kind: "gm_hub" | "partner_terminal"; address: string; location: GeoPoint;
  phone: string; hours: string; accepts_dropoff: boolean; offers_collection: boolean; is_sample: boolean; city_name?: string;
}
export interface WaybillOrigin { id: string; name: string; state: string; home_pickup: boolean; dropoff_hubs: WaybillHub[] }
export interface WaybillDestination {
  city: string; name: string; state: string; door_delivery: boolean; transit_days: [number, number]; from_kobo: Kobo;
  carrier: string; collection_hubs: WaybillHub[];
}
export interface WaybillDestinations {
  origin: { id: string; name: string; home_pickup: boolean }; dropoff_hubs: WaybillHub[];
  destinations: WaybillDestination[]; max_kg_by_size: Record<ParcelSize, number>;
}
export interface WaybillTracking {
  tracking_code: string; origin: string; destination: string; stage: WaybillStage | null; label: string; step: number;
  steps: string[]; eta_from: string; eta_to: string; eta_text: string; last_mile: "door" | "collect";
  collection_point: { name: string; address: string; hours: string } | null;
  milestones: { stage: WaybillStage; label: string; at: string; place: string | null }[]; delivered: boolean;
}
export interface HubItem {
  order_id: string; tracking_code: string; status: OrderStatus; stage: WaybillStage | null; label: string;
  origin: string; destination: string; first_mile: "pickup" | "dropoff"; last_mile: "door" | "collect";
  size: ParcelSize; weight_kg: number; category: string; description: string;
  sender: { name: string; phone: string }; recipient: { name: string; phone: string };
  cod_amount_kobo: Kobo | null; carrier: string; trip_reference: string | null; eta_text: string; updated_at: string;
}
export interface HubBoard {
  hub: WaybillHub; expected: HubItem[]; at_hub: HubItem[]; incoming: HubItem[]; out_for_delivery: HubItem[];
  for_collection: HubItem[];
}

export interface Me {
  uid: string; email: string | null; phone: string | null; name: string | null; roles: string[];
  restaurant_roles: Record<string, "owner" | "manager" | "staff">; permissions: string[];
}
export interface CustomerProfile {
  uid: string; display_name: string | null; dietary: string[]; allergens: string[]; favourite_cuisines: string[];
  favourite_restaurant_ids: string[]; personalisation_consent: boolean; marketing_consent: boolean; loyalty_points: number;
  refund_to_wallet?: boolean; pay_on_delivery_blocked?: boolean;
}

export interface MealPlan {
  restaurant_id: string; restaurant_name: string; restaurant_rating: number;
  items: { item_id: string; name: string; kind: ItemKind; quantity: number; unit_total_kobo: Kobo; selection_labels: string[] }[];
  cart_lines: CartLine[]; breakdown: PriceBreakdown; distance_km: number; eta_minutes: number;
  estimated_delivery_at: string; meets_deadline: boolean; budget_remaining_kobo: Kobo; score: number; rationale: string[];
}
export interface MealPlanResult {
  plans: MealPlan[]; restaurants_considered: number; restaurants_eligible: number; cheapest_total_kobo: Kobo | null;
  notes: string[];
}

export interface Analytics {
  period_days: number; orders_total: number; orders_completed: number; gross_sales_kobo: Kobo; commission_kobo: Kobo;
  net_earnings_kobo: Kobo; average_order_kobo: Kobo; acceptance_rate: number | null; avg_prep_minutes: number | null;
  top_items: { name: string; quantity: number }[]; series: { date: string; orders: number; gross_kobo: Kobo }[];
  forecast_next_7_days_orders: number; top_restaurants?: { name: string; gross_kobo: Kobo }[];
}

export interface Overview {
  as_of: string; orders_today: number; orders_by_status: Record<string, number>; gmv_today_kobo: Kobo;
  platform_revenue_today_kobo: Kobo; active_orders: number;
  stuck_orders: { id: string; short_code: string; status: OrderStatus; minutes_since_update: number }[];
  riders_online: number; riders_busy: number; pending_applications: number; open_tickets: number;
  pending_refunds: number; flagged_payments: number;
}

export interface Application {
  id: string; type: "restaurant" | "rider"; applicant_uid: string; status: "submitted" | "in_review" | "approved" | "rejected";
  data: Record<string, unknown>; document_paths: string[]; submitted_at: string; decided_at: string | null;
  decision_reason: string | null; created_entity_id: string | null;
}

/** A rider's KYC (docs/adr/0027-rider-kyc.md). `nin` is masked except for the reviewing team. */
export type RiderKycStatus = "draft" | "submitted" | "needs_changes" | "verified" | "rejected";
export interface RiderKycDocumentState {
  label: string; uploaded: boolean; content_type: string | null; uploaded_at: string | null; needs_change: boolean;
}
export interface RiderKycGuarantor { name: string; phone: string; email: string; address: string; occupation: string }
export interface RiderKyc {
  uid: string; status: RiderKycStatus; full_name: string; whatsapp_phone: string; email: string; residential_address: string;
  permanent_address: string; nin: string; documents: Record<string, RiderKycDocumentState>; guarantors: RiderKycGuarantor[];
  submitted_at: string | null; reviewed_at: string | null; reviewed_by: string | null; review_note: string | null;
  changes_needed: string[]; missing: string[]; editable: boolean;
}
export interface RiderKycSummary {
  uid: string; full_name: string; whatsapp_phone: string; status: RiderKycStatus; submitted_at: string | null;
  nin: string; documents: number; missing: number;
}

export interface Refund {
  id: string; order_id: string; payment_id: string; amount_kobo: Kobo; reason: string; liability: string; stage: string;
  status: string; requested_by: string; decided_by: string | null; decision_note: string | null; created_at: string;
  /** "wallet" = refunded instantly into the customer's Yummy Chops wallet. */
  destination?: "original" | "wallet";
}

export interface SupportTicket {
  id: string; opened_by: string; order_id: string | null; category: string; description: string;
  missing_item_ids: string[]; status: string; priority: "low" | "normal" | "high" | "urgent"; channel: string;
  resolution: string | null; created_at: string; updated_at: string;
}

export interface RiderProfile {
  uid: string; name: string; phone: string | null; vehicle: "bicycle" | "motorcycle" | "car"; status: string;
  is_online: boolean; rating: number; acceptance_rate: number; active_order_ids: string[]; completed_deliveries: number;
  last_location: GeoPoint | null; last_location_at: string | null;
}

export interface AuditEvent {
  id: string; occurred_at: string; actor_id: string; actor_roles: string[]; action: string; resource_type: string;
  resource_id: string; details: Record<string, unknown>;
}

export interface LedgerOverview {
  trial_balance: { debits_kobo: Kobo; credits_kobo: Kobo };
  accounts: { account: string; type: string; balance_kobo: Kobo }[];
}

export interface Settlement {
  id: string; restaurant_id: string; period_start: string; period_end: string; orders_count: number; gross_kobo: Kobo;
  commission_kobo: Kobo; adjustments_kobo: Kobo; net_kobo: Kobo; status: string; payout_reference: string | null;
}

export interface PricingConfig {
  version: number; service_fee_bps: number; service_fee_min_kobo: Kobo; service_fee_max_kobo: Kobo;
  small_order_threshold_kobo: Kobo; small_order_fee_kobo: Kobo; vat_bps: number; default_commission_bps: number;
  delivery: { base_kobo: Kobo; per_km_kobo: Kobo; min_kobo: Kobo; max_kobo: Kobo; road_factor: string };
  rider_pay: { base_kobo: Kobo; per_km_kobo: Kobo; min_kobo: Kobo };
  avg_speed_kmh: string; dispatch_buffer_minutes: number;
  zones: { id: string; name: string; center: GeoPoint; radius_km: number; is_active: boolean; surge_bps: number }[];
  plus?: PlusPlanConfig;
}

export interface ChatCard { type: string; [key: string]: unknown }
export interface ChatApproval {
  type: "approval_required"; tool: string; tool_call_id: string;
  preview: { title: string; message?: string; order?: Record<string, unknown>; [key: string]: unknown };
}
export interface ChatResponse {
  thread_id: string; status: "completed" | "approval_required" | "blocked"; reply: string | null; agent: string | null;
  cards: ChatCard[]; approval: ChatApproval | null; warnings: string[];
}

// ------------------------------------------------------------------------------------- multi-service
export interface ServiceInfo {
  id: Vertical; name: string; tagline: string; available: boolean; merchants?: number;
  options?: string[]; coming_soon?: string[]; cities?: string[];
}
export interface BrowseCategory { id: string; name: string; emoji: string; merchants: number }
export interface PlaceArea { name: string; city: string; lat: number; lng: number }

export type ParcelSize = "small" | "medium" | "large";
export type ParcelCategory = "documents" | "clothing" | "electronics" | "food" | "cosmetics" | "household" | "other";
export interface ParcelStop {
  name: string; phone: string; line1: string; area?: string | null; city: string; location: GeoPoint; instructions?: string | null;
}
export interface ParcelDetails {
  pickup: ParcelStop; dropoff: ParcelStop; size: ParcelSize; category: ParcelCategory; description: string; city: string;
  /** Cash the rider collects from the recipient for the sender (vendor cash-on-delivery). */
  cod_amount_kobo?: Kobo | null;
}
export interface ParcelQuoteRequest {
  pickup: ParcelStop; dropoff: ParcelStop; size: ParcelSize; category: ParcelCategory; description?: string;
  scheduled_for?: string | null; cod_amount_kobo?: Kobo | null;
}
export interface ParcelQuote {
  id: string; details: ParcelDetails; breakdown: PriceBreakdown; distance_km: number; eta_minutes: number;
  estimated_delivery_at: string; scheduled_for: string | null; expires_at: string; order_id: string | null;
}
export interface OrderSummary {
  orders_count: number; completed_count: number; in_progress_count: number; total_spent_kobo: Kobo;
  this_month_spent_kobo: Kobo; refunded_kobo: Kobo; by_vertical: Record<Vertical, { orders: number; spent_kobo: Kobo }>;
  favourite_merchant: { id: string; name: string; orders: number } | null;
  first_order_at: string | null; last_order_at: string | null;
}
/** Support contacts from `/v1/config/public`. A contact that is not set up yet is an empty string (show it as
 * "coming soon"); `placeholders` is true while any of the three is missing (older app builds read only that). */
export interface SupportContacts { whatsapp: string; phone: string; email: string; hours: string; placeholders: boolean }

// ------------------------------------------------------------------------------------------ maps
/** Where a distance, time or place came from: Google (measured) or Yummy Chops' own estimate. */
export type MapSource = "google" | "estimate" | "local";
export type PlacePrecision = "rooftop" | "street" | "area" | "approximate";

export interface PlaceSuggestion {
  place_id: string; title: string; subtitle: string; distance_m: number | null; source: "google" | "local";
}

export interface PlaceResult {
  place_id: string | null; formatted_address: string; location: GeoPoint; area: string | null; city: string | null;
  precision: PlacePrecision; source: "google" | "local";
}

/** A place plus whether Yummy Chops delivers there. */
export interface PlaceLookup { place: PlaceResult; serviceable: boolean; zone: string | null; city: string | null }

export interface DeliveryEstimate {
  restaurant_id: string; name: string; area: string; road_distance_km: number; travel_minutes: number;
  eta_minutes: number; delivery_fee_kobo: Kobo | null; delivers: boolean; is_open: boolean; source: "google" | "estimate";
}

export interface RestaurantLocation {
  restaurant_id: string; address: string; area: string; city: string; location: GeoPoint; delivery_radius_km: number;
  zone: string | null; in_service_area: boolean; maps_provider: "google" | "local";
}

export interface RestaurantLocationUpdate {
  address: string; location: GeoPoint; area?: string | null; place_id?: string | null;
  /** Keep the pin even though the address check suggests another spot. */
  confirm_pin?: boolean;
  /** Staff only. */
  delivery_radius_km?: number;
}

export interface LiveRider {
  rider_id: string; name: string; vehicle: string; location: GeoPoint | null; located_at: string | null;
  /** Idle riders are only ever known to about 1 km. */
  precision: "precise" | "coarse"; on_delivery: boolean; active_order_ids: string[]; zone_id: string | null;
}

export interface MapsStatus {
  provider: "google" | "local"; routes: "google" | "estimate"; traffic_aware: boolean; live_eta_refresh_seconds: number;
  requests_today: number; daily_cap: number;
}

// ------------------------------------------------------------------------------------- growth (phase 4)
export interface PlusPlanConfig {
  enabled: boolean; price_kobo: Kobo; period_days: number; free_delivery_min_subtotal_kobo: Kobo;
  service_fee_discount_bps: number; verticals: string[]; points_multiplier: number; renew_window_hours: number;
}
export interface PlusPlan {
  enabled: boolean; price_kobo: Kobo; vat_kobo: Kobo; period_days: number; free_delivery_min_subtotal_kobo: Kobo;
  service_fee_discount_bps: number; points_multiplier: number; verticals: string[];
  /** Ready-to-show benefit lines, e.g. "Free delivery on Food and Beauty orders of ₦3,000 or more". */
  benefits: string[];
}
export interface PlusMembership {
  status: "active" | "expired"; member_since: string; paid_through: string; paid_through_text: string;
  days_left: number; auto_renew: boolean; can_renew: boolean; periods: number; savings_kobo: Kobo;
}
export interface PlusOverview { plan: PlusPlan; member: boolean; membership: PlusMembership | null }
export interface PlusSubscribeResult extends PlusOverview { payment: TopUpResult & { payment_status?: string } }

export interface RewardVoucher {
  code: string; description: string; value_kobo: Kobo; min_subtotal_kobo: Kobo; ends_at: string | null;
  source: "campaign" | "points" | "referral" | "referrer";
}
export interface PointsEntry {
  id: string; kind: "earned" | "redeemed" | "reversed"; points: number; order_id: string | null;
  voucher_code: string | null; note: string; at: string;
}
export interface RewardsOverview {
  points: number; lifetime_points: number; points_value_kobo: Kobo;
  redeem: {
    enabled: boolean; step_points: number; step_value_kobo: Kobo; redeemable_points: number; points_to_next: number;
    min_subtotal_kobo: Kobo; valid_days: number;
  };
  earn: { points_per_100_naira: number; plus_multiplier: number; member: boolean };
  referral: {
    enabled: boolean; code: string; friend_gets_kobo: Kobo; you_get_kobo: Kobo; min_subtotal_kobo: Kobo;
    friends_rewarded: number; applied: boolean; can_apply: boolean; share_text: string;
  };
  vouchers: RewardVoucher[];
  history: PointsEntry[];
}

export type GroupStatus = "open" | "locked" | "ordered" | "cancelled" | "expired";
export type SplitMode = "host" | "each";
export interface GroupMemberView {
  uid: string; name: string; is_host: boolean; me: boolean; ready: boolean; items: number; items_kobo: Kobo;
}
export interface GroupLineView {
  id: string; member_uid: string; member: string; item_id: string; name: string; quantity: number;
  selections: { group_id: string; choice_ids: string[] }[]; options: string[]; notes: string | null;
  line_total_kobo: Kobo; problem: string | null;
}
export interface GroupShareView {
  uid: string; name: string; me: boolean; items_kobo: Kobo; amount_kobo: Kobo; status: "unpaid" | "paid";
  paid_by_host: boolean;
}
export interface GroupOrder {
  id: string; code: string; status: GroupStatus; split_mode: SplitMode; is_host: boolean; host_name: string;
  restaurant: { id: string; name: string }; vertical: Vertical; fulfillment: Fulfillment; delivery_area: string | null;
  members: GroupMemberView[]; max_members: number; lines: GroupLineView[]; estimated_items_kobo: Kobo;
  expires_at: string;
  order: { id: string; short_code: string; status: OrderStatus; total_kobo: Kobo; breakdown: PriceBreakdown } | null;
  total_kobo: Kobo; shares: GroupShareView[];
  my_share: { amount_kobo: Kobo; items_kobo: Kobo; status: "unpaid" | "paid" } | null;
  paid_kobo: Kobo; remaining_kobo: Kobo; pay_by: string | null; can_pay: boolean; can_cover_rest: boolean;
  cancel_reason: string | null;
}
export interface GroupCreateRequest {
  restaurant_id: string; fulfillment: Fulfillment; delivery_address?: DeliveryAddress | null; split_mode: SplitMode;
}
export interface GroupPayResult { payment: TopUpResult & { payment_status?: string }; group: GroupOrder }

export interface GrowthConfig {
  version: number;
  points_enabled: boolean; points_per_100_naira: number; point_value_kobo: Kobo; redeem_step_points: number;
  redeem_min_subtotal_kobo: Kobo; redeem_valid_days: number;
  referrals_enabled: boolean; referee_reward_kobo: Kobo; referee_min_subtotal_kobo: Kobo; referrer_reward_kobo: Kobo;
  referrer_monthly_cap: number; referral_valid_days: number;
  group_orders_enabled: boolean; group_max_members: number; group_open_hours: number;
}
export interface GrowthStats {
  plus: { active_members: number; auto_renew_on: number; ending_in_7_days: number; revenue_kobo: Kobo; plan: PlusPlan };
  rewards: {
    points_outstanding: number; points_outstanding_value_kobo: Kobo; customers_with_points: number;
    referred_customers: number; referrals_rewarded: number;
    vouchers: Record<string, { issued: number; used: number; value_issued_kobo: Kobo }>;
  };
}

// ------------------------------------------------------------------------------------- WhatsApp (phase 5)
export interface WhatsAppStatus {
  /** False until Yummy Chops' WhatsApp Business number is live. */
  enabled: boolean;
  linked: boolean;
  /** Masked, e.g. "+234 801 ••• 1111". */
  number: string | null;
  linked_at: string | null;
  business_number: string;
  /** wa.me link to chat with Yummy once linked. */
  chat_link: string | null;
}
export interface WhatsAppLinkCode {
  code: string;
  expires_at: string;
  business_number: string;
  /** wa.me link that pre-fills "LINK <code>". */
  wa_link: string;
}

// ------------------------------------------------------------------------------------- receipts (ADR-0019)
export interface ReceiptLine { name: string; quantity: number; amount_kobo: Kobo; details: string[] }
/** A fee, tax or discount row; a discount is negative. */
export interface ReceiptCharge { label: string; amount_kobo: Kobo }
/** What the customer paid for one order. `saved` is true once they have printed it (kept under "My receipts"). */
export interface Receipt {
  id: string; number: string; order_id: string; order_code: string; customer_id: string; customer_name: string | null;
  service: Vertical; service_name: string; seller: string; seller_address: string;
  /** Packages: the route, the size and the tracking number. */
  summary: string[];
  lines: ReceiptLine[]; charges: ReceiptCharge[]; total_kobo: Kobo; savings_kobo: Kobo; refunded_kobo: Kobo;
  paid_with: string; payment_reference: string | null; paid_at: string | null; ordered_at: string; issued_at: string;
  printed_at: string | null; print_count: number; saved: boolean;
}

// ------------------------------------------------------------------------------------- businesses (ADR-0028)
export interface BusinessBranch {
  restaurant_id: string; branch_name: string | null; address: string; area: string; location: GeoPoint;
  manager_phone: string | null; main: boolean; status: "pending" | "active" | "suspended"; is_accepting_orders: boolean;
}
/** A business: its unique ID (YCB-XXXXXX), its branches and the bank account split payments go to. Only the
 * account's last four digits are kept. */
export interface Business {
  id: string; name: string; owner_uid: string; vertical: MerchantVertical; phone: string | null; email: string | null;
  main_restaurant_id: string; settlement_bank_code: string | null; settlement_bank_name: string | null;
  settlement_account_name: string | null; settlement_account_last4: string | null; created_at: string;
  bank_connected: boolean; branches: BusinessBranch[];
}
export interface MyBusinesses {
  businesses: Business[];
  /** The owner's shops that are not in a business yet: each can get a business ID. */
  without_business: { restaurant_id: string; name: string; address: string; area: string }[];
}
export interface BranchInput {
  branch_name?: string | null; address: string; area?: string; location: GeoPoint; manager_phone?: string | null;
}
export interface Bank { code: string; name: string }

/** The answer to a menu spreadsheet (services/menu_tools.py): what would change, or what changed. */
export interface MenuImportRow {
  row: number;
  name: string;
  category: string;
  price_kobo: number | null;
  action: "create" | "update" | "unchanged" | "error";
  error: string | null;
  changes: string[];
}

export interface MenuImportResult {
  applied: boolean;
  created: number;
  updated: number;
  unchanged: number;
  errors: number;
  new_categories: string[];
  rows: MenuImportRow[];
}
