#!/usr/bin/env bash
# Built by where-is-jl.nix, which sets $token_file and puts curl, jq and date
# on PATH. --place also needs `places` (gcp.nix) on the caller's PATH.

usage() {
  cat <<'EOF'
Usage: where-is-jl [--place]

Where Jean-Luc's phone is, from Home Assistant: zone, street address (the
phone's own reverse geocode), coordinates with GPS accuracy, the age of the
fix, and the straight-line distance from home. iOS reports only on
significant moves and zone crossings, so read the fix age before saying where
he is now.

  --place  Also ask Google Maps for the places nearest him and the drive home
           with live traffic (about $0.04). Worth it when he's outside every
           zone and the address doesn't say what he's doing there. Skipped
           at home; inside another zone only the drive home is looked up.
EOF
}

place=false
case "${1:-}" in
  "") ;;
  --place) place=true ;;
  -h | --help) usage; exit ;;
  *) usage >&2; exit 2 ;;
esac

# The token goes in on stdin, so it never shows up in ps.
state() {
  curl -sS --fail-with-body -H @- "http://127.0.0.1:8123/api/states/$1" \
    <<<"Authorization: Bearer $(<"$token_file")"
}

person=$(state person.jean_luc)
home=$(state zone.home)
# 404 while the sensor is disabled in HA.
geo=$(state sensor.jean_lucs_iphone_geocoded_location 2>/dev/null) || geo=null

jq -nr --argjson p "$person" --argjson h "$home" --argjson g "$geo" '
  # HA timestamps are UTC with microseconds: 2026-11-26T22:32:10.123456+00:00
  def ts: sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601;
  def ago: (now - .) / 60
    | if . < 1 then "just now" elif . < 60 then "\(floor) min ago"
      elif . < 2880 then "\(. / 60 | floor) h ago" else "\(. / 1440 | floor) days ago" end;
  def rad: . * (1 | atan) / 45;
  def miles($a; $b):
    (($b.latitude - $a.latitude) | rad) as $dlat | (($b.longitude - $a.longitude) | rad) as $dlng
    | ($dlat / 2 | sin | . * .) + ($a.latitude | rad | cos) * ($b.latitude | rad | cos) * ($dlng / 2 | sin | . * .)
    | sqrt | asin * 2 * 3958.8;
  # iOS fills missing placemark fields with "N/A".
  def known: select(. != null and . != "N/A" and . != "" and . != []);

  $p.attributes as $a | ($p.last_updated | ts) as $fix
  | "zone: \({home: "home", not_home: "none"}[$p.state] // $p.state)",
    ($g | select(. and (.state | IN("unknown", "unavailable") | not))
      | .attributes as $ga | (.last_updated | ts) as $t
      | (.state | split("\n") | map(known) | join(", ")) as $addr
      | [($ga.Name | known | select(. as $n | $addr | contains($n) | not)), $addr,
         ($ga["Areas Of Interest"] | known | if type == "array" then join(", ") else . end | "(\(.))")]
      | "address: \(join(" "))" + if $fix - $t > 600 then " (as of \($t | ago))" else "" end),
    ($a | select(.latitude) | "coords: \(.latitude),\(.longitude) ±\(.gps_accuracy // "?") m"),
    "fix: \($fix | ago)",
    ($a | select(.latitude and $p.state != "home")
      | miles(.; $h.attributes) | "from home: \(if . < 0.1 then "<0.1" else . * 10 | round / 10 end) mi")'

$place || exit 0
ll='.attributes | select(.latitude) | "\(.latitude),\(.longitude)"'
zone=$(jq -r .state <<<"$person")
here=$(jq -r "$ll" <<<"$person")
[[ $zone != home && -n $here ]] || exit 0

if [[ $zone == not_home ]]; then
  # Search the fix's accuracy circle, kept between 50 and 500 m.
  radius=$(jq '[.attributes.gps_accuracy // 0, 50] | max | [., 500] | min' <<<"$person")
  places nearby -n 5 --radius "$radius" "$here" | jq -rs --arg r "$radius" '
    if . == [] then "near: no places within \($r) m"
    else "near (closest first): " + (map(.name + if .type then " (\(.type))" else "" end) | join(", ")) end'
fi
places route "$here" "$(jq -r "$ll" <<<"$home")" \
  | jq -rs '.[0] | "drive home: \(.duration) (\(.no_traffic) without traffic)"'
