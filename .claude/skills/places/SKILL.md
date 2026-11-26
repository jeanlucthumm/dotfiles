---
name: places
description: Google Maps from the shell — place ratings and reviews, "X near Y", travel times with live traffic, transit directions. Use instead of browsing Maps or Yelp.
allowed-tools: Bash(places:*)
---

```
Usage: places search [-n N] [--reviews] [--near WHERE] QUERY...
       places get PLACE_ID
       places nearby [-n N] [--radius M] WHERE
       places route [--mode MODE] [--depart TIME | --arrive TIME] FROM TO

Google Maps places, reviews and routes. Prints JSON lines.

  search   Text search, e.g. "ramen in the Mission, SF". Up to N places
           (default 5, max 20) with rating, price, open-now and a Gemini
           summary of their reviews. --reviews adds each place's 5 most
           relevant reviews. --near lists places nearest WHERE first,
           with no distance cutoff.
  get      One place by id: summary, 5 reviews, hours, food/service
           features, phone, website.
  nearby   What's at WHERE: up to N places (default 5, max 20) within M
           meters (default 100), nearest first. Name, type and address
           only, so it's a cheaper call than search.
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
```
