# Smart Ranking for Hanoi Date Spots

Score each candidate from 0-100.

## Dimensions

- Date fit, 25: romantic/comfortable, good for talking, couple-friendly.
- Trend signal, 20: recent mentions, TikTok/Facebook/local media buzz, new opening/event.
- Practicality, 15: accessible, clear hours, easy booking, not too far.
- Vibe uniqueness, 15: memorable, photogenic, activity/story value.
- Reliability, 10: multiple sources, recent reviews, stable venue.
- Budget fit, 10: suitable for requested budget.
- Weather/time fit, 5: indoor/outdoor suitability for requested date/time.

## Penalties

- -10 if hours/prices are unclear.
- -10 if likely overcrowded and no booking advice.
- -15 if source is old and no recent corroboration.
- -20 if it seems unsafe, scammy, private, or not couple-friendly.

## Candidate Types

Classics:
- Hoan Kiem walk + old quarter cafe
- West Lake sunset / lakeside cafe
- French Quarter / Trang Tien / Opera House walk
- pottery/workshop/painting/cinema/live music

Trendy:
- new cafes/restaurants
- pop-up exhibitions
- TikTok-famous dessert/cafe spots
- weekend markets
- immersive/interactive activities
- photobooth/studio/check-in places

## Output Grouping

Group by user intent:
- Chill cafe / talk
- Romantic dinner / rooftop
- Activity date
- Photo/check-in trend
- Outdoor walk
- Rain-safe plan
- Budget-friendly plan
