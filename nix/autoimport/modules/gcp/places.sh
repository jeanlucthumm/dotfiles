#!/usr/bin/env bash
# Built by gcp.nix, which sets $places_jq and puts curl, jq and gcloud on
# PATH. Auth is whatever gcloud account the environment provides (on the
# server, the sandbox service account); Places API accepts its OAuth token
# directly, so there's no API key.

# reviewSummary and reviews put every call in the Enterprise + Atmosphere SKU,
# so the other fields here cost nothing extra.
base_fields=id,displayName,primaryTypeDisplayName,shortFormattedAddress,rating,userRatingCount,priceLevel,reviewSummary
food_fields=dineIn,takeout,delivery,reservable,outdoorSeating,servesBreakfast,servesBrunch,servesLunch,servesDinner,servesVegetarianFood,servesBeer,servesWine,servesCocktails,servesCoffee,servesDessert,goodForChildren,goodForGroups,allowsDogs

usage() {
  cat <<'EOF'
Usage: places search [-n N] [--reviews] QUERY...
       places get PLACE_ID

Google Maps ratings and reviews via Places API. Prints JSON lines.

  search   Text search, e.g. "ramen in the Mission, SF". Up to N places
           (default 5, max 20) with rating, price, open-now and a Gemini
           summary of their reviews. --reviews adds each place's 5 most
           relevant reviews.
  get      One place by id: summary, 5 reviews, hours, food/service
           features, phone, website.

Google never returns more than 5 full reviews per place.
EOF
}

call() {
  local token
  token=$(gcloud auth print-access-token)
  curl -sS -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$@"
}

cmd=${1:-}
shift || true
case "$cmd" in
  search)
    n=5
    fields="$base_fields,currentOpeningHours.openNow"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -n) n=$2; shift 2 ;;
        --reviews) fields+=",reviews"; shift ;;
        -*) usage >&2; exit 2 ;;
        *) break ;;
      esac
    done
    [[ $# -ge 1 ]] || { usage >&2; exit 2; }
    body=$(jq -nc --arg q "$*" --argjson n "$n" '{textQuery: $q, pageSize: $n, languageCode: "en"}')
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
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
