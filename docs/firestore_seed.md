# Firestore Seed Data

The home screen reads these collections from Firebase project
`mxpertztest-da18a`.

## `home/content`

```json
{
  "greeting": "Hi, Andrea",
  "bannerTitle": "JUST FOR you",
  "bannerSubtitle": "30% OFF"
}
```

## `categories`

Create one document per item. Auto IDs are fine.

```json
[
  { "name": "Beauty", "icon": "beauty" },
  { "name": "Offers", "icon": "offer" },
  { "name": "Fashion", "icon": "fashion" },
  { "name": "Home", "icon": "home" },
  { "name": "Shirt", "icon": "fashion" },
  { "name": "Woman Bag", "icon": "bag" },
  { "name": "Dress", "icon": "fashion" },
  { "name": "Mobiles", "icon": "phone" }
]
```

## `products`

Create one document per item. Auto IDs are fine.

```json
[
  { "name": "Multi Kit", "price": 500, "rating": 4.6, "reviews": 86, "icon": "beauty" },
  { "name": "Lipstick", "price": 400, "rating": 4.6, "reviews": 86, "icon": "lipstick" },
  { "name": "Skin Care", "price": 650, "rating": 4.8, "reviews": 52, "icon": "beauty" },
  { "name": "Hand Bag", "price": 900, "rating": 4.4, "reviews": 41, "icon": "bag" }
]
```
