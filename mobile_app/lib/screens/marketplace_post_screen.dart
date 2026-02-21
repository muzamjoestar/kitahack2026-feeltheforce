import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class MarketplacePostScreen extends StatefulWidget {
  const MarketplacePostScreen({super.key});

  @override
  State<MarketplacePostScreen> createState() => _MarketplacePostScreenState();
}

class _MarketplacePostScreenState extends State<MarketplacePostScreen> {
  final titleC = TextEditingController();
  final subtitleC = TextEditingController();
  final priceC = TextEditingController();
  final locationC = TextEditingController();
  final descC = TextEditingController();

  String cat = 'Services';

  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void dispose() {
    titleC.dispose();
    subtitleC.dispose();
    priceC.dispose();
    locationC.dispose();
    descC.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  IconData _iconByCat(String c) {
    switch (c) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Services':
        return Icons.handyman_rounded;
      case 'Shops':
        return Icons.shopping_bag_rounded;
      case 'Rent':
        return Icons.key_rounded;
      case 'Tickets':
        return Icons.confirmation_number_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (_) {
      _toast('Tak boleh pilih gambar. Cuba run semula.');
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
    });
  }

  void _publish() {
    final title = titleC.text.trim();
    final subtitle = subtitleC.text.trim();
    final location = locationC.text.trim();
    final desc = descC.text.trim();

    if (title.isEmpty) {
      _toast('Title wajib isi');
      return;
    }

    final p = double.tryParse(priceC.text.trim());
    if (p == null) {
      _toast('Price tak valid');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // TODO BACKEND (nanti):
    // 1) Upload _imageBytes ke storage -> dapatkan imageUrl
    // 2) POST /marketplace/posts simpan title/desc/price/cat/location/imageUrl/userId
    final post = <String, dynamic>{
      'id': 'mp_$now',
      'title': title,
      'subtitle': subtitle.isEmpty ? 'New • just posted' : subtitle,
      'cat': cat,
      'price': p,
      'rating': 5.0, // frontend default
      'accent': UColors.gold,
      'icon': _iconByCat(cat),
      'createdAt': now,
      'isMine': true,
      'seller': 'You',
      'location': location.isEmpty ? 'Campus' : location,
      'desc': desc,
      'phone': '',

      // ✅ frontend image (bytes) for preview/listing
      'imageBytes': _imageBytes,
      'imageName': _imageName ?? '',

      // ✅ backend nanti akan guna url
      'imageUrl': '',
    };

    Navigator.of(context).pop(post);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Scaffold(
      backgroundColor: isDark ? UColors.darkBg : UColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textMain),
        title: Text('Post Service', style: TextStyle(color: textMain, fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Category', muted),
                    const SizedBox(height: 8),
                    _dropdown(textMain, muted),
                    const SizedBox(height: 12),

                    _label('Title*', muted),
                    const SizedBox(height: 8),
                    _field(titleC, 'Contoh: Print & Binding', textMain, muted),
                    const SizedBox(height: 12),

                    _label('Subtitle', muted),
                    const SizedBox(height: 8),
                    _field(subtitleC, 'Contoh: Fast • same day', textMain, muted),
                    const SizedBox(height: 12),

                    _label('Price (RM)*', muted),
                    const SizedBox(height: 8),
                    _field(priceC, 'Contoh: 12.50', textMain, muted, keyboard: TextInputType.number),
                    const SizedBox(height: 12),

                    _label('Location', muted),
                    const SizedBox(height: 8),
                    _field(locationC, 'Contoh: Zubair Block D 3.2', textMain, muted),
                    const SizedBox(height: 12),

                    _label('Image (upload)', muted),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: _imageBytes == null ? 'Upload image' : 'Change image',
                            icon: Icons.image_rounded,
                            onTap: _pickImage,
                          ),
                        ),
                        if (_imageBytes != null) ...[
                          const SizedBox(width: 10),
                          IconSquareButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: _removeImage,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    _preview(muted),
                    const SizedBox(height: 12),

                    _label('Description', muted),
                    const SizedBox(height: 8),
                    _field(descC, 'Detail service, masa siap, syarat, dll.', textMain, muted, maxLines: 4),

                    const SizedBox(height: 14),
                    PrimaryButton(
                      text: 'Publish',
                      icon: Icons.cloud_upload_rounded,
                      onTap: _publish,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'NOTE BACKEND (nanti):\n'
                '• Upload gambar -> storage (Firebase Storage/S3) -> dapat imageUrl\n'
                '• Simpan post ke database (title, price, cat, location, imageUrl, userId)',
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t, Color muted) => Text(t, style: TextStyle(color: muted, fontWeight: FontWeight.w800));

  Widget _field(
    TextEditingController c,
    String hint,
    Color textMain,
    Color muted, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: muted.withAlpha(60)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
      ),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: muted.withAlpha(60)),
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: cat,
          dropdownColor: isDark ? const Color(0xFF0D0F14) : Colors.white,
          iconEnabledColor: muted,
          style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
          items: const [
            DropdownMenuItem(value: 'Food', child: Text('Food')),
            DropdownMenuItem(value: 'Services', child: Text('Services')),
            DropdownMenuItem(value: 'Shops', child: Text('Shops')),
            DropdownMenuItem(value: 'Rent', child: Text('Rent')),
            DropdownMenuItem(value: 'Tickets', child: Text('Tickets')),
          ],
          onChanged: (v) => setState(() => cat = v ?? 'Services'),
        ),
      ),
    );
  }

  Widget _preview(Color muted) {
    if (_imageBytes == null) {
      return Row(
        children: [
          Icon(Icons.image_outlined, color: muted),
          const SizedBox(width: 8),
          Text('Preview akan keluar lepas upload', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_imageBytes!, fit: BoxFit.cover),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                child: Text(
                  _imageName ?? 'image',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}