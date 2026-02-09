import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final searchCtrl = TextEditingController();
  String category = "All";
  String sort = "Latest";

  // Demo store (in-memory). Backend nanti replace je.
  final List<_Listing> listings = [
    _Listing(
      id: "1",
      title: "Maggie Tengah Malam 🌙",
      desc: "Pickup Mahallah Zubair. Add telur +RM1.",
      price: 3.0,
      category: "Food",
      location: "Mahallah Zubair",
      openTime: "11PM - 2AM",
      sellerName: "Aqil",
      whatsapp: "60165443288",
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    _Listing(
      id: "2",
      title: "Print Notes A4 (Fast)",
      desc: "Hitam putih / warna. Boleh bind sekali.",
      price: 0.2,
      category: "Services",
      location: "KICT",
      openTime: "9AM - 10PM",
      sellerName: "Nana",
      whatsapp: "60123456789",
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    _Listing(
      id: "3",
      title: "Preloved Hoodie IIUM",
      desc: "Size L. Condition 9/10. COD UIA.",
      price: 25,
      category: "Items",
      location: "Around UIA",
      openTime: "Anytime",
      sellerName: "Iman",
      whatsapp: "60111222333",
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  List<_Listing> get filtered {
    final q = searchCtrl.text.trim().toLowerCase();
    var list = listings.where((x) {
      final matchSearch = q.isEmpty ||
          x.title.toLowerCase().contains(q) ||
          x.desc.toLowerCase().contains(q) ||
          x.location.toLowerCase().contains(q);
      final matchCat = category == "All" || x.category == category;
      return matchSearch && matchCat;
    }).toList();

    if (sort == "Price: Low") {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (sort == "Price: High") {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else {
      // Latest
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Student Market",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.add_business_rounded,
            onTap: _openCreateSheet,
          ),
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(textMain, muted),
          const SizedBox(height: 14),

          // Search
          _searchBar(textMain, muted),
          const SizedBox(height: 12),

          // Filters
          Row(
            children: [
              Expanded(child: _dropdownCat(muted)),
              const SizedBox(width: 10),
              Expanded(child: _dropdownSort(muted)),
            ],
          ),
          const SizedBox(height: 14),

          // List
          if (filtered.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  const Icon(Icons.storefront_outlined, color: UColors.darkMuted, size: 34),
                  const SizedBox(height: 10),
                  Text(
                    "No listing found.\nTry different keywords.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          else
            Column(
              children: filtered
                  .map((x) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _listingCard(x, textMain, muted),
                      ))
                  .toList(),
            ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _hero(Color textMain, Color muted) {
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      ),
      borderColor: UColors.gold.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: UColors.gold,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: UColors.gold.withAlpha(70),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: const Icon(Icons.store_rounded, color: Colors.black, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Support Student Business",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  "Maggie midnight, printing, preloved, services — semua ada sini.",
                  style: TextStyle(color: Colors.white.withAlpha(190), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;
    final bg = isDark ? const Color(0xFF0F172A) : UColors.lightInput;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: "Search maggie, print, hoodie, service…",
                hintStyle: TextStyle(color: muted),
                border: InputBorder.none,
              ),
            ),
          ),
          if (searchCtrl.text.isNotEmpty)
            IconButton(
              onPressed: () {
                searchCtrl.clear();
                setState(() {});
              },
              icon: Icon(Icons.close_rounded, color: muted),
            ),
        ],
      ),
    );
  }

  Widget _dropdownCat(Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final items = const ["All", "Food", "Items", "Services", "Rentals", "Other"];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: category,
          dropdownColor: isDark ? const Color(0xFF0B1220) : Colors.white,
          iconEnabledColor: muted,
          style: TextStyle(color: muted, fontWeight: FontWeight.w800),
          items: items
              .map((x) => DropdownMenuItem(value: x, child: Text("Category: $x")))
              .toList(),
          onChanged: (v) => setState(() => category = v ?? "All"),
        ),
      ),
    );
  }

  Widget _dropdownSort(Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final items = const ["Latest", "Price: Low", "Price: High"];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: sort,
          dropdownColor: isDark ? const Color(0xFF0B1220) : Colors.white,
          iconEnabledColor: muted,
          style: TextStyle(color: muted, fontWeight: FontWeight.w800),
          items: items.map((x) => DropdownMenuItem(value: x, child: Text("Sort: $x"))).toList(),
          onChanged: (v) => setState(() => sort = v ?? "Latest"),
        ),
      ),
    );
  }

  Widget _listingCard(_Listing x, Color textMain, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: UColors.gold.withAlpha(70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumb(x),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      x.title,
                      style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      x.desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill(Icons.local_offer_rounded, x.category, UColors.teal),
                        _pill(Icons.location_on_rounded, x.location, UColors.info),
                        _pill(Icons.schedule_rounded, x.openTime, UColors.warning),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.white.withAlpha(18)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: UColors.gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: UColors.gold.withAlpha(90)),
                      ),
                      child: const Icon(Icons.person_rounded, color: UColors.gold, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(x.sellerName, style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                          Text(_timeAgo(x.createdAt),
                              style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "RM ${x.price.toStringAsFixed(x.price < 1 ? 2 : 0)}",
                style: TextStyle(
                  color: UColors.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  shadows: [Shadow(color: UColors.gold.withAlpha(70), blurRadius: 18)],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: "Order",
                  icon: Icons.shopping_bag_rounded,
                  bg: UColors.gold,
                  onTap: () => _toast("Order: connect WhatsApp/API later."),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  text: "Chat Seller",
                  icon: Icons.chat_rounded,
                  bg: UColors.teal,
                  fg: Colors.black,
                  onTap: () => _toast("Chat: connect WhatsApp/API later."),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumb(_Listing x) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Colors.white.withAlpha(16) : Colors.black.withAlpha(10);

    if (x.imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(border: Border.all(color: border)),
          child: Image.memory(x.imageBytes!, fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: const Icon(Icons.image_rounded, color: UColors.darkMuted),
    );
  }

  Widget _pill(IconData icon, String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 14),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 11)),
        ],
      ),
    );
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateListingSheet(
        onCreate: (l) => setState(() => listings.insert(0, l)),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? UColors.darkGlass
            : UColors.lightGlass,
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    return "${diff.inDays} day ago";
  }
}

/// ================================
/// CREATE LISTING BOTTOM SHEET
/// ================================
class _CreateListingSheet extends StatefulWidget {
  final void Function(_Listing listing) onCreate;
  const _CreateListingSheet({required this.onCreate});

  @override
  State<_CreateListingSheet> createState() => _CreateListingSheetState();
}

class _CreateListingSheetState extends State<_CreateListingSheet> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final locationCtrl = TextEditingController(text: "Around UIA");
  final openCtrl = TextEditingController(text: "Anytime");
  final sellerCtrl = TextEditingController(text: "Student");
  final whatsappCtrl = TextEditingController(text: "60");

  String category = "Food";
  Uint8List? imageBytes;

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    locationCtrl.dispose();
    openCtrl.dispose();
    sellerCtrl.dispose();
    whatsappCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final textMain = isDark ? UColors.darkText : UColors.lightText;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white.withAlpha(16)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("Create Listing",
                        style: TextStyle(color: UColors.gold, fontWeight: FontWeight.w900, fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Let student buy from you — maggie midnight pun boleh 😄",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w600)),

                const SizedBox(height: 14),

                _sheetField("Title", "e.g. Maggie Tengah Malam", titleCtrl, textMain, muted, icon: Icons.title_rounded),
                const SizedBox(height: 12),
                _sheetField("Description", "details, add-on, etc", descCtrl, textMain, muted,
                    icon: Icons.notes_rounded, maxLines: 4),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _sheetField("Price (RM)", "e.g. 3", priceCtrl, textMain, muted,
                          icon: Icons.payments_rounded, keyboard: TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _catDropdown(textMain, muted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _sheetField("Location", "Mahallah / KICT / etc", locationCtrl, textMain, muted,
                    icon: Icons.location_on_rounded),
                const SizedBox(height: 12),
                _sheetField("Open Time", "e.g. 11PM - 2AM", openCtrl, textMain, muted, icon: Icons.schedule_rounded),
                const SizedBox(height: 12),
                _sheetField("Seller Name", "e.g. Aqil", sellerCtrl, textMain, muted, icon: Icons.person_rounded),
                const SizedBox(height: 12),
                _sheetField("WhatsApp (optional)", "e.g. 60165443288", whatsappCtrl, textMain, muted,
                    icon: Icons.chat_rounded, keyboard: TextInputType.phone),
                const SizedBox(height: 14),

                // Image
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: UColors.gold.withAlpha(18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: UColors.gold.withAlpha(90)),
                        ),
                        child: imageBytes == null
                            ? const Icon(Icons.image_rounded, color: UColors.gold)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(imageBytes!, fit: BoxFit.cover),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("Listing Image (optional)",
                              style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text("Upload photo untuk nampak lagi power.",
                              style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12)),
                        ]),
                      ),
                      PrimaryButton(
                        text: "Pick",
                        icon: Icons.upload_file_rounded,
                        bg: UColors.teal,
                        fg: Colors.black,
                        onTap: _pickImage,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: "Publish Listing",
                    icon: Icons.publish_rounded,
                    bg: UColors.gold,
                    onTap: _publish,
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Backend later: POST /market/listings + upload image to storage",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    String label,
    String hint,
    TextEditingController ctrl,
    Color textMain,
    Color muted, {
    required IconData icon,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
              color: UColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: muted),
              prefixIcon: Icon(icon, color: muted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _catDropdown(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final items = const ["Food", "Items", "Services", "Rentals", "Other"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CATEGORY",
          style: TextStyle(
            color: UColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: category,
              dropdownColor: isDark ? const Color(0xFF0B1220) : Colors.white,
              iconEnabledColor: muted,
              style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
              items: items.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setState(() => category = v ?? "Food"),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    // Web friendly
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (!mounted) return;
    if (res == null || res.files.isEmpty) return;
    setState(() => imageBytes = res.files.first.bytes);
  }

  void _publish() {
    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final price = double.tryParse(priceCtrl.text.trim()) ?? 0;

    if (title.isEmpty || desc.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Fill title + description + valid price"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? UColors.darkGlass
              : UColors.lightGlass,
        ),
      );
      return;
    }

    final l = _Listing(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      desc: desc,
      price: price,
      category: category,
      location: locationCtrl.text.trim().isEmpty ? "Around UIA" : locationCtrl.text.trim(),
      openTime: openCtrl.text.trim().isEmpty ? "Anytime" : openCtrl.text.trim(),
      sellerName: sellerCtrl.text.trim().isEmpty ? "Student" : sellerCtrl.text.trim(),
      whatsapp: whatsappCtrl.text.trim(),
      imageBytes: imageBytes,
      createdAt: DateTime.now(),
    );

    widget.onCreate(l);
    Navigator.pop(context);
  }
}

/// ================================
/// MODEL
/// ================================
class _Listing {
  final String id;
  final String title;
  final String desc;
  final double price;
  final String category;
  final String location;
  final String openTime;
  final String sellerName;
  final String whatsapp;
  final Uint8List? imageBytes;
  final DateTime createdAt;

  _Listing({
    required this.id,
    required this.title,
    required this.desc,
    required this.price,
    required this.category,
    required this.location,
    required this.openTime,
    required this.sellerName,
    required this.whatsapp,
    this.imageBytes,
    required this.createdAt,
  });
}
