#!/usr/bin/env bash
# Built by gcp.nix, which sets $places_jq and puts curl, jq, gcloud and date on
# PATH. Auth is whatever gcloud account the environment provides (on the
# server, the sandbox service account); Places and Routes APIs accept its OAuth
# token directly, so there's no API key.

# reviewSummary and reviews put every call in the Enterprise + Atmosphere SKU,
# so the other fields here cost nothing extra.
base_fields=id,displayName,primaryTypeDisplayName,shortFormattedAddress,rating,userRatingCount,priceLevel,reviewSummary
food_fields=dineIn,takeout,delivery,reservable,outdoorSeating,servesBreakfast,servesBrunch,servesLunch,servesDinner,servesVegetarianFood,servesBeer,servesWine,servesCocktails,servesCoffee,servesDessert,goodForChildren,goodForGroups,allowsDogs
route_fields=routes.duration,routes.staticDuration,routes.description,routes.warnings,routes.localizedValues
transit_fields=routes.legs.steps.travelMode,routes.legs.steps.staticDuration,routes.legs.steps.transitDetails

# Copied verbatim into .claude/skills/places/SKILL.md; keep them in sync.
usage() {
  cat <<'EOF'
Usage: places search [-n N] [--reviews] [--near WHERE] QUERY...
       places get PLACE_ID
       places route [--mode MODE] [--depart TIME | --arrive TIME] FROM TO

Google Maps places, reviews and routes. Prints JSON lines.

  search   Text search, e.g. "ramen in the Mission, SF". Up to N places
           (default 5, max 20) with rating, price, open-now and a Gemini
           summary of their reviews. --reviews adds each place's 5 most
           relevant reviews. --near lists places nearest WHERE first,
           with no distance cutoff.
  get      One place by id: summary, 5 reviews, hours, food/service
           features, phone, website.
  route    Up to 3 routes from FROM to TO. MODE is drive (default, with
           live traffic; no_traffic is the same trip on empty roads), walk,
           bike or transit (lines, stops and departure times). TIME is
           anything `date -d` reads, e.g. "18:30" or "tomorrow 9am";
           --arrive is transit only.

WHERE, FROM and TO are an address, a place name or LAT,LNG.
Google never returns more than 5 full reviews per place.

Anything else in the Places or Routes APIs (places.googleapis.com,
routes.googleapis.com; the legacy maps.googleapis.com ones need an API key):
curl with -H "Authorization: Bearer $(gcloud auth print-access-token)" and an
X-Goog-FieldMask header, which is required and sets the price. Responses are
large; trim them with jq.
EOF
}

call() {
  local token
  token=$(gcloud auth print-access-token)
  curl -sS -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$@"
}

# LAT,LNG as {latitude, longitude}; null for anything else.
latlng() {
  jq -nc --arg s "$1" '($s | capture("^ *(?<lat>-?[0-9.]+) *, *(?<lng>-?[0-9.]+) *$")
    | {latitude: (.lat | tonumber), longitude: (.lng | tonumber)}) // null'
}

# FIELD (id or location) of the top Places match for TEXT. Routes API's own
# address lookup is bad at names: "SFO" lands a mile from Dolores Park.
find_place() {
  call -H "X-Goog-FieldMask: places.$1" -d "$(jq -nc --arg q "$2" '{textQuery: $q, pageSize: 1}')" \
    https://places.googleapis.com/v1/places:searchText \
    | jq -c --arg f "$1" --arg q "$2" 'if .error then "places: \(.error.message)\n" | halt_error(1)
        else .places[0][$f] // ("places: nothing found for \($q)\n" | halt_error(1)) end'
}

# FROM or TO as a Routes API waypoint.
waypoint() {
  local ll id
  ll=$(latlng "$1")
  if [[ $ll != null ]]; then jq -nc --argjson ll "$ll" '{location: {latLng: $ll}}'; return; fi
  id=$(find_place id "$1") || return
  jq -nc --argjson id "$id" '{placeId: $id}'
}

cmd=${1:-}
shift || true
case "$cmd" in
  search)
    n=5 near='' center=null
    fields="$base_fields,currentOpeningHours.openNow"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -n) n=$2; shift 2 ;;
        --reviews) fields+=",reviews"; shift ;;
        --near) near=$2; shift 2 ;;
        -*) usage >&2; exit 2 ;;
        *) break ;;
      esac
    done
    [[ $# -ge 1 ]] || { usage >&2; exit 2; }
    if [[ -n $near ]]; then
      center=$(latlng "$near")
      if [[ $center == null ]]; then center=$(find_place location "$near"); fi
    fi
    # With DISTANCE ranking the bias radius barely matters: 100m and 50km
    # return nearly the same places.
    body=$(jq -nc --arg q "$*" --argjson n "$n" --argjson center "$center" '
      {textQuery: $q, pageSize: $n, languageCode: "en"}
      + if $center then {locationBias: {circle: {center: $center, radius: 1000}}, rankPreference: "DISTANCE"}
        else {} end')
    call -H "X-Goog-FieldMask: places.${fields//,/,places.}" -d "$body" \
      https://places.googleapis.com/v1/places:searchText \
      | jq -c --arg mode search -f "$places_jq"
    ;;
  get)
    [[ $# -eq 1 ]] || { usage >&2; exit 2; }
    call -H "X-Goog-FieldMask: $base_fields,$food_fields,reviews,currentOpeningHours,nationalPhoneNumber,websiteUri,googleMapsUri" \
      "https://places.googleapis.com/v1/places/$1?languageCode=en" \
      | jq -c --arg mode get -f "$places_jq"
    ;;
  route)
    travel=drive time_field='' time=''
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --mode) travel=$2; shift 2 ;;
        --depart) time_field=departureTime time=$2; shift 2 ;;
        --arrive) time_field=arrivalTime time=$2; shift 2 ;;
        -*) usage >&2; exit 2 ;;
        *) break ;;
      esac
    done
    [[ $# -eq 2 ]] || { usage >&2; exit 2; }
    # Google silently ignores arrivalTime outside transit.
    if [[ $time_field == arrivalTime && $travel != transit ]]; then
      echo "places: --arrive is transit only" >&2; exit 2
    fi
    fields=$route_fields
    case "$travel" in
      drive) api_mode=DRIVE ;;
      walk) api_mode=WALK ;;
      bike) api_mode=BICYCLE ;;
      transit) api_mode=TRANSIT fields+=",$transit_fields" ;;
      *) usage >&2; exit 2 ;;
    esac
    if [[ -n $time ]]; then time=$(date -d "$time" --iso-8601=seconds); fi
    origin=$(waypoint "$1")
    dest=$(waypoint "$2")
    body=$(jq -nc --argjson o "$origin" --argjson d "$dest" --arg mode "$api_mode" --arg tf "$time_field" --arg t "$time" '
      {origin: $o, destination: $d, travelMode: $mode, computeAlternativeRoutes: true,
       languageCode: "en-US", units: "IMPERIAL"}
      + if $mode == "DRIVE" then {routingPreference: "TRAFFIC_AWARE"} else {} end
      + if $tf != "" then {($tf): $t} else {} end')
    call -H "X-Goog-FieldMask: $fields" -d "$body" \
      https://routes.googleapis.com/directions/v2:computeRoutes \
      | jq -c --arg mode route --arg travel "$travel" --arg from "$1" --arg to "$2" \
        --argjson o "$origin" --argjson d "$dest" -f "$places_jq"
    ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
