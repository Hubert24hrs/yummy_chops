"""Yummy offline: a deterministic, rule-based stand-in for the LLM.

Used when no Gemini key is configured (and usable as an emergency fallback). It implements the same ModelFactory
protocol as Gemini, so it runs inside the normal graph — guard → router → agent ⇄ tools — and every action still
goes through tool validation, role permissions, rate limits, audit and the in-app approval screen. It never invents
prices: all numbers in its replies are copied from tool results.

Language: replies fully in English or Nigerian Pidgin; for Igbo, Yoruba and Hausa it greets and acknowledges in the
customer's language and gives details in English (full multilingual conversation needs the Gemini model).
"""

from __future__ import annotations

import json
import re
import unicodedata
import uuid
from typing import Any, Literal

from langchain_core.messages import AIMessage, AnyMessage, HumanMessage, SystemMessage, ToolMessage

from .agents import RouteDecision

Lang = Literal["en", "pcm", "ig", "yo", "ha"]

# ------------------------------------------------------------------------------------------------ language
_LANG_MARKERS: dict[Lang, re.Pattern[str]] = {
    "ig": re.compile(r"\b(biko|ndewo|kedu|nri|achoro|daalu|ego ole|nwanne|ehee|nyere m|ka m)\b"),
    "yo": re.compile(
        r"\b(e jowo|ejowo|jowo|bawo|ekaaro|e kaaro|ekasan|ounje|mo fe|mo n fe|e se|oluwa|e kaabo)\b"
    ),
    "ha": re.compile(r"\b(sannu|don allah|nagode|ina kwana|abinci|ina so|ina son|yaya|wallahi)\b"),
    "pcm": re.compile(
        r"\b(abeg|wetin|dey|una|wahala|oya|sef|abi|how far|make i|i wan|wan|no be|don|chop|wey|dem|sabi)\b"
    ),
}


def plain(text: str) -> str:
    """Lower-case ASCII folding (drops accents) so 'Ẹ jọ̀wọ́' matches 'e jowo'."""
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()


def detect_language(text: str) -> Lang:
    p = plain(text)
    scores = {lang: len(rx.findall(p)) for lang, rx in _LANG_MARKERS.items()}
    best = max(scores, key=lambda k: scores[k])
    return best if scores[best] else "en"


GREETING: dict[Lang, str] = {
    "en": "Hi{name}! I'm Yummy, your Yummy Chops assistant.",
    "pcm": "How far{name}! Na me be Yummy, your Yummy Chops paddy.",
    "ig": "Ndewo{name}! Abụ m Yummy.",
    "yo": "Ẹ n lẹ{name}! Èmi ni Yummy.",
    "ha": "Sannu{name}! Ni ne Yummy.",
}
ACK: dict[Lang, str] = {"en": "", "pcm": "", "ig": "Ọ dị mma. ", "yo": "Ó dáa. ", "ha": "To, shi ke nan. "}
SORRY: dict[Lang, str] = {
    "en": "Sorry, ",
    "pcm": "Sorry o, ",
    "ig": "Ndo, ",
    "yo": "Ẹ má bínú, ",
    "ha": "Yi haƙuri, ",
}
ENGLISH_NOTE = " (I'll reply in English for now.)"

T: dict[str, dict[str, str]] = {
    "intro": {
        "en": "I can find food, groceries, pharmacy items, market foodstuff and beauty products, plan a meal within "
        "your budget, send packages across Lagos and "
        "Enugu, track your orders and tell you how much you've spent. What would you like?",
        "pcm": "I fit find better food, groceries, pharmacy things, market foodstuff and beauty things for you, plan "
        "food wey go fit your budget, send package for "
        "Lagos and Enugu, track your order, and tell you how much you don spend. Wetin you wan do?",
    },
    "services": {
        "en": "Here's what Yummy Chops does in Lagos and Enugu:",
        "pcm": "See wetin Yummy Chops dey do for Lagos and Enugu:",
    },
    "coming_soon": {"en": "Coming soon: {items}.", "pcm": "E dey come soon: {items}."},
    "totals": {
        "en": "You've paid for {n} order(s) on Yummy Chops: {total} in total ({month} this month).",
        "pcm": "You don pay for {n} order(s) for Yummy Chops, total na {total} ({month} this month).",
    },
    "totals_none": {
        "en": "You haven't placed any orders yet. Shall I find you something nice?",
        "pcm": "You never order anything yet. Make I find something sweet for you?",
    },
    "favourite": {"en": "Your favourite: {name}.", "pcm": "Your favourite na {name}."},
    "refunded": {"en": "Refunds received: {amount}.", "pcm": "Refund wey you don collect: {amount}."},
    "plans": {
        "en": "Here are {n} option(s) within your budget:",
        "pcm": "See {n} option(s) wey fit your budget:",
    },
    "plans_pick": {
        "en": "Reply 'plan 1' (or 2, 3) and I'll order it for you.",
        "pcm": "Reply 'plan 1' (or 2, 3) make I order am for you.",
    },
    "plans_none": {
        "en": "I couldn't build a meal within that budget right now.",
        "pcm": "I no fit arrange food wey fit that budget now.",
    },
    "draft": {
        "en": "Order {code} from {restaurant}: {items}. Total {total} (delivery {delivery}, service {service}, VAT "
        "{vat}). Say 'confirm' and I'll create your secure payment link.",
        "pcm": "Your order {code} from {restaurant} don ready: {items}. Total na {total} (delivery {delivery}, "
        "service {service}, VAT {vat}). Talk 'confirm' make I bring the payment link.",
    },
    "paylink": {
        "en": "Here's your secure payment link for {amount}. Yummy Chops starts your order as soon as the payment is "
        "verified.",
        "pcm": "Correct! Na your secure payment link be this for {amount}. Once the payment land, we go start your "
        "order.",
    },
    "declined": {"en": "No problem, I haven't done it.", "pcm": "No wahala, I no do am."},
    "found": {"en": "Here's what I found:", "pcm": "See wetin I find:"},
    "found_none": {
        "en": "I couldn't find that. Try another name, or browse Order Food, Pharmacy, Beauty & Skin Care, Shop & "
        "Groceries or Buy Foodstuff.",
        "pcm": "I no see am o. Try another name, or check Order Food, Pharmacy, Beauty & Skin Care, Shop & Groceries "
        "or Buy Foodstuff.",
    },
    "found_next": {
        "en": "Open the store to add items to your cart.",
        "pcm": "Open the store make you add am to your cart.",
    },
    "status": {
        "en": "Order {code} from {restaurant}: {label}.",
        "pcm": "Your order {code} from {restaurant}: {label}.",
    },
    "eta": {"en": "Expected around {time}.", "pcm": "E go reach around {time}."},
    "no_orders": {"en": "You don't have any orders yet.", "pcm": "You never get any order yet."},
    "parcel": {
        "en": "To send a package, tap the button and fill in pickup and drop-off. You'll see the exact price before "
        "you pay.",
        "pcm": "To send package, tap the button, fill pickup and drop-off. You go see the correct price before you "
        "pay.",
    },
    "support": {
        "en": "You can reach Yummy Chops support {ways} ({hours}). Or chat with our team in the Support tab.",
        "pcm": "You fit reach Yummy Chops support {ways} ({hours}). Or chat with our team for the Support tab.",
    },
    # Only the contacts that exist are listed (the API leaves the others empty), joined with "or".
    "support_whatsapp": {"en": "on WhatsApp {v}", "pcm": "for WhatsApp {v}"},
    "support_phone": {"en": "by phone on {v}", "pcm": "for phone {v}"},
    "support_email": {"en": "by email at {v}", "pcm": "for email {v}"},
    "support_tab_only": {
        "en": "Chat with our team in the Support tab: a person replies in the app.",
        "pcm": "Chat with our team for the Support tab: person go reply you for the app.",
    },
    "support_placeholder": {
        "en": "More ways to reach us are coming soon, so the Support tab is the fastest way to reach a person.",
        "pcm": "More ways to reach us dey come soon, so Support tab na the fastest way to reach person.",
    },
    "ticket": {
        "en": "I've opened support ticket {id}. A Yummy Chops specialist will reply in the app.",
        "pcm": "I don open support ticket {id}. Person from Yummy Chops go reply you for the app.",
    },
    "nearby": {
        "en": "Places that deliver to {near} ({order}):",
        "pcm": "See places wey fit deliver reach {near} ({order}):",
    },
    "nearby_none": {
        "en": "I couldn't find a place that delivers to {near} with that. Try allowing more time or another cuisine.",
        "pcm": "I no see place wey fit deliver reach {near} with that one. Try give am more time or another food.",
    },
    "nearby_note": {
        "en": "Times and delivery fees are estimates; checkout shows the exact price.",
        "pcm": "The time and delivery fee na estimate; checkout go show the correct price.",
    },
    "button": {"en": "Tap the button below.", "pcm": "Tap the button wey dey below."},
    "wallet": {
        "en": "Your Yummy Chops wallet balance is {balance}.",
        "pcm": "Money wey dey your Yummy Chops wallet na {balance}.",
    },
    "wallet_cod": {
        "en": "Cash-on-delivery money collected for you: {amount}.",
        "pcm": "Cash-on-delivery money wey we collect for you: {amount}.",
    },
    "wallet_topup": {
        "en": "To top up, open your wallet (Profile → Yummy Chops wallet). I can't move money myself.",
        "pcm": "To top up, open your wallet (Profile → Yummy Chops wallet). I no fit move money by myself.",
    },
    "pod": {
        "en": "Yes: pay on delivery lets you pay the rider in cash for restaurant and shop orders once you've completed "
        "your first order (limits apply). Choose 'Pay on delivery' at checkout and Yummy Chops checks if your order "
        "qualifies.",
        "pcm": "Yes o: you fit pay the rider cash for restaurant and shop orders once you don complete your first order "
        "(limit dey). Choose 'Pay on delivery' for checkout, Yummy Chops go check if your order qualify.",
    },
    "cod": {
        "en": "Selling online? When you send a package, tick 'Collect cash from my buyer'. The rider collects the price "
        "at drop-off and it shows in your wallet: move it to your wallet instantly or withdraw it to your bank.",
        "pcm": "You dey sell online? When you dey send package, tick 'Collect cash from my buyer'. Rider go collect the "
        "money for drop-off, e go show for your wallet: move am enter wallet sharp sharp or withdraw am go your bank.",
    },
    "pay_options": {"en": "How you can pay order total {total}:", "pcm": "How you fit pay for {total}:"},
    "waybill_routes": {
        "en": "From {origin} we send packages to:",
        "pcm": "From {origin} we dey send package go:",
    },
    "waybill_book": {
        "en": "Prices are from-prices; the app shows your exact total. Tap the button to book.",
        "pcm": "Na from-price be dis; the app go show your correct total. Tap the button make you book.",
    },
    "waybill_track": {
        "en": "Waybill {code} ({route}): {status}. Expected {eta}.",
        "pcm": "Waybill {code} ({route}): {status}. E go reach {eta}.",
    },
    "waybill_done": {
        "en": "Waybill {code} ({route}): {status}.",
        "pcm": "Waybill {code} ({route}): {status}.",
    },
    "waybill_collect": {"en": "Collect it at {place}.", "pcm": "Make dem collect am for {place}."},
    "waybill_none": {"en": "You don't have any waybills yet.", "pcm": "You never send any waybill yet."},
    "plus_member": {
        "en": "You're a Yummy Chops Plus member until {until}. Auto-renew from your wallet is {renew}. You've saved "
        "{saved} so far.",
        "pcm": "You be Yummy Chops Plus member till {until}. Auto-renew from your wallet dey {renew}. You don save "
        "{saved} so far.",
    },
    "plus_join": {
        "en": "Yummy Chops Plus costs {price}:",
        "pcm": "Yummy Chops Plus na {price}:",
    },
    "plus_tap": {"en": "Tap the button to join.", "pcm": "Tap the button make you join."},
    "rewards_points": {
        "en": "You have {points} Yummy points (worth {worth}). You earn {rate}.",
        "pcm": "You get {points} Yummy points (e worth {worth}). You dey earn {rate}.",
    },
    "rewards_ready": {
        "en": "You can turn {points} points into vouchers now on the Rewards screen ({rule}).",
        "pcm": "You fit change {points} points to voucher now for Rewards screen ({rule}).",
    },
    "rewards_next": {
        "en": "{left} more points to your next {worth} voucher.",
        "pcm": "{left} more points remain for your next {worth} voucher.",
    },
    "rewards_referral": {
        "en": "Your referral code is {code}: friends get {friend} off their first order and you get {you} when "
        "it's done.",
        "pcm": "Your referral code na {code}: your padi go get {friend} off for their first order, you go get "
        "{you} when e finish.",
    },
    "rewards_vouchers": {"en": "Your vouchers:", "pcm": "Your vouchers:"},
    "group_none": {
        "en": "You're not in any group orders right now. Open a Food or Beauty store and tap 'Order with "
        "friends', then share the code.",
        "pcm": "You no dey any group order now. Open one Food or Beauty store, tap 'Order with friends', then "
        "share the code.",
    },
    "group_list": {"en": "Your group orders:", "pcm": "Your group orders:"},
    "unknown": {
        "en": "I didn't quite get that. You can ask me for food, groceries, pharmacy items, market foodstuff, beauty "
        "products, package delivery, your order status "
        "or how much you've spent.",
        "pcm": "I no too understand. You fit ask me for food, groceries, pharmacy things, market foodstuff, beauty "
        "things, package delivery, your order status or "
        "how much you don spend.",
    },
    "error": {"en": "{message}", "pcm": "{message}"},
}


def say(key: str, lang: Lang, **kw: Any) -> str:
    variants = T[key]
    text = variants["pcm"] if lang == "pcm" else variants["en"]
    return text.format(**kw)


# ------------------------------------------------------------------------------------------------ intents
_YES = re.compile(
    r"^(yes|yeah|yep|yup|ok(ay)?|sure|go ahead|do it|proceed|confirm|place (it|the order)|order (it|am)|oya|"
    r"abeg do am|ehen|i agree|pay|let'?s go|e se|ese|nagode|daalu|biko)\b"
)
_NO = re.compile(r"^(no|nope|cancel( that)?|don'?t|leave it|forget it|no be am|no need)\b")
_PLAN_PICK = re.compile(
    r"\b(?:plan|option|number)\s*[-#]?\s*(\d)\b|\bthe (first|second|third) (one|option|plan)\b"
)
_ORDER_NOW = re.compile(r"\b(order (it|am|for me|now)|place (the |an |my )?order|buy it|book it|and order)\b")
_TOTALS = re.compile(
    r"\b(total|totals|spent|spend|spending|how much (have|did) i|i don spend|my (order )?history|summary|ego ole)\b"
)
_SERVICES = re.compile(
    r"\b(services?|what (do|can) (you|yummy ?chops?) (do|offer|sell)|wetin (una|you) dey (do|sell)|what you offer|"
    r"what do you offer)\b"
)
_TRACK = re.compile(r"\b(where is my|where my|track|tracking|status|rider|eta|don reach|dey come|my order)\b")
_PARCEL = re.compile(
    r"\b(package|parcel|courier|dispatch rider|waybill|send (a|my|this|some|am)\b|deliver (a|my|this) "
    r"(package|item|parcel|box))"
)
_SUPPORT = re.compile(
    r"\b(human|agent|customer care|support|complain|complaint|problem|issue|wahala|refund|talk to (someone|a "
    r"person)|help me with my order)\b"
)
_OPEN = re.compile(
    r"\b(open|go to|take me to|show me)\s+(the\s+|my\s+)?(food|groceries|grocery|pharmacy|market|beauty|packages?|"
    r"parcel|orders?|support|profile|"
    r"discover|home|wallet|rewards|plus)\b"
)
_WALLET = re.compile(r"\b(wallet|my balance|top ?up|fund my account)\b")
_PLUS = re.compile(
    r"\b(yummy ?chops? plus|plus member(ship)?|membership|subscription|subscribe|free delivery)\b"
)
_REWARDS = re.compile(
    r"\b(yummy points|my points|points|rewards?|referr?al( code)?|refer|invite (a |my )?friends?|my vouchers?|"
    r"my coupons?)\b"
)
_GROUP = re.compile(
    r"\b(group orders?|order (with|for) (my )?(friends|colleagues|team|office)|split (the |our )?bill|"
    r"order together)\b"
)
_TRACKING_CODE = re.compile(r"\bgmw[2-9a-hj-np-z]{8}\b")
_WAYBILL = re.compile(
    r"\b(waybill|interstate|another state|other states?|another city|outside (lagos|enugu))\b"
)
_WAYBILL_CITY = re.compile(r"\b(?:to|for|go)\s+(lagos|enugu|abuja|port harcourt|portharcourt|ph)\b")
_MY_WAYBILL = re.compile(r"\b(where is|track|status of|wetin happen to) (my )?(waybill|interstate)")
_SELLER_COD = re.compile(
    r"\b(collect (the )?(cash|money|payment) from (my )?(buyer|customer)s?|cash on delivery for (vendors?|sellers?)|"
    r"(vendor|seller) cod|i (sell|dey sell) online)\b"
)
_PAY_ON_DELIVERY = re.compile(
    r"\b(pay on delivery|pay(ing)? (with |in )?cash|cash on delivery|pay when (it|e|the food|my order) "
    r"(arrives?|reach(es)?|comes?)|pay for door|payment on delivery|how (can|do) i pay|payment (methods?|options?))\b"
)
_GREET = re.compile(
    r"^(hi|hello|hey|good (morning|afternoon|evening)|how far|ndewo|kedu|bawo|e kaaro|ekaaro|sannu|ina kwana|"
    r"hiya|howdy)\b"
)
_HELP = re.compile(r"^(help|what can you do|who are you|menu)\b")
_NEAR = re.compile(
    r"\b(near ?by|near me|near here|close to me|close by|closest|nearest|around me|around here|in my area|"
    r"for my area|dey near|wey near)\b"
)
_FAST = re.compile(r"\b(fastest|quickest|soonest|shortest wait)\b")
_PLACE = re.compile(
    r"\b(restaurants?|kitchens?|places?|spots?|shops?|stores?|bukka|buka|joints?|vendors?|food|chop|deliver\w*)\b"
)
_MINE = re.compile(r"\b(my order|my rider|my food|my package|where is my|where my)\b")
_WITHIN = re.compile(r"\b(?:in|under|within|less than|below)\s+(\d{2,3})\s*(?:min|mins|minutes)\b")
_STARS = re.compile(r"\b([1-5](?:\.\d)?)\s*\+?\s*stars?\b")
_CHEAP = re.compile(r"\b(cheap|cheaper|budget|affordable|not expensive|low ?cost)\b")
_SORTS = (
    ("fastest", re.compile(r"\b(fastest|quickest|soonest|shortest wait)\b")),
    ("best_rated", re.compile(r"\b(best|top|highest|highly)[ -]rated\b|\bbest\b")),
    ("cheapest_delivery", re.compile(r"\b(cheapest|free|lowest|low) delivery\b")),
)
_SORT_LABEL = {
    "fastest": "quickest first",
    "closest": "closest first",
    "best_rated": "best rated first",
    "cheapest_delivery": "cheapest delivery first",
}


def nearby_args(text: str) -> dict[str, Any] | None:
    """find_nearby_restaurants arguments for a 'near me' / 'fastest' question, or None if it isn't one."""
    p = plain(text)
    if (
        _MINE.search(p)
        or _PARCEL.search(p)
        or not (_NEAR.search(p) or (_FAST.search(p) and _PLACE.search(p)))
    ):
        return None
    if parse_budget(text):  # an amount means a meal plan within that budget
        return None
    args: dict[str, Any] = {"service": _nearby_service(p)}
    args["sort_by"] = next((sort for sort, rx in _SORTS if rx.search(p)), "closest")
    within = _WITHIN.search(p)
    if within:
        args["max_minutes"] = max(10, min(180, int(within.group(1))))
    stars = _STARS.search(p)
    if stars:
        args["min_rating"] = float(stars.group(1))
    if _CHEAP.search(p):
        args["max_price_level"] = 2
    food = _keyword(text, _FOOD)
    if food and food not in _GENERIC_FOOD and args["service"] == "food":
        args["query"] = food
    return args


_BEAUTY = re.compile(
    r"\b(serum|sunscreen|spf|moisturi[sz]er|cream|lotion|shea|black soap|soap|lipstick|foundation|powder|perfume|"
    r"fragrance|body mist|edge control|conditioner|shampoo|beard|toner|skincare|skin care|make ?up|cosmetics|"
    r"body butter|body oil|hair oil|scalp|curl|bonnet|chebe|castor oil)\b"
)
# Shop products (ADR-0018). Only words that are clearly a product: "rice" or "yam" alone still means a meal.
_PHARMACY = re.compile(
    r"\b(paracetamol|panadol|ibuprofen|vitamin c|multivitamins?|vitamins?|cough syrup|antacid|plasters?|bandages?|"
    r"antiseptic|thermometer|condoms?|sanitary pads?|lozenges?|nasal spray|eye drops|rehydration salts?|"
    r"first aid|mosquito repellent|pharmacy|chemist|medicines?)\b"
)
_GROCERY = re.compile(
    r"\b(bottled water|pack of water|milk|bread|eggs?|sugar|indomie|corn ?flakes|cereal|toilet (paper|rolls?)|"
    r"tissue|detergent|bleach|diapers?|baby wipes|toothpaste|soft drinks?|malt|juice|butter|margarine|mayonnaise|"
    r"ketchup|vegetable oil|groundnut oil|semovita|seasoning cubes?|tin(ned)? tomato(es)?|sardines?|corned beef|"
    r"biscuits?|groceries|grocery|supermarket)\b"
)
_MARKET = re.compile(
    r"\b(derica|garri|tatashe|rodo|fresh tomato(es)?|fresh pepper|ugwu|ugu|waterleaf|bitter ?leaf|crayfish|"
    r"stockfish|okporoko|iru|palm oil|raw (beef|chicken|goat meat|meat|fish)|tubers? of yam|soup combo|"
    r"foodstuffs?|market shopping|market)\b"
)
# Words that name a whole service, not a product: open the service instead of searching for the word.
_GENERIC_SHOP = {
    "pharmacy": "pharmacy",
    "chemist": "pharmacy",
    "medicine": "pharmacy",
    "medicines": "pharmacy",
    "first aid": "pharmacy",
    "groceries": "grocery",
    "grocery": "grocery",
    "supermarket": "grocery",
    "foodstuff": "market",
    "foodstuffs": "market",
    "market shopping": "market",
    "market": "market",
}
_SHOPS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("pharmacy", _PHARMACY),
    ("grocery", _GROCERY),
    ("market", _MARKET),
)


def _nearby_service(p: str) -> str:
    """Which kind of place a 'near me' question is about."""
    for service, rx in _SHOPS:
        if rx.search(p):
            return service
    return "beauty" if _BEAUTY.search(p) else "food"


_FOOD = re.compile(
    r"\b(jollof|fried rice|ofada|rice|suya|shawarma|pizza|burger|chicken|amala|egusi|efo|soup|pepper ?soup|swallow|"
    r"pounded yam|fufu|eba|small chops|puff ?puff|moi ?moi|plantain|dodo|beans|yam|chapman|zobo|smoothie|abacha|"
    r"nkwobi|okpa|meat ?pie|pasta|spaghetti|wings|catfish|gizzard|kilishi|asun|isi ewu|onugbu|oha|ogbono|"
    r"afang|edikang ikong|bole|noodles|salad|food|meal|lunch|dinner|breakfast|chop|hungry|nri|ounje|abinci)\b"
)
_BUDGET = re.compile(
    r"(?:₦|\bngn|\bn(?=\s*[0-9])|\bnaira)\s*([0-9][0-9,.]*)\s*(k\b)?|\b([0-9][0-9,.]*)\s*(k|naira|thousand)\b"
)
_DEADLINE = re.compile(r"\b(?:before|by|latest)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b")
_NUMBER_WORDS = {
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
}
_PARTY = re.compile(
    r"\bfor (\d{1,2}|one|two|three|four|five|six|seven|eight|nine|ten)\b(?:\s+(?:people|persons|of us|pple))?|"
    r"\b(\d{1,2}|one|two|three|four|five|six|seven|eight|nine|ten)\s+(?:people|persons)\b"
)
_ORDINAL = {"first": 1, "second": 2, "third": 3}
_SCREEN_WORDS = {
    "food": "food",
    "groceries": "grocery",
    "grocery": "grocery",
    "pharmacy": "pharmacy",
    "market": "market",
    "beauty": "beauty",
    "package": "parcel",
    "packages": "parcel",
    "parcel": "parcel",
    "order": "orders",
    "orders": "orders",
    "support": "support",
    "profile": "profile",
    "discover": "discover",
    "home": "home",
    "wallet": "wallet",
    "rewards": "rewards",
    "plus": "plus",
}


def parse_budget(text: str) -> int | None:
    m = _BUDGET.search(text.lower())
    if not m:
        return None
    raw, suffix = (m.group(1), m.group(2)) if m.group(1) else (m.group(3), m.group(4))
    try:
        value = float(raw.replace(",", ""))
    except ValueError:
        return None
    if suffix in ("k", "thousand"):
        value *= 1000
    return int(value) if 100 <= value <= 1_000_000 else None


def parse_party(text: str) -> int:
    m = _PARTY.search(plain(text))
    if not m:
        return 1
    token = m.group(1) or m.group(2)
    n = _NUMBER_WORDS.get(token) if not token.isdigit() else int(token)
    return max(1, min(10, n or 1))


def parse_deadline(text: str) -> str | None:
    m = _DEADLINE.search(plain(text))
    if not m:
        return None
    hour, minute, ampm = int(m.group(1)), int(m.group(2) or 0), m.group(3)
    if ampm == "pm" and hour < 12:
        hour += 12
    elif ampm == "am" and hour == 12:
        hour = 0
    elif ampm is None and 1 <= hour <= 9:
        hour += 12  # "before 8" at meal times means 8pm
    if not (0 <= hour <= 23 and 0 <= minute <= 59):
        return None
    return f"{hour:02d}:{minute:02d}"


def _keyword(text: str, rx: re.Pattern[str]) -> str | None:
    m = rx.search(plain(text))
    return m.group(0) if m else None


_GENERIC_FOOD = frozenset(
    {"food", "meal", "lunch", "dinner", "breakfast", "chop", "hungry", "nri", "ounje", "abinci"}
)


# ------------------------------------------------------------------------------------------------ model
class OfflineModels:
    """ModelFactory implementation (see llm.py)."""

    model_name = "gudy-offline"
    deterministic_routing = True  # the graph uses keyword routing instead of asking a model

    def for_tools(self, tools: list[dict[str, Any]]) -> _OfflineAgent:
        return _OfflineAgent({t["function"]["name"] for t in tools})

    def for_structured(self, schema: type) -> _NoRouter:
        return _NoRouter()


class _NoRouter:
    async def ainvoke(self, messages: Any, config: Any = None, **_: Any) -> RouteDecision:
        raise RuntimeError("offline mode routes by keywords")


def _call(name: str, args: dict[str, Any]) -> AIMessage:
    return AIMessage(
        content="", tool_calls=[{"name": name, "args": args, "id": f"offline_{uuid.uuid4().hex[:12]}"}]
    )


def _payload(msg: ToolMessage) -> dict[str, Any]:
    try:
        body = json.loads(msg.content if isinstance(msg.content, str) else str(msg.content))
    except ValueError:
        return {}
    return body if isinstance(body, dict) else {}


class _OfflineAgent:
    def __init__(self, tools: set[str]) -> None:
        self.tools = tools

    async def ainvoke(self, messages: list[AnyMessage], config: Any = None, **_: Any) -> AIMessage:
        system = next((m for m in messages if isinstance(m, SystemMessage)), None)
        human_idx = max((i for i, m in enumerate(messages) if isinstance(m, HumanMessage)), default=-1)
        text = str(messages[human_idx].content) if human_idx >= 0 else ""
        lang = detect_language(text)
        name = _first_name(system)
        turn_results = [m for m in messages[human_idx + 1 :] if isinstance(m, ToolMessage)]
        if turn_results:
            return self._after_tools(turn_results, text, lang)
        return self._first_step(messages[:human_idx], text, lang, name)

    # -------------------------------------------------------------------------- deciding what to do
    def _can(self, tool: str) -> bool:
        return tool in self.tools

    def _first_step(self, history: list[AnyMessage], text: str, lang: Lang, name: str) -> AIMessage:
        p = plain(text).strip()

        # Follow-ups to the latest thing Yummy offered that is still open (a plan, a draft or a parcel quote).
        offer, prev = _latest_offer(history)
        data = prev.get("data") or {}
        pick = _PLAN_PICK.search(p)
        if pick:
            plans_tool, plans = _latest(history, {"plan_meal_within_budget"})
            if plans_tool and (plans.get("data") or {}).get("plans") and self._can("create_order_draft"):
                n = int(pick.group(1)) if pick.group(1) else _ORDINAL.get(pick.group(2) or "", 1)
                return _call("create_order_draft", {"plan_ref": f"plan-{n}"})
        if offer and (_YES.match(p) or _ORDER_NOW.search(p)):
            if offer == "plan_meal_within_budget" and data.get("plans") and self._can("create_order_draft"):
                return _call("create_order_draft", {"plan_ref": data["plans"][0]["plan_ref"]})
            if offer == "create_order_draft" and data.get("order_id") and self._can("confirm_order"):
                return _call("confirm_order", {"order_id": data["order_id"]})
            if offer == "get_parcel_quote" and data.get("quote_id") and self._can("book_parcel"):
                return _call("book_parcel", {"quote_id": data["quote_id"]})
        if offer and _NO.match(p):
            return AIMessage(content=ACK[lang] + say("declined", lang))

        # New requests.
        if _GREET.match(p) or _HELP.match(p):
            intro = GREETING[lang].format(name=f" {name}" if name else "")
            note = ENGLISH_NOTE if lang in ("ig", "yo", "ha") else ""
            return AIMessage(content=f"{intro} {say('intro', lang)}{note}")
        nearby = nearby_args(text)
        if nearby and self._can("find_nearby_restaurants"):
            return _call("find_nearby_restaurants", nearby)
        screen = _OPEN.search(p)
        if screen and self._can("open_screen"):
            return _call("open_screen", {"screen": _SCREEN_WORDS[screen.group(3)]})
        code = _TRACKING_CODE.search(p)
        if code and self._can("track_waybill"):
            return _call("track_waybill", {"tracking_code": code.group(0).upper()})
        if _MY_WAYBILL.search(p) and self._can("track_waybill"):
            return _call("track_waybill", {})
        city = _WAYBILL_CITY.search(p)
        if (_WAYBILL.search(p) or (city and _PARCEL.search(p))) and self._can("get_waybill_options"):
            return _call("get_waybill_options", {"destination": city.group(1)} if city else {})
        if (
            city
            and city.group(1) in ("abuja", "port harcourt", "portharcourt", "ph")
            and self._can("get_waybill_options")
        ):
            return _call("get_waybill_options", {"destination": city.group(1)})
        if _SELLER_COD.search(p):
            if self._can("open_screen"):
                return _call("open_screen", {"screen": "parcel"})
            return AIMessage(content=say("cod", lang))
        if _GROUP.search(p) and self._can("get_group_orders"):
            return _call("get_group_orders", {})
        if _PLUS.search(p) and self._can("get_plus_membership"):
            return _call("get_plus_membership", {})
        if _REWARDS.search(p) and self._can("get_rewards"):
            return _call("get_rewards", {})
        if _WALLET.search(p) and self._can("get_wallet"):
            return _call("get_wallet", {})
        if _PAY_ON_DELIVERY.search(p):
            last_order = (
                _latest(history, {"create_order_draft", "reorder", "confirm_order"})[1].get("data") or {}
            )
            if last_order.get("order_id") and self._can("get_payment_options"):
                return _call("get_payment_options", {"order_id": last_order["order_id"]})
            return AIMessage(content=ACK[lang] + say("pod", lang))
        if _TOTALS.search(p) and self._can("get_order_totals"):
            return _call("get_order_totals", {})
        if _SERVICES.search(p) and self._can("list_services"):
            return _call("list_services", {})
        budget = parse_budget(text)
        if budget and not _BEAUTY.search(p) and self._can("plan_meal_within_budget"):
            args: dict[str, Any] = {"budget_naira": budget, "party_size": parse_party(text)}
            deadline = parse_deadline(text)
            if deadline:
                args["deliver_before"] = deadline
            return _call("plan_meal_within_budget", args)
        if _PARCEL.search(p) and self._can("open_screen"):
            return _call("open_screen", {"screen": "parcel"})
        if _TRACK.search(p):
            if self._can("get_delivery_tracking") and re.search(r"\b(rider|track|tracking|eta|where)\b", p):
                return _call("get_delivery_tracking", {})
            if self._can("get_order_status"):
                return _call("get_order_status", {})
        if _SUPPORT.search(p) and self._can("get_support_contacts"):
            return _call("get_support_contacts", {})
        beauty = _keyword(text, _BEAUTY)
        if beauty and self._can("search_food_items"):
            return _call("search_food_items", {"query": beauty, "service": "beauty"})
        for service, rx in _SHOPS:
            word = _keyword(text, rx)
            if not word:
                continue
            if word in _GENERIC_SHOP:
                if self._can("open_screen"):
                    return _call("open_screen", {"screen": _GENERIC_SHOP[word]})
            elif self._can("search_food_items"):
                return _call("search_food_items", {"query": word, "service": service})
        food = _keyword(text, _FOOD)
        if food and food not in _GENERIC_FOOD and self._can("search_food_items"):
            return _call("search_food_items", {"query": food, "service": "food"})
        if food and self._can("open_screen"):
            return _call("open_screen", {"screen": "food"})
        return AIMessage(content=say("unknown", lang))

    # -------------------------------------------------------------------------- after tools ran
    def _after_tools(self, results: list[ToolMessage], text: str, lang: Lang) -> AIMessage:
        last = results[-1]
        tool = last.name or ""
        body = _payload(last)
        p = plain(text)
        if "error" in body:
            message = (body["error"] or {}).get("message", "something went wrong")
            return AIMessage(content=SORRY[lang] + message[0].lower() + message[1:])
        if body.get("declined"):
            return AIMessage(content=ACK[lang] + say("declined", lang))
        data = body.get("data") or {}

        # Chain the vision flow in one turn: "… for two, order it" → plan → draft → approval screen.
        if tool == "plan_meal_within_budget" and data.get("plans") and _ORDER_NOW.search(p):
            if self._can("create_order_draft"):
                return _call("create_order_draft", {"plan_ref": data["plans"][0]["plan_ref"]})
        if tool == "create_order_draft" and data.get("order_id") and self._can("confirm_order"):
            if _ORDER_NOW.search(p) or _PLAN_PICK.search(p) or _YES.match(p.strip()):
                return _call("confirm_order", {"order_id": data["order_id"]})

        return AIMessage(content=ACK[lang] + render(tool, data, lang, p))


_WALLET_TOPUP = re.compile(r"\b(top ?up|fund|add money|load)\b")


def render(tool: str, data: dict[str, Any], lang: Lang, text: str = "") -> str:
    """Turn a tool result into a short reply. Numbers are copied verbatim from the tool output."""
    if tool == "list_services":
        lines = [say("services", lang)]
        for s in data.get("services", []):
            lines.append(f"• {s['name']}: {s['what_it_is']}")
        soon = next((s.get("coming_soon") for s in data.get("services", []) if s.get("coming_soon")), None)
        if soon:
            pretty = ", ".join(x.replace("_", " ") for x in soon)
            lines.append(say("coming_soon", lang, items=pretty))
        return "\n".join(lines)
    if tool == "get_order_totals":
        if not data.get("paid_orders"):
            return say("totals_none", lang)
        lines = [
            say(
                "totals",
                lang,
                n=data["paid_orders"],
                total=data["total_spent"],
                month=data["spent_this_month"],
            )
        ]
        for service, v in (data.get("by_service") or {}).items():
            lines.append(f"• {service}: {v['orders']} order(s), {v['spent']}")
        if data.get("refunded"):
            lines.append(say("refunded", lang, amount=data["refunded"]))
        if data.get("favourite"):
            lines.append(say("favourite", lang, name=data["favourite"]))
        return "\n".join(lines)
    if tool == "plan_meal_within_budget":
        plans = data.get("plans") or []
        if not plans:
            extra = (
                f" Cheapest possible: {data['cheapest_possible_total']}."
                if data.get("cheapest_possible_total")
                else ""
            )
            return say("plans_none", lang) + extra
        lines = [say("plans", lang, n=len(plans))]
        for i, plan in enumerate(plans, start=1):
            items = ", ".join(plan["items"])
            eta = f", arrives around {plan['arrives_around']}" if plan.get("arrives_around") else ""
            lines.append(f"{i}. {plan['restaurant']}: {items}. Total {plan['total']}{eta}.")
        lines.append(say("plans_pick", lang))
        return "\n".join(lines)
    if tool in ("create_order_draft", "reorder"):
        return say(
            "draft",
            lang,
            code=data.get("short_code"),
            restaurant=data.get("restaurant"),
            items=", ".join(data.get("items") or []),
            total=data.get("total"),
            delivery=data.get("delivery_fee"),
            service=data.get("service_fee"),
            vat=data.get("vat"),
        )
    if tool in ("confirm_order", "book_parcel"):
        return say("paylink", lang, amount=data.get("amount"))
    if tool == "search_food_items":
        items = data.get("items") or []
        if not items:
            return say("found_none", lang)
        lines = [say("found", lang)]
        for it in items[:5]:
            lines.append(f"• {it['name']}: {it['price']} at {it['restaurant']}")
        lines.append(say("found_next", lang))
        return "\n".join(lines)
    if tool == "find_nearby_restaurants":
        near = data.get("near") or "your address"
        rows = data.get("restaurants") or []
        if not rows:
            return say("nearby_none", lang, near=near)
        lines = [
            say("nearby", lang, near=near, order=_SORT_LABEL.get(data.get("sorted_by", ""), "closest first"))
        ]
        for r in rows:
            bits = [
                f"about {r['eta_minutes']} min" if r.get("eta_minutes") is not None else None,
                f"{r['road_distance_km']} km away" if r.get("road_distance_km") is not None else None,
                f"delivery {r['delivery_fee']}" if r.get("delivery_fee") else None,
                f"rated {r['rating']}",
            ]
            lines.append(f"• {r['name']} ({r['area']}): " + ", ".join(b for b in bits if b))
        lines.append(say("nearby_note", lang))
        return "\n".join(lines)
    if tool == "compare_delivery_times":
        rows = data.get("comparison") or []
        lines = [f"{r['name']}: about {r['eta_minutes']} min, {r['road_distance_km']} km away" for r in rows]
        if data.get("fastest"):
            lines.insert(0, f"Fastest to {data.get('near') or 'you'}: {data['fastest']}.")
        lines.append(say("nearby_note", lang))
        return "\n".join(lines)
    if tool in ("get_order_status", "get_delivery_tracking"):
        if data.get("message") == "No orders yet" or not data:
            return say("no_orders", lang)
        code = data.get("short_code") or data.get("order_id", "")
        label = data.get("status_label") or data.get("status", "")
        out = say("status", lang, code=code, restaurant=data.get("restaurant", "Yummy Chops"), label=label)
        eta = data.get("estimated_arrival") or data.get("eta")
        if eta:
            out += " " + say("eta", lang, time=eta)
        return out
    if tool == "open_screen":
        if data.get("shown_button") == "Send a package":
            return say("cod", lang) if _SELLER_COD.search(text) else say("parcel", lang)
        return say("button", lang)
    if tool == "get_plus_membership":
        if data.get("member"):
            return say(
                "plus_member",
                lang,
                until=data.get("member_until"),
                renew="on" if data.get("auto_renew_from_wallet") else "off",
                saved=data.get("saved_so_far"),
            )
        lines = [say("plus_join", lang, price=data.get("price"))]
        lines += [f"• {b}" for b in data.get("benefits") or []]
        lines.append(say("plus_tap", lang))
        return "\n".join(lines)
    if tool == "get_rewards":
        lines = [
            say(
                "rewards_points",
                lang,
                points=data.get("points"),
                worth=data.get("points_worth"),
                rate=data.get("earn_rate"),
            )
        ]
        if data.get("redeemable_points"):
            lines.append(
                say("rewards_ready", lang, points=data["redeemable_points"], rule=data.get("redeem_rule"))
            )
        else:
            lines.append(
                say(
                    "rewards_next",
                    lang,
                    left=data.get("points_to_next_reward"),
                    worth=data.get("next_reward_worth"),
                )
            )
        lines.append(
            say(
                "rewards_referral",
                lang,
                code=data.get("referral_code"),
                friend=data.get("friend_gets"),
                you=data.get("you_get"),
            )
        )
        if data.get("vouchers"):
            lines.append(say("rewards_vouchers", lang))
            lines += [
                f"• {v['code']}: {v['worth']} off orders from {v['min_order']}" for v in data["vouchers"]
            ]
        return "\n".join(lines)
    if tool == "get_group_orders":
        rows = data.get("group_orders") or []
        if not rows:
            return say("group_none", lang)
        lines = [say("group_list", lang)]
        for g in rows:
            extra = f", code {g['join_code']}" if g.get("join_code") else ""
            share = f", your share {g['your_share']}" if g.get("your_share") else ""
            lines.append(f"• {g['store']}: {g['status']}{extra}{share}")
        return "\n".join(lines)
    if tool == "get_wallet":
        lines = [say("wallet", lang, balance=data.get("balance"))]
        for t in (data.get("recent") or [])[:3]:
            lines.append(f"• {t['what']}: {t['amount']}")
        if data.get("cash_on_delivery_balance"):
            lines.append(say("wallet_cod", lang, amount=data["cash_on_delivery_balance"]))
        if _WALLET_TOPUP.search(text):
            lines.append(say("wallet_topup", lang))
        return "\n".join(lines)
    if tool == "get_waybill_options":
        if data.get("same_city") or data.get("available") is False:
            return data.get("message", "")
        lines = [say("waybill_routes", lang, origin=data.get("from"))]
        for d in data.get("destinations") or []:
            how = (
                "door delivery"
                if d.get("door_delivery")
                else "collect at " + ", ".join(d.get("collection_points") or [])
            )
            lines.append(f"• {d['to']}: from {d['price_from']}, {d['transit']} ({how})")
        lines.append(say("waybill_book", lang))
        return "\n".join(lines)
    if tool == "track_waybill":
        if data.get("message") == "No waybills yet":
            return say("waybill_none", lang)
        out = say(
            "waybill_done" if data.get("delivered") else "waybill_track",
            lang,
            code=data.get("tracking_code"),
            route=data.get("route"),
            status=data.get("status"),
            eta=data.get("expected"),
        )
        if data.get("collection_point"):
            out += " " + say("waybill_collect", lang, place=data["collection_point"])
        return out
    if tool == "get_payment_options":
        lines = [say("pay_options", lang, total=data.get("order_total"))]
        for m in data.get("methods") or []:
            mark = "✓" if m.get("available") else "✗"
            why = f" ({m['why_not']})" if m.get("why_not") else ""
            lines.append(f"{mark} {m['method']}{why}")
        return "\n".join(lines)
    if tool == "get_support_contacts":
        ways = [say(f"support_{k}", lang, v=data[k]) for k in ("whatsapp", "phone", "email") if data.get(k)]
        if not ways:
            return say("support_tab_only", lang)
        joined = ways[0] if len(ways) == 1 else ", ".join(ways[:-1]) + " or " + ways[-1]
        out = say("support", lang, ways=joined, hours=data.get("hours"))
        if data.get("note"):
            out += " " + say("support_placeholder", lang)
        return out
    if tool == "create_support_ticket":
        return say("ticket", lang, id=data.get("ticket_id"))
    return say("button", lang) if data.get("shown_button") else "Done."


_OFFERS = {"plan_meal_within_budget", "create_order_draft", "get_parcel_quote", "reorder"}
_CLOSERS = {"confirm_order", "book_parcel", "cancel_order"}


def _latest(history: list[AnyMessage], names: set[str]) -> tuple[str | None, dict[str, Any]]:
    """The most recent successful result of one of `names` (errors and declined approvals are skipped)."""
    for msg in reversed(history):
        if isinstance(msg, ToolMessage) and msg.name in names:
            payload = _payload(msg)
            if "error" not in payload and not payload.get("declined"):
                return msg.name, payload
    return None, {}


def _latest_offer(history: list[AnyMessage]) -> tuple[str | None, dict[str, Any]]:
    """The latest open offer; an offer is closed once it was confirmed/booked/cancelled or explicitly declined."""
    for msg in reversed(history):
        if not isinstance(msg, ToolMessage):
            continue
        payload = _payload(msg)
        if msg.name in _CLOSERS or payload.get("declined"):
            return None, {}
        if msg.name in _OFFERS and "error" not in payload:
            name = "create_order_draft" if msg.name == "reorder" else msg.name
            return name, payload
    return None, {}


def _first_name(system: SystemMessage | None) -> str:
    if system is None:
        return ""
    m = re.search(r"Signed-in user: ([^;\n]+);", str(system.content))
    name = (m.group(1).strip() if m else "") or ""
    return "" if name.lower() in ("customer", "none") else name.split()[0]


__all__ = [
    "OfflineModels",
    "detect_language",
    "nearby_args",
    "parse_budget",
    "parse_deadline",
    "parse_party",
    "render",
]
