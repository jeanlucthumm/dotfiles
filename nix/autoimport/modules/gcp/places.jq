# Trims Places API responses down to what an agent needs to pick a place;
# the raw JSON is ~10KB per place. $mode is "search" or "get".

def price: {PRICE_LEVEL_FREE: "free", PRICE_LEVEL_INEXPENSIVE: "$", PRICE_LEVEL_MODERATE: "$$",
  PRICE_LEVEL_EXPENSIVE: "$$$", PRICE_LEVEL_VERY_EXPENSIVE: "$$$$"}[. // ""];

def place: {
  id, name: .displayName.text, type: .primaryTypeDisplayName.text,
  address: .shortFormattedAddress, rating, ratings: .userRatingCount,
  price: (.priceLevel | price), open_now: .currentOpeningHours.openNow,
  summary: .reviewSummary.text.text,
  reviews: [.reviews[]? | {stars: .rating, when: .relativePublishTimeDescription, text: .text.text}],
  hours: .currentOpeningHours.weekdayDescriptions,
  features: [to_entries[] | select(.value == true) | .key],
  phone: .nationalPhoneNumber, website: .websiteUri,
  maps: (.googleMapsUri // "" | sub("&g_mp=[^&]*"; ""))
} | with_entries(select(.value | . != null and . != [] and . != ""));

if .error then "places: \(.error.message)\n" | halt_error(1)
elif $mode == "search" then .places[]? | place
else place
end
