"""Browse categories for each service (the round "bubbles" under the search bar on each service's page).

A merchant belongs to a category when one of its cuisines/categories (case-insensitive) is in the category's
set. "promotions" is special: merchants with an active merchant-specific voucher.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class BrowseCategory:
    id: str
    name: str
    emoji: str
    matches: frozenset[str] = field(default_factory=frozenset)


PROMOTIONS = "promotions"

FOOD_CATEGORIES: tuple[BrowseCategory, ...] = (
    BrowseCategory(PROMOTIONS, "Promotions", "🏷️"),
    BrowseCategory(
        "local",
        "Local food",
        "🍲",
        frozenset(
            {
                "nigerian",
                "yoruba",
                "igbo",
                "efik",
                "northern nigerian",
                "rice dishes",
                "swallow",
                "soups",
                "native",
            }
        ),
    ),
    BrowseCategory(
        "international",
        "International",
        "🌍",
        frozenset(
            {"fast food", "shawarma", "pizza", "burgers", "chinese", "italian", "lebanese", "continental"}
        ),
    ),
    BrowseCategory(
        "snacks", "Snacks", "🥟", frozenset({"snacks", "party food", "small chops", "pastries", "bakery"})
    ),
    BrowseCategory("grills", "Grills & suya", "🍢", frozenset({"grills", "suya", "barbecue", "seafood"})),
    BrowseCategory("healthy", "Healthy", "🥗", frozenset({"healthy", "vegetarian", "salads"})),
    BrowseCategory("drinks", "Drinks", "🥤", frozenset({"drinks", "smoothies", "juice", "zobo"})),
)

BEAUTY_CATEGORIES: tuple[BrowseCategory, ...] = (
    BrowseCategory(PROMOTIONS, "Promotions", "🏷️"),
    BrowseCategory("skincare", "Skincare", "🧴", frozenset({"skincare", "face care", "sun care"})),
    BrowseCategory("bodycare", "Body care", "🧼", frozenset({"body care", "bath", "natural oils"})),
    BrowseCategory("haircare", "Hair care", "💇🏾‍♀️", frozenset({"hair care", "natural hair", "wigs"})),
    BrowseCategory("makeup", "Make-up", "💄", frozenset({"make-up", "makeup", "cosmetics"})),
    BrowseCategory("fragrance", "Fragrance", "🌸", frozenset({"fragrance", "perfume", "perfume oils"})),
    BrowseCategory("men", "Men's grooming", "🧔🏾", frozenset({"men's grooming", "beard care"})),
)

# Shop & Groceries, Pharmacy and Buy Foodstuff (ADR-0018, names from ADR-0025). A shop matches by the departments
# it lists in `cuisines`.
GROCERY_CATEGORIES: tuple[BrowseCategory, ...] = (
    BrowseCategory(PROMOTIONS, "Promotions", "🏷️"),
    BrowseCategory("supermarkets", "Supermarkets", "🛒", frozenset({"supermarket", "superstore"})),
    BrowseCategory(
        "convenience", "Convenience", "🏪", frozenset({"convenience", "mini mart", "corner shop"})
    ),
    BrowseCategory("drinks", "Drinks & water", "🥤", frozenset({"drinks", "water", "soft drinks", "juice"})),
    BrowseCategory(
        "fresh", "Fresh & frozen", "🥦", frozenset({"fresh produce", "frozen", "dairy", "bakery"})
    ),
    BrowseCategory("baby", "Baby", "🍼", frozenset({"baby", "baby & toddler"})),
    BrowseCategory("household", "Household", "🧻", frozenset({"household", "toiletries", "cleaning"})),
)

PHARMACY_CATEGORIES: tuple[BrowseCategory, ...] = (
    BrowseCategory(PROMOTIONS, "Promotions", "🏷️"),
    BrowseCategory("pain", "Pain & fever", "💊", frozenset({"pain relief", "pain & fever", "analgesics"})),
    BrowseCategory("cold", "Cough & cold", "🤧", frozenset({"cough & cold", "cold & flu", "allergy"})),
    BrowseCategory("vitamins", "Vitamins", "🍊", frozenset({"vitamins", "supplements", "multivitamins"})),
    BrowseCategory("firstaid", "First aid", "🩹", frozenset({"first aid", "medical supplies", "devices"})),
    BrowseCategory("baby", "Mother & baby", "🍼", frozenset({"mother & baby", "baby care"})),
    BrowseCategory(
        "personal", "Personal care", "🧼", frozenset({"personal care", "toiletries", "skin care"})
    ),
)

MARKET_CATEGORIES: tuple[BrowseCategory, ...] = (
    BrowseCategory(PROMOTIONS, "Promotions", "🏷️"),
    BrowseCategory("foodstuff", "Foodstuff", "🧺", frozenset({"foodstuff", "grains", "rice & grains"})),
    BrowseCategory(
        "vegetables", "Pepper & vegetables", "🍅", frozenset({"pepper & vegetables", "vegetables"})
    ),
    BrowseCategory("protein", "Meat & fish", "🐟", frozenset({"meat", "fish", "meat & fish", "protein"})),
    BrowseCategory("tubers", "Tubers", "🍠", frozenset({"tubers", "yam"})),
    BrowseCategory("fruits", "Fruits", "🍌", frozenset({"fruits"})),
    BrowseCategory("combos", "Soup combos", "🍲", frozenset({"combos", "soup combos"})),
)

CATEGORIES_BY_VERTICAL: dict[str, tuple[BrowseCategory, ...]] = {
    "food": FOOD_CATEGORIES,
    "beauty": BEAUTY_CATEGORIES,
    "grocery": GROCERY_CATEGORIES,
    "pharmacy": PHARMACY_CATEGORIES,
    "market": MARKET_CATEGORIES,
}


def category_matches(category: BrowseCategory, cuisines: list[str]) -> bool:
    return any(c.lower() in category.matches for c in cuisines)


def find_category(vertical: str, category_id: str) -> BrowseCategory | None:
    return next((c for c in CATEGORIES_BY_VERTICAL.get(vertical, ()) if c.id == category_id), None)
