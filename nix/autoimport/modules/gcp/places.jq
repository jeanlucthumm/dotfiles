# Trims Places and Routes API responses down to what an agent needs; the raw
# JSON is ~10KB per place and ~7KB per transit route. $mode is "search", "get"
# or "route" (nearby uses "search").

def compact: with_entries(select(.value | . != null and . != [] and . != ""));

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
} | compact;

# Transit steps as one line each, with every run of walking directions
# collapsed into a single walk.
def steps: reduce (.legs[]?.steps[]?) as $s ([];
  if $s.travelMode != "WALK" then . + [$s.transitDetails]
  else ($s.staticDuration | rtrimstr("s") | tonumber) as $t
    | if last.walk then .[-1].walk += $t else . + [{walk: $t}] end end)
  | map(if .walk then "walk \(.walk / 60 | ceil) min"
    else .transitLine as $l | .stopDetails as $s | .localizedValues as $t
      | "\($l.nameShort // $l.name) \($l.vehicle.name.text | ascii_downcase) to \(.headsign): "
        + "\($s.departureStop.name) \($t.departureTime.time.text) → "
        + "\($s.arrivalStop.name) \($t.arrivalTime.time.text) (\(.stopCount) stops)"
    end);

# Route args (FROM, TO and their waypoints o, d) come via $ARGS since the
# other modes don't pass them.
def route: $ARGS.named as {$travel, $from, $to, $o, $d} | {
  mode: $travel, duration: .localizedValues.duration.text,
  no_traffic: (if $travel == "drive" then .localizedValues.staticDuration.text else null end),
  distance: .localizedValues.distance.text, via: .description,
  fare: .localizedValues.transitFare.text, steps: steps, warnings,
  maps: ("https://www.google.com/maps/dir/?api=1&origin=\($from | @uri)&destination=\($to | @uri)"
    + if $o.placeId then "&origin_place_id=\($o.placeId)" else "" end
    + if $d.placeId then "&destination_place_id=\($d.placeId)" else "" end
    + "&travelmode=\({drive: "driving", walk: "walking", bike: "bicycling", transit: "transit"}[$travel])")
} | compact;

if .error then "places: \(.error.message)\n" | halt_error(1)
elif $mode == "search" then .places[]? | place
elif $mode == "route" then (.routes // ("places: no route found\n" | halt_error(1)))[:3][] | route
else place
end
