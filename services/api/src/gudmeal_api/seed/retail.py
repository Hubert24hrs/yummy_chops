"""Demo catalog for Shop & Groceries, Pharmacy and Buy Foodstuff (ADR-0018, names from ADR-0025).

Laid out the way shoppers already know from Nigerian delivery apps: a shop has aisles, each aisle has products with
a size or market measure, a price and an in-stock switch; some products have choices ("From ₦..."); markets also
sell ready-made soup combos. Every business here is invented and products carry no real brand names. Pharmacies
list over-the-counter products only; the one prescription-only entry exists to prove it stays hidden and unsold.
Prices are realistic for 2026 (naira in the tables, stored as kobo).
"""

from __future__ import annotations

from ..domain.models import (
    ItemKind,
    MenuCategory,
    MenuItem,
    OptionChoice,
    OptionGroup,
    Restaurant,
    Vertical,
    Voucher,
)
from ..domain.money import naira
from ..repositories import Repositories
from .expansion import Menu, _hours, _i, _m

# A product row: code, aisle id, name, size or measure, price in naira, picture placeholder, popularity, tags.
Row = tuple[str, str, str, str | None, int, str, int, tuple[str, ...]]

# ------------------------------------------------------------------------------------------------ supermarkets
GROCERY_AISLES: list[tuple[str, str]] = [
    ("drinks", "Soft drinks & water"),
    ("cupboard", "Food cupboard"),
    ("condiments", "Cooking & condiments"),
    ("dairy", "Dairy & eggs"),
    ("bakery", "Bakery"),
    ("snacks", "Snacks & sweets"),
    ("fresh", "Fresh & frozen"),
    ("toiletries", "Toiletries"),
    ("household", "Household"),
    ("baby", "Baby & toddler"),
]

GROCERY_ROWS: list[Row] = [
    ("water-75x12", "drinks", "Table water", "75 cl × 12", 2700, "💧", 320, ("water",)),
    ("water-50x12", "drinks", "Table water", "50 cl × 12", 2300, "💧", 300, ("water",)),
    ("cola-50", "drinks", "Cola", "50 cl bottle", 500, "🥤", 260, ("soft drink", "mineral")),
    ("orange-soda-50", "drinks", "Orange soda", "50 cl bottle", 500, "🥤", 150, ("soft drink", "mineral")),
    ("malt-33x6", "drinks", "Malt drink", "33 cl × 6", 3600, "🥫", 190, ("malt",)),
    ("juice-1l", "drinks", "Orange juice", "1 L pack", 2200, "🧃", 170, ("juice",)),
    ("energy-25", "drinks", "Energy drink", "25 cl can", 900, "⚡", 110, ("energy drink",)),
    ("rice-5kg", "cupboard", "Long grain parboiled rice", "5 kg", 9800, "🍚", 280, ("rice",)),
    ("rice-1kg", "cupboard", "Long grain parboiled rice", "1 kg", 2200, "🍚", 160, ("rice",)),
    ("spaghetti-500", "cupboard", "Spaghetti", "500 g", 1100, "🍝", 210, ("pasta",)),
    ("noodles-5", "cupboard", "Instant noodles", "70 g × 5", 1700, "🍜", 250, ("noodles",)),
    ("semolina-1kg", "cupboard", "Semolina", "1 kg", 2100, "🌾", 90, ("swallow",)),
    ("sugar-1kg", "cupboard", "Granulated sugar", "1 kg", 2900, "🍬", 120, ("sugar",)),
    ("cornflakes-350", "cupboard", "Cornflakes", "350 g", 3800, "🥣", 140, ("cereal",)),
    ("oats-500", "cupboard", "Rolled oats", "500 g", 3200, "🥣", 95, ("cereal", "oats")),
    ("veg-oil-3l", "condiments", "Vegetable oil", "3 L", 9500, "🍶", 200, ("oil",)),
    ("tomato-paste-10", "condiments", "Tomato paste sachets", "70 g × 10", 2500, "🍅", 230, ("tomato",)),
    ("seasoning-50", "condiments", "Seasoning cubes", "pack of 50", 1900, "🧂", 240, ("seasoning",)),
    ("mayonnaise-500", "condiments", "Mayonnaise", "500 g", 4500, "🥫", 80, ("mayonnaise",)),
    ("ketchup-340", "condiments", "Tomato ketchup", "340 g", 2600, "🍅", 70, ("ketchup",)),
    ("milk-powder-400", "dairy", "Milk powder refill", "400 g", 5600, "🥛", 220, ("milk",)),
    ("evap-milk-160", "dairy", "Evaporated milk", "160 g tin", 800, "🥛", 180, ("milk",)),
    ("yoghurt-1l", "dairy", "Plain yoghurt", "1 L", 3500, "🥛", 100, ("yoghurt",)),
    ("eggs", "dairy", "Fresh eggs", "half crate (15)", 3200, "🥚", 270, ("eggs",)),
    ("butter-250", "dairy", "Butter", "250 g", 3900, "🧈", 85, ("butter", "margarine")),
    ("bread-sliced", "bakery", "Sliced bread", "family loaf", 1800, "🍞", 290, ("bread",)),
    ("bread-wheat", "bakery", "Wheat bread", "loaf", 2000, "🍞", 130, ("bread",)),
    ("biscuits-400", "snacks", "Digestive biscuits", "400 g", 2400, "🍪", 150, ("biscuits",)),
    ("plantain-chips", "snacks", "Plantain chips", "150 g", 1200, "🍌", 175, ("chips",)),
    ("chocolate-100", "snacks", "Milk chocolate bar", "100 g", 1900, "🍫", 125, ("chocolate",)),
    ("groundnuts-250", "snacks", "Roasted groundnuts", "250 g", 1500, "🥜", 105, ("nuts",)),
    ("chicken-1kg", "fresh", "Frozen chicken laps", "1 kg", 6500, "🍗", 215, ("chicken", "frozen")),
    ("franks-340", "fresh", "Chicken franks", "340 g", 3200, "🌭", 115, ("sausage", "frozen")),
    ("apples-4", "fresh", "Apples", "pack of 4", 2600, "🍎", 135, ("fruit",)),
    ("carrots-500", "fresh", "Carrots", "500 g", 1500, "🥕", 90, ("vegetable",)),
    ("ice-cream-1l", "fresh", "Vanilla ice cream", "1 L tub", 5200, "🍨", 145, ("ice cream", "frozen")),
    ("toothpaste-140", "toiletries", "Toothpaste", "140 g", 1800, "🦷", 185, ("toothpaste",)),
    ("bath-soap-3", "toiletries", "Bath soap", "pack of 3", 2100, "🧼", 195, ("soap",)),
    ("pads-10", "toiletries", "Sanitary pads", "pack of 10", 1500, "🌸", 165, ("pads",)),
    ("lotion-400", "toiletries", "Body lotion", "400 ml", 4200, "🧴", 110, ("lotion",)),
    ("tissue-12", "household", "Toilet tissue", "12 rolls", 4800, "🧻", 255, ("tissue",)),
    ("detergent-900", "household", "Washing powder", "900 g", 2900, "🧺", 205, ("detergent",)),
    ("dish-soap-750", "household", "Dishwashing liquid", "750 ml", 2200, "🧽", 140, ("dish soap",)),
    ("bleach-1l", "household", "Bleach", "1 L", 1700, "🧴", 95, ("bleach",)),
    ("insecticide-300", "household", "Insecticide spray", "300 ml", 2800, "🦟", 120, ("insecticide",)),
    ("diapers-m-44", "baby", "Baby diapers, medium", "pack of 44", 9800, "🍼", 190, ("diapers",)),
    ("baby-wipes-80", "baby", "Baby wipes", "80 wipes", 1900, "🧻", 160, ("wipes",)),
    ("baby-cereal-400", "baby", "Baby cereal", "400 g", 4300, "🥣", 100, ("baby food",)),
]

# -------------------------------------------------------------------------------------------------- pharmacies
PHARMACY_AISLES: list[tuple[str, str]] = [
    ("pain", "Pain & fever"),
    ("cold", "Cough, cold & allergy"),
    ("stomach", "Stomach & digestion"),
    ("vitamins", "Vitamins & supplements"),
    ("firstaid", "First aid"),
    ("baby", "Mother & baby"),
    ("family", "Family planning & tests"),
    ("personal", "Personal care"),
    ("devices", "Health devices"),
]

PHARMACY_ROWS: list[Row] = [
    ("paracetamol-12", "pain", "Paracetamol 500 mg tablets", "12 tablets", 300, "💊", 330, ("pain", "fever")),
    ("ibuprofen-24", "pain", "Ibuprofen 200 mg tablets", "24 tablets", 900, "💊", 210, ("pain",)),
    (
        "para-syrup-100",
        "pain",
        "Children's paracetamol syrup",
        "100 ml",
        1100,
        "🧴",
        190,
        ("fever", "children"),
    ),
    ("pain-balm-30", "pain", "Pain relief balm", "30 g", 1200, "🧴", 120, ("muscle pain",)),
    ("lozenges-24", "cold", "Cough lozenges", "pack of 24", 900, "🍬", 230, ("cough", "sore throat")),
    ("cough-syrup-100", "cold", "Cough syrup", "100 ml", 1800, "🧴", 170, ("cough",)),
    ("loratadine-10", "cold", "Loratadine 10 mg tablets", "10 tablets", 1200, "💊", 130, ("allergy",)),
    ("nasal-spray-30", "cold", "Saline nasal spray", "30 ml", 2500, "💧", 85, ("blocked nose",)),
    ("ors-5", "stomach", "Oral rehydration salts", "5 sachets", 700, "💧", 200, ("ors", "diarrhoea")),
    ("antacid-24", "stomach", "Antacid tablets", "24 tablets", 1400, "💊", 150, ("heartburn",)),
    (
        "vitamin-c-20",
        "vitamins",
        "Vitamin C 1000 mg effervescent",
        "20 tablets",
        3500,
        "🍊",
        290,
        ("vitamin c",),
    ),
    ("multivitamin-30", "vitamins", "Multivitamin tablets", "30 tablets", 4200, "💊", 220, ("multivitamin",)),
    ("cod-liver-100", "vitamins", "Cod liver oil capsules", "100 capsules", 6500, "🐟", 110, ("omega 3",)),
    ("folic-acid-28", "vitamins", "Folic acid 5 mg tablets", "28 tablets", 600, "💊", 140, ("pregnancy",)),
    ("plasters-20", "firstaid", "Adhesive plasters", "pack of 20", 800, "🩹", 180, ("plaster",)),
    ("antiseptic-250", "firstaid", "Antiseptic liquid", "250 ml", 2400, "🧴", 240, ("antiseptic",)),
    ("spirit-100", "firstaid", "Methylated spirit", "100 ml", 600, "🧴", 160, ("spirit",)),
    ("cotton-wool-100", "firstaid", "Cotton wool", "100 g", 700, "☁️", 125, ("cotton wool",)),
    ("bandage", "firstaid", "Crepe bandage", "7.5 cm × 4.5 m", 900, "🩹", 75, ("bandage",)),
    ("sanitiser-250", "firstaid", "Hand sanitiser", "250 ml", 1800, "🧴", 145, ("sanitiser",)),
    ("nappy-cream-50", "baby", "Nappy rash cream", "50 g", 2300, "🧴", 135, ("baby",)),
    ("gripe-water-150", "baby", "Gripe water", "150 ml", 1900, "🍼", 155, ("baby", "colic")),
    ("diapers-s-40", "baby", "Baby diapers, small", "pack of 40", 8900, "🍼", 115, ("diapers",)),
    ("condoms-3", "family", "Condoms", "pack of 3", 700, "🛡️", 205, ("family planning",)),
    ("pregnancy-test", "family", "Pregnancy test strip", "1 test", 500, "🧪", 185, ("pregnancy test",)),
    ("pads-10", "family", "Sanitary pads", "pack of 10", 1500, "🌸", 165, ("pads",)),
    ("toothpaste-140", "personal", "Toothpaste", "140 g", 1800, "🦷", 100, ("toothpaste",)),
    ("mouthwash-250", "personal", "Mouthwash", "250 ml", 2600, "🧴", 80, ("mouthwash",)),
    ("petroleum-jelly-100", "personal", "Petroleum jelly", "100 g", 1300, "🧴", 150, ("vaseline", "skin")),
    ("thermometer", "devices", "Digital thermometer", "1 piece", 3500, "🌡️", 175, ("thermometer",)),
    ("face-masks-50", "devices", "Face masks", "box of 50", 3000, "😷", 90, ("masks",)),
    ("bp-monitor", "devices", "Blood pressure monitor", "upper arm", 28000, "🩺", 95, ("blood pressure",)),
]

# Prescription-only: partners may record it, but customers never see it and it can never be ordered.
PRESCRIPTION_ROWS: list[Row] = [
    ("amoxicillin-500", "cold", "Amoxicillin 500 mg capsules", "15 capsules", 2500, "💊", 0, ("antibiotic",)),
]

# ----------------------------------------------------------------------------------------------------- markets
MARKET_AISLES: list[tuple[str, str]] = [
    ("combos", "Soup & stew combos"),
    ("grains", "Rice, grains & garri"),
    ("vegetables", "Pepper & vegetables"),
    ("tubers", "Tubers & plantain"),
    ("meat", "Meat (raw)"),
    ("fish", "Fish & seafood"),
    ("chicken", "Chicken & turkey"),
    ("fruits", "Fruits"),
    ("spices", "Oil, spices & seasoning"),
]

MARKET_ROWS: list[Row] = [
    ("garri-derica", "grains", "Ijebu garri", "derica", 600, "🌾", 260, ("garri",)),
    ("garri-half-paint", "grains", "Ijebu garri", "half paint", 2400, "🌾", 180, ("garri",)),
    ("rice-derica", "grains", "Local rice (stone-free)", "derica", 1500, "🍚", 240, ("rice", "ofada")),
    ("rice-half-paint", "grains", "Local rice (stone-free)", "half paint", 6000, "🍚", 170, ("rice",)),
    ("beans-derica", "grains", "Honey beans (oloyin)", "derica", 1800, "🥜", 215, ("beans",)),
    ("beans-half-paint", "grains", "Brown beans", "half paint", 6800, "🥜", 120, ("beans",)),
    ("egusi-derica", "grains", "Egusi (ground)", "derica", 3500, "🥜", 205, ("egusi", "melon")),
    ("elubo-half-paint", "grains", "Yam flour (elubo)", "half paint", 6000, "🌾", 95, ("amala", "elubo")),
    ("ogbono-cup", "grains", "Ogbono (ground)", "small cup", 2500, "🥜", 110, ("ogbono",)),
    ("tomatoes-half-paint", "vegetables", "Tomatoes", "half paint", 4000, "🍅", 300, ("tomato",)),
    ("rodo-portion", "vegetables", "Rodo (scotch bonnet)", "portion", 500, "🌶️", 285, ("pepper", "ata rodo")),
    ("tatashe-half-paint", "vegetables", "Tatashe", "half paint", 5000, "🌶️", 190, ("pepper",)),
    ("onions-3", "vegetables", "Onions", "3 medium", 500, "🧅", 275, ("onion",)),
    ("ugwu-bunch", "vegetables", "Ugwu (pumpkin leaves)", "bunch", 500, "🥬", 250, ("ugu", "vegetable")),
    ("okro-half-paint", "vegetables", "Okro", "half paint", 3000, "🥒", 160, ("okra",)),
    ("ewedu-bunch", "vegetables", "Ewedu", "bunch", 300, "🥬", 130, ("ewedu",)),
    ("spinach-bunch", "vegetables", "Spinach (efo tete)", "bunch", 400, "🥬", 140, ("efo", "vegetable")),
    ("garden-egg", "vegetables", "Garden egg", "portion", 1200, "🍆", 85, ("garden egg",)),
    ("ginger-garlic", "vegetables", "Ginger and garlic", "portion", 800, "🧄", 150, ("ginger", "garlic")),
    ("yam-tuber", "tubers", "Yam", "1 medium tuber", 5000, "🍠", 265, ("yam",)),
    ("sweet-potato", "tubers", "Sweet potatoes", "portion (about 1 kg)", 1000, "🍠", 125, ("potato",)),
    ("irish-potato", "tubers", "Irish potatoes", "portion (about 1 kg)", 2000, "🥔", 135, ("potato",)),
    ("plantain-ripe", "tubers", "Ripe plantain", "bunch of 5", 2000, "🍌", 245, ("plantain", "dodo")),
    ("plantain-unripe", "tubers", "Unripe plantain", "bunch of 5", 2000, "🍌", 115, ("plantain",)),
    ("beef", "meat", "Beef (raw)", "500 g", 4200, "🥩", 295, ("beef", "meat")),
    ("goat-meat", "meat", "Goat meat", "1 kg", 9500, "🥩", 175, ("goat", "meat")),
    ("assorted", "meat", "Assorted meat (shaki, liver, kidney)", "portion", 5000, "🥩", 165, ("assorted",)),
    ("ponmo-3", "meat", "Ponmo (cow skin)", "3 pieces", 1500, "🥩", 185, ("ponmo", "kpomo")),
    ("catfish", "fish", "Catfish (cleaned)", "1 medium", 5000, "🐟", 225, ("catfish", "fish")),
    ("titus-1kg", "fish", "Titus fish (frozen mackerel)", "1 kg", 6500, "🐟", 235, ("titus", "mackerel")),
    ("croaker-1kg", "fish", "Croaker fish", "1 kg", 9000, "🐟", 140, ("croaker",)),
    ("smoked-panla", "fish", "Smoked fish (panla)", "pack", 2000, "🐟", 195, ("panla", "smoked fish")),
    ("stockfish", "fish", "Stockfish pieces (okporoko)", "portion", 3500, "🐟", 155, ("stockfish",)),
    ("crayfish-cup", "fish", "Crayfish (ground)", "small cup", 1500, "🦐", 270, ("crayfish",)),
    ("chicken-laps-1kg", "chicken", "Chicken laps", "1 kg", 6500, "🍗", 255, ("chicken",)),
    ("whole-chicken", "chicken", "Whole chicken (dressed)", "about 1.5 kg", 9000, "🍗", 145, ("chicken",)),
    ("turkey-wings-1kg", "chicken", "Turkey wings", "1 kg", 8500, "🍗", 150, ("turkey",)),
    ("bananas", "fruits", "Bananas", "bunch", 1500, "🍌", 200, ("banana",)),
    ("oranges-10", "fruits", "Oranges", "10 pieces", 1500, "🍊", 170, ("orange",)),
    ("pineapple", "fruits", "Pineapple", "1 medium", 1800, "🍍", 160, ("pineapple",)),
    ("watermelon", "fruits", "Watermelon", "1 medium", 3000, "🍉", 180, ("watermelon",)),
    ("pawpaw", "fruits", "Pawpaw", "1 medium", 2000, "🥭", 105, ("pawpaw", "papaya")),
    ("palm-oil-75", "spices", "Palm oil", "75 cl bottle", 2200, "🍶", 280, ("palm oil",)),
    ("groundnut-oil-75", "spices", "Groundnut oil", "75 cl bottle", 2800, "🍶", 165, ("oil",)),
    ("dry-pepper-cup", "spices", "Dried pepper (ground)", "small cup", 1000, "🌶️", 185, ("pepper",)),
    ("iru-wrap", "spices", "Iru (locust beans)", "wrap", 300, "🥜", 175, ("iru", "ogiri")),
    ("curry-thyme", "spices", "Curry and thyme", "set", 600, "🌿", 155, ("curry", "thyme")),
]

# Ready-made baskets, the way market stalls bundle them: (code, name, what is in it, price).
COMBOS: list[tuple[str, str, str, int]] = [
    ("combo-pepper-stew", "Pepper stew combo", "Tomatoes, rodo, tatashe and onions for 1 pot of stew.", 2500),
    (
        "combo-egusi",
        "Egusi soup combo",
        "Egusi, ugwu, palm oil, crayfish, stockfish, ponmo and pepper.",
        7500,
    ),
    (
        "combo-jollof",
        "Jollof rice combo",
        "Rice (2 derica), stew mix, seasoning and oil for a family pot.",
        6800,
    ),
    ("combo-okro", "Okro soup combo", "Okro, ugwu, palm oil, crayfish, ponmo and pepper for 1 pot.", 4800),
]
ENUGU_COMBOS: list[tuple[str, str, str, int]] = [
    ("combo-onugbu", "Ofe onugbu combo", "Washed bitterleaf, cocoyam, stockfish, ogiri and palm oil.", 6500),
    ("combo-egusi", "Ofe egusi combo", "Egusi, ugwu, palm oil, crayfish, stockfish and pepper.", 7500),
    ("combo-abacha", "Abacha combo", "Abacha, ugba, garden egg, ponmo, palm oil and pepper.", 4500),
    ("combo-pepper-stew", "Pepper stew combo", "Tomatoes, pepper and onions for 1 pot of stew.", 2500),
]
ENUGU_MARKET_ROWS: list[Row] = [
    ("abacha-wrap", "grains", "Abacha (dried cassava flakes)", "wrap", 800, "🌾", 230, ("abacha",)),
    ("ugba-wrap", "spices", "Ugba (oil bean)", "wrap", 500, "🥜", 210, ("ugba", "ukpaka")),
    ("bitterleaf", "vegetables", "Bitterleaf (washed)", "portion", 500, "🥬", 220, ("onugbu", "bitterleaf")),
    ("cocoyam", "tubers", "Cocoyam (ede) for soup", "portion", 1000, "🍠", 150, ("cocoyam", "ede")),
    ("ukwa-derica", "grains", "Ukwa (breadfruit)", "derica", 4500, "🌰", 120, ("ukwa", "breadfruit")),
]


def _product(
    prefix: str, rid: str, row: Row, *, factor: float, out_of_stock: set[str], prep: int
) -> MenuItem:
    code, aisle, name, unit, price, emoji, popularity, tags = row
    return _i(
        rid,
        f"{prefix}-{code}",
        aisle,
        name,
        max(100, round(price * factor / 50) * 50),
        kind=ItemKind.PRODUCT,
        unit_label=unit,
        emoji=emoji,
        tags=list(tags),
        popularity=popularity,
        prep_minutes=prep,
        is_available=code not in out_of_stock,
    )


def _aisles(aisles: list[tuple[str, str]], items: list[MenuItem]) -> list[MenuCategory]:
    used = {i.category_id for i in items}
    return [MenuCategory(id=a, name=n, position=p) for p, (a, n) in enumerate(aisles) if a in used]


def _grocery(
    prefix: str, rid: str, *, factor: float, aisles: set[str] | None = None, out: tuple[str, ...] = ()
) -> Menu:
    """A supermarket's menu. Eggs come by the half crate or the crate: a product with a choice ("From ₦...")."""
    rows = [r for r in GROCERY_ROWS if aisles is None or r[1] in aisles]
    items = [_product(prefix, rid, r, factor=factor, out_of_stock=set(out), prep=12) for r in rows]
    eggs = OptionGroup(
        id=f"{rid}-egg-pack",
        restaurant_id=rid,
        name="Pack size",
        min_select=1,
        max_select=1,
        choices=[
            OptionChoice(id="half", name="Half crate (15 eggs)"),
            OptionChoice(id="full", name="Full crate (30 eggs)", price_delta_kobo=naira(3000)),
        ],
    )
    groups: list[OptionGroup] = []
    for n, item in enumerate(items):
        if item.id == f"{prefix}-eggs":
            items[n] = item.model_copy(
                update={"option_group_ids": [eggs.id], "unit_label": "from half a crate"}
            )
            groups = [eggs]
    return _aisles(GROCERY_AISLES, items), items, groups


def _pharmacy(prefix: str, rid: str, *, factor: float, out: tuple[str, ...] = ()) -> Menu:
    items = [_product(prefix, rid, r, factor=factor, out_of_stock=set(out), prep=8) for r in PHARMACY_ROWS]
    for row in PRESCRIPTION_ROWS:
        hidden = _product(prefix, rid, row, factor=factor, out_of_stock=set(), prep=8)
        items.append(hidden.model_copy(update={"requires_prescription": True}))
    return _aisles(PHARMACY_AISLES, items), items, []


def _market(
    prefix: str,
    rid: str,
    *,
    factor: float,
    combos: list[tuple[str, str, str, int]],
    extra: list[Row] | None = None,
    out: tuple[str, ...] = (),
) -> Menu:
    """A market shopper's list: combos first, then foodstuff by local measure. Beef is sold by weight and
    ugwu can be washed and sliced: products with choices."""
    items = [
        _i(
            rid,
            f"{prefix}-{code}",
            "combos",
            name,
            max(100, round(price * factor / 50) * 50),
            kind=ItemKind.COMBO,
            description=desc,
            emoji="🍲",
            tags=["combo", "soup"],
            popularity=310 - n * 15,
            prep_minutes=30,
        )
        for n, (code, name, desc, price) in enumerate(combos)
    ]
    rows = [*MARKET_ROWS, *(extra or [])]
    items += [_product(prefix, rid, r, factor=factor, out_of_stock=set(out), prep=30) for r in rows]
    weight = OptionGroup(
        id=f"{rid}-beef-weight",
        restaurant_id=rid,
        name="How much?",
        min_select=1,
        max_select=1,
        choices=[
            OptionChoice(id="500g", name="500 g"),
            OptionChoice(id="1kg", name="1 kg", price_delta_kobo=naira(round(3800 * factor / 50) * 50)),
            OptionChoice(id="2kg", name="2 kg", price_delta_kobo=naira(round(11400 * factor / 50) * 50)),
        ],
    )
    cut = OptionGroup(
        id=f"{rid}-beef-cut",
        restaurant_id=rid,
        name="How should we cut it?",
        min_select=0,
        max_select=1,
        choices=[
            OptionChoice(id="stew", name="Stew size"),
            OptionChoice(id="small", name="Small pieces for soup"),
            OptionChoice(id="whole", name="Leave it whole"),
        ],
    )
    leaves = OptionGroup(
        id=f"{rid}-leaves-prep",
        restaurant_id=rid,
        name="Preparation",
        min_select=1,
        max_select=1,
        choices=[
            OptionChoice(id="plain", name="As it is"),
            OptionChoice(id="sliced", name="Washed and sliced", price_delta_kobo=naira(200)),
        ],
    )
    for n, item in enumerate(items):
        if item.id == f"{prefix}-beef":
            items[n] = item.model_copy(
                update={"option_group_ids": [weight.id, cut.id], "unit_label": "from 500 g"}
            )
        elif item.id == f"{prefix}-ugwu-bunch":
            items[n] = item.model_copy(update={"option_group_ids": [leaves.id]})
    return _aisles(MARKET_AISLES, items), items, [weight, cut, leaves]


MERCHANTS: list[Restaurant] = [
    # ---------------------------------------------------------------------------------------- supermarkets
    _m(
        "g-freshbasket",
        "FreshBasket Supermarket",
        city="lagos",
        area="Lekki Phase 1",
        lat=6.4455,
        lng=3.4705,
        street="14 Admiralty Way",
        vertical=Vertical.GROCERY,
        description="A full supermarket shop: drinks, food cupboard, fresh and frozen, household and baby.",
        cuisines=["Supermarket", "Drinks", "Fresh produce", "Household", "Baby"],
        tags=["groceries", "water", "rice", "bread"],
        rating=4.6,
        rating_count=1820,
        price_level=2,
        avg_prep_minutes=15,
        opening_hours=_hours("08:00", "22:00"),
        delivery_radius_km=18,
        is_featured=True,
        phone="+2348000000201",
    ),
    _m(
        "g-mainland-mart",
        "Mainland Mart",
        city="lagos",
        area="Yaba",
        lat=6.5090,
        lng=3.3780,
        street="22 Herbert Macaulay Way",
        vertical=Vertical.GROCERY,
        description="Everyday groceries at mainland prices: food cupboard, drinks, toiletries and household.",
        cuisines=["Supermarket", "Drinks", "Household", "Toiletries"],
        tags=["groceries", "noodles", "detergent"],
        rating=4.4,
        rating_count=940,
        price_level=1,
        avg_prep_minutes=18,
        opening_hours=_hours("08:00", "21:00"),
        delivery_radius_km=16,
        phone="+2348000000202",
    ),
    _m(
        "g-quickstop",
        "QuickStop Mini Mart",
        city="lagos",
        area="Victoria Island",
        lat=6.4300,
        lng=3.4250,
        street="9 Akin Adesola Street",
        vertical=Vertical.GROCERY,
        description="Open late for the quick things: cold drinks, snacks, bread, milk and toiletries.",
        cuisines=["Convenience", "Drinks", "Snacks"],
        tags=["snacks", "drinks", "late night"],
        rating=4.3,
        rating_count=410,
        price_level=2,
        avg_prep_minutes=8,
        opening_hours=_hours("07:00", "23:30"),
        delivery_radius_km=14,
        phone="+2348000000203",
    ),
    _m(
        "g-coal-city-superstore",
        "Coal City Superstore",
        city="enugu",
        area="Independence Layout",
        lat=6.4490,
        lng=7.5190,
        street="5 Nza Street",
        vertical=Vertical.GROCERY,
        zone_id="enugu",
        description="Enugu's one-stop shop: food cupboard, drinks, fresh and frozen, household and baby.",
        cuisines=["Supermarket", "Drinks", "Fresh produce", "Household", "Baby"],
        tags=["groceries", "water", "rice"],
        rating=4.5,
        rating_count=520,
        price_level=2,
        avg_prep_minutes=15,
        opening_hours=_hours("08:00", "21:00"),
        delivery_radius_km=14,
        is_featured=True,
        phone="+2348000000204",
    ),
    # ------------------------------------------------------------------------------------------ pharmacies
    _m(
        "p-carefirst",
        "CareFirst Pharmacy",
        city="lagos",
        area="Lekki Phase 1",
        lat=6.4380,
        lng=3.4560,
        street="3 Fola Osibo Road",
        vertical=Vertical.PHARMACY,
        description="Over-the-counter medicines, vitamins, first aid and baby care. A pharmacist packs every order.",
        cuisines=["Pain relief", "Cough & cold", "Vitamins", "First aid", "Mother & baby", "Personal care"],
        tags=["paracetamol", "vitamin c", "first aid"],
        rating=4.7,
        rating_count=640,
        price_level=2,
        avg_prep_minutes=10,
        opening_hours=_hours("08:00", "22:00"),
        delivery_radius_km=18,
        is_featured=True,
        phone="+2348000000211",
    ),
    _m(
        "p-wellspring",
        "Wellspring Pharmacy",
        city="lagos",
        area="Ikeja GRA",
        lat=6.5850,
        lng=3.3530,
        street="17 Isaac John Street",
        vertical=Vertical.PHARMACY,
        description="Everyday health needs for the mainland: pain relief, cough and cold, vitamins and devices.",
        cuisines=["Pain relief", "Cough & cold", "Vitamins", "First aid", "Devices"],
        tags=["pharmacy", "thermometer", "vitamins"],
        rating=4.5,
        rating_count=310,
        price_level=2,
        avg_prep_minutes=10,
        opening_hours=_hours("08:00", "21:00"),
        delivery_radius_km=16,
        phone="+2348000000212",
    ),
    _m(
        "p-hilltop",
        "Hilltop Pharmacy",
        city="enugu",
        area="GRA",
        lat=6.4560,
        lng=7.5080,
        street="8 Abakaliki Road",
        vertical=Vertical.PHARMACY,
        zone_id="enugu",
        description="Over-the-counter medicines, vitamins, first aid and mother and baby care in Enugu.",
        cuisines=["Pain relief", "Cough & cold", "Vitamins", "First aid", "Mother & baby", "Personal care"],
        tags=["pharmacy", "paracetamol", "baby care"],
        rating=4.6,
        rating_count=150,
        price_level=2,
        avg_prep_minutes=10,
        opening_hours=_hours("08:00", "21:00"),
        delivery_radius_km=14,
        is_featured=True,
        phone="+2348000000213",
    ),
    # --------------------------------------------------------------------------------------------- markets
    _m(
        "m-lekki-market",
        "Lekki Market Shopper",
        city="lagos",
        area="Lekki Phase 1",
        lat=6.4420,
        lng=3.4780,
        street="Market road, off Admiralty Way",
        vertical=Vertical.MARKET,
        description="A shopper buys your foodstuff fresh at the market: pepper, vegetables, meat, fish and grains.",
        cuisines=["Foodstuff", "Pepper & vegetables", "Meat & fish", "Tubers", "Fruits", "Soup combos"],
        tags=["foodstuff", "tomatoes", "yam", "soup"],
        rating=4.5,
        rating_count=760,
        price_level=1,
        avg_prep_minutes=35,
        opening_hours=_hours("08:00", "18:00"),
        delivery_radius_km=18,
        is_featured=True,
        supports_pickup=False,
        phone="+2348000000221",
    ),
    _m(
        "m-mainland-market",
        "Mainland Market Shopper",
        city="lagos",
        area="Surulere",
        lat=6.5000,
        lng=3.3600,
        street="Market lane, off Ojuelegba Road",
        vertical=Vertical.MARKET,
        description="Mainland market prices, bought for you the same day: foodstuff, pepper, meat and fish.",
        cuisines=["Foodstuff", "Pepper & vegetables", "Meat & fish", "Tubers", "Soup combos"],
        tags=["foodstuff", "garri", "beans"],
        rating=4.3,
        rating_count=430,
        price_level=1,
        avg_prep_minutes=40,
        opening_hours=_hours("08:00", "18:00"),
        delivery_radius_km=16,
        supports_pickup=False,
        phone="+2348000000222",
    ),
    _m(
        "m-enugu-main-market",
        "Enugu Main Market Shopper",
        city="enugu",
        area="Ogui",
        lat=6.4410,
        lng=7.4950,
        street="Market road, Ogui",
        vertical=Vertical.MARKET,
        zone_id="enugu",
        description="A shopper buys your foodstuff at the main market: abacha, ugba, bitterleaf, meat and fish.",
        cuisines=["Foodstuff", "Pepper & vegetables", "Meat & fish", "Tubers", "Fruits", "Soup combos"],
        tags=["foodstuff", "abacha", "ofe onugbu"],
        rating=4.6,
        rating_count=280,
        price_level=1,
        avg_prep_minutes=35,
        opening_hours=_hours("08:00", "18:00"),
        delivery_radius_km=14,
        is_featured=True,
        supports_pickup=False,
        phone="+2348000000223",
    ),
]

VOUCHERS: list[Voucher] = [
    Voucher(
        code="FRESH10",
        description="10% off at FreshBasket (up to ₦2,000)",
        kind="percent",
        value=1000,
        max_discount_kobo=naira(2000),
        funded_by="restaurant",
        restaurant_id="g-freshbasket",
        per_customer_limit=3,
    ),
]


def retail_menus() -> dict[str, Menu]:
    convenience = {"drinks", "snacks", "bakery", "dairy", "toiletries"}
    return {
        "g-freshbasket": _grocery("fb", "g-freshbasket", factor=1.0, out=("ice-cream-1l", "butter-250")),
        "g-mainland-mart": _grocery(
            "mm",
            "g-mainland-mart",
            factor=0.94,
            aisles={"drinks", "cupboard", "condiments", "dairy", "snacks", "toiletries", "household"},
            out=("yoghurt-1l",),
        ),
        "g-quickstop": _grocery("qs", "g-quickstop", factor=1.08, aisles=convenience, out=("bread-wheat",)),
        "g-coal-city-superstore": _grocery("cs", "g-coal-city-superstore", factor=0.97, out=("apples-4",)),
        "p-carefirst": _pharmacy("cf", "p-carefirst", factor=1.0, out=("bp-monitor",)),
        "p-wellspring": _pharmacy("ws", "p-wellspring", factor=0.96, out=("nasal-spray-30",)),
        "p-hilltop": _pharmacy("ht", "p-hilltop", factor=0.95),
        "m-lekki-market": _market("lm", "m-lekki-market", factor=1.0, combos=COMBOS, out=("croaker-1kg",)),
        "m-mainland-market": _market(
            "ml", "m-mainland-market", factor=0.9, combos=COMBOS, out=("garden-egg", "pawpaw")
        ),
        "m-enugu-main-market": _market(
            "em", "m-enugu-main-market", factor=0.92, combos=ENUGU_COMBOS, extra=ENUGU_MARKET_ROWS
        ),
    }


async def seed_retail(repos: Repositories) -> dict[str, int]:
    menus = retail_menus()
    counts = {"merchants": 0, "items": 0, "groups": 0, "vouchers": 0}
    for shop in MERCHANTS:
        await repos.restaurants.save(shop)
        aisles, items, groups = menus[shop.id]
        await repos.set_menu_categories(shop.id, aisles)
        for group in groups:
            await repos.option_groups.save(group)
        for position, item in enumerate(items):
            await repos.items.save(item.model_copy(update={"position": position}))
        counts["merchants"] += 1
        counts["items"] += len(items)
        counts["groups"] += len(groups)
    for voucher in VOUCHERS:
        await repos.vouchers.save(voucher)
        counts["vouchers"] += 1
    return counts
