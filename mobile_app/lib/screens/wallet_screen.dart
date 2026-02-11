import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const _kBalanceKey = 'wallet_balance_v1';
  static const _kTxKey = 'wallet_txs_v1';

  double balance = 39.50;
  final List<_WalletTx> txs = [];

  bool loading = false;

  // Quick topup presets
  final List<int> presets = const [5, 10, 20, 50];

  // manual amount
  final TextEditingController amountCtrl = TextEditingController(text: "3");

  @override
  void initState() {
    super.initState();
    _loadLocal();
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  // ================== PERSIST ==================
  Future<void> _loadLocal() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      final b = prefs.getDouble(_kBalanceKey);
      final raw = prefs.getString(_kTxKey);

      final loadedTxs = <_WalletTx>[];
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final e in list) {
            if (e is Map<String, dynamic>) {
              loadedTxs.add(_WalletTx.fromJson(e));
            } else if (e is Map) {
              loadedTxs.add(_WalletTx.fromJson(Map<String, dynamic>.from(e)));
            }
          }
        }
      }

      setState(() {
        if (b != null) balance = b;
        txs
          ..clear()
          ..addAll(loadedTxs);
      });
    } catch (_) {
      // kalau error, just fallback to default state
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kBalanceKey, balance);
      final raw = jsonEncode(txs.map((e) => e.toJson()).toList());
      await prefs.setString(_kTxKey, raw);
    } catch (_) {
      // ignore silently
    }
  }

  // ================== ACTIONS ==================
  double _amountFromField() {
    final v = double.tryParse(amountCtrl.text.trim());
    if (v == null) return 0;
    if (v.isNaN || v.isInfinite) return 0;
    return v <= 0 ? 0 : v;
  }

  Future<void> _topup(double amount) async {
    if (amount <= 0) {
      _toast("Enter valid amount.");
      return;
    }

    setState(() => loading = true);
    try {
      setState(() {
        balance += amount;
        txs.insert(
          0,
          _WalletTx(
            type: _TxType.topup,
            amount: amount,
            title: "Top up",
            subtitle: "Wallet reload",
            at: DateTime.now(),
          ),
        );
        if (txs.length > 80) txs.removeRange(80, txs.length);
      });
      await _saveLocal();
      _toast("Topup success ✅");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _spend(double amount) async {
    if (amount <= 0) {
      _toast("Enter valid amount.");
      return;
    }
    if (amount > balance) {
      _toast("Insufficient balance.");
      return;
    }

    setState(() => loading = true);
    try {
      setState(() {
        balance -= amount;
        txs.insert(
          0,
          _WalletTx(
            type: _TxType.spend,
            amount: amount,
            title: "Payment",
            subtitle: "Service payment",
            at: DateTime.now(),
          ),
        );
        if (txs.length > 80) txs.removeRange(80, txs.length);
      });
      await _saveLocal();
      _toast("Paid ✅");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resetWallet() async {
    setState(() => loading = true);
    try {
      setState(() {
        balance = 0;
        txs.clear();
      });
      await _saveLocal();
      _toast("Reset done.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark ? UColors.darkGlass : UColors.lightGlass,
      ),
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fg = isDark ? Colors.white : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    final chipBg = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6);
    final chipBorder = isDark ? Colors.white.withAlpha(18) : border;

    return PremiumScaffold(
      title: "Wallet",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.refresh_rounded,
            onTap: loading ? () {} : _loadLocal,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.delete_outline_rounded,
            onTap: loading ? () {} : _resetWallet,
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroCard(isDark: isDark, fg: fg, muted: muted),
            const SizedBox(height: 14),

            _sectionTitle("Quick Topup", isDark: isDark),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final v = presets[i];
                  return GestureDetector(
                    onTap: loading ? null : () => _topup(v.toDouble()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: chipBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: muted, size: 18),
                          const SizedBox(width: 8),
                          Text("RM $v", style: TextStyle(color: fg, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),
            _sectionTitle("Manual Amount", isDark: isDark),
            const SizedBox(height: 10),
            _amountRow(isDark: isDark, fg: fg, muted: muted, border: border),

            const SizedBox(height: 18),
            _sectionTitle("Transactions", isDark: isDark),
            const SizedBox(height: 10),
            _txList(isDark: isDark, fg: fg, muted: muted, border: border),
          ],
        ),
      ),

      bottomBar: _bottomBar(isDark: isDark, fg: fg, muted: muted, border: border),
    );
  }

  Widget _sectionTitle(String t, {required bool isDark}) {
    return Text(
      t.toUpperCase(),
      style: const TextStyle(
        color: UColors.gold,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        fontSize: 11,
      ),
    );
  }

  Widget _heroCard({required bool isDark, required Color fg, required Color muted}) {
    final bg = isDark ? const Color(0xFF0B1220) : UColors.lightCard;
    final br = isDark ? Colors.white.withAlpha(18) : UColors.lightBorder;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: UColors.gold.withAlpha(140),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: br),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: UColors.gold.withAlpha(isDark ? 20 : 28),
                border: Border.all(color: UColors.gold.withAlpha(120)),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: UColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Current Balance", style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  "RM ${balance.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: UColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: UColors.gold.withAlpha(60), blurRadius: 18)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stored locally (restart app tak hilang).",
                  style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
            if (loading)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _amountRow({
    required bool isDark,
    required Color fg,
    required Color muted,
    required Color border,
  }) {
    final fieldBg = isDark ? const Color(0xFF0B1220) : UColors.lightInput;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.payments_rounded, color: muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      hintText: "Amount (e.g. 3)",
                      hintStyle: TextStyle(color: muted),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Text("RM", style: TextStyle(color: muted, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: loading ? "..." : "Topup",
                  icon: Icons.add_rounded,
                  bg: UColors.teal,
                  onTap: loading ? () {} : () => _topup(_amountFromField()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  text: loading ? "..." : "Pay",
                  icon: Icons.arrow_upward_rounded,
                  bg: UColors.gold,
                  onTap: loading ? () {} : () => _spend(_amountFromField()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _txList({
    required bool isDark,
    required Color fg,
    required Color muted,
    required Color border,
  }) {
    if (txs.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, color: muted, size: 32),
            const SizedBox(height: 10),
            Text("No transactions yet.", style: TextStyle(color: fg, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text("Try topup RM5 then pay RM3.", style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Column(
      children: txs.map((t) {
        final isIn = t.type == _TxType.topup;
        final sign = isIn ? "+" : "-";
        final color = isIn ? UColors.success : UColors.warning;

        final bg = isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(4);
        final br = isDark ? Colors.white.withAlpha(18) : border;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: br),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withAlpha(18),
                  border: Border.all(color: color.withAlpha(120)),
                ),
                child: Icon(isIn ? Icons.add_rounded : Icons.arrow_upward_rounded, color: color),
              ),
              title: Text(t.title, style: TextStyle(color: fg, fontWeight: FontWeight.w900)),
              subtitle: Text(
                "${t.subtitle} • ${_fmtTime(t.at)}",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              trailing: Text(
                "$sign RM ${t.amount.toStringAsFixed(2)}",
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _fmtTime(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}";
  }

  Widget _bottomBar({
    required bool isDark,
    required Color fg,
    required Color muted,
    required Color border,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: UColors.gold.withAlpha(140),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Current Balance", style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      "RM ${balance.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: UColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: UColors.gold.withAlpha(60), blurRadius: 16)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: PrimaryButton(
                  text: "Spend RM3",
                  icon: Icons.shopping_bag_rounded,
                  bg: UColors.gold,
                  onTap: loading ? () {} : () => _spend(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== MODEL ==================
enum _TxType { topup, spend }

class _WalletTx {
  final _TxType type;
  final double amount;
  final String title;
  final String subtitle;
  final DateTime at;

  const _WalletTx({
    required this.type,
    required this.amount,
    required this.title,
    required this.subtitle,
    required this.at,
  });

  Map<String, dynamic> toJson() => {
        "type": type.name,
        "amount": amount,
        "title": title,
        "subtitle": subtitle,
        "at": at.toIso8601String(),
      };

  factory _WalletTx.fromJson(Map<String, dynamic> json) {
    final typeStr = (json["type"] ?? "topup").toString();
    final parsedType = typeStr == "spend" ? _TxType.spend : _TxType.topup;

    final amtRaw = json["amount"];
    final amt = (amtRaw is num) ? amtRaw.toDouble() : double.tryParse("$amtRaw") ?? 0;

    final atRaw = (json["at"] ?? "").toString();
    final at = DateTime.tryParse(atRaw) ?? DateTime.now();

    return _WalletTx(
      type: parsedType,
      amount: amt,
      title: (json["title"] ?? "").toString(),
      subtitle: (json["subtitle"] ?? "").toString(),
      at: at,
    );
  }
}
