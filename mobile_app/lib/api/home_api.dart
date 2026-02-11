import 'dart:async';

class HomeApi {
  final String baseUrl;
  const HomeApi({required this.baseUrl});

  Future<Map<String, dynamic>> fetchHome() async {
    // ✅ simulate network delay (tak akan loading forever)
    await Future.delayed(const Duration(milliseconds: 600));

    return {
      "user": {
        "name": "Muhammad Aqil",
        "avatarUrl": "", // kosong pun ok
        "verified": true,
      },
      "wallet": {"balance": 12.50},
      "stats": {
        "ordersThisWeek": 3,
        "savedThisMonth": 8,
        "rating": 4.9,
      },
      "services": [
        {"label": "Runner", "route": "/runner", "icon": "run", "color": "info"},
        {"label": "Transport", "route": "/transport", "icon": "car", "color": "warning"},
        {"label": "Print", "route": "/print", "icon": "print", "color": "gold"},
        {"label": "Parcel", "route": "/parcel", "icon": "box", "color": "success"},
        {"label": "Express", "route": "/express", "icon": "run", "color": "cyan"},
        {"label": "Wallet", "route": "/wallet", "icon": "wallet", "color": "purple"},
        {"label": "Marketplace", "route": "/marketplace", "icon": "market", "color": "gold"},
        {"label": "More", "route": "/more", "icon": "grid", "color": "gold"},
      ],
      "recent": [
        {
          "title": "Runner Order",
          "type": "Delivery",
          "when": "Today",
          "amount": -5.00,
          "icon": "run",
          "color": "info"
        },
        {
          "title": "Wallet Topup",
          "type": "Topup",
          "when": "Yesterday",
          "amount": 10.00,
          "icon": "wallet",
          "color": "success"
        },
      ],
      "quick": [
        {
          "title": "Repeat last order",
          "subtitle": "Runner pickup from Mahallah",
          "route": "/runner"
        },
        {
          "title": "Sell on Marketplace",
          "subtitle": "Post item or service",
          "route": "/marketplace"
        },
        {
          "title": "Verify identity",
          "subtitle": "Unlock seller & driver features",
          "route": "/verify-identity"
        },
      ]
    };
  }
}
