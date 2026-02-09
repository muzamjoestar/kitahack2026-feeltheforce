import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

enum TxType { topup, spend }

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final amountCtrl = TextEditingController(text: "10");
  final noteCtrl = TextEditingController();
  final searchCtrl = TextEditingController();

  double balance = 0.0;
  bool loading = false;
  bool hideBalance = false;

  TxTypeFilter filter = TxTypeFilter.all;

  // attachment (web-safe: we keep only name)
  String? attachedFileName;

  final List<_Tx> txs = [];

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  // ---------- Actions ----------
  Future<void> _pickReceipt() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
      );
      if (!mounted) return;
      if (res == null || res.files.isEmpty) return;

      setState(() => attachedFileName = res.files.single.name);
      _toast("Attached: ${res.files.single.name}");
    } catch (e) {
      _toast("File picker error: $e");
    }
  }

  Future<void> _topup(double amount) async {
    if (amount <= 0) {
      _toast("Enter valid amount");
      return;
    }
    setState(() => loading = true);

    await Future.delayed(const Duration(milliseconds: 650)); // simulate processing
    if (!mounted) return;

    setState(() {
      balance += amount;
      txs.insert(
        0,
        _Tx(
          type: TxType.topup,
          title: "Topup",
          subtitle: _niceNote(noteCtrl.text),
          amount: amount,
          time: DateTime.now(),
          attachmentName: attachedFileName,
        ),
      );

      loading = false;
      noteCtrl.clear();
      attachedFileName = null;
    });

    _toast("Topup RM${amount.toStringAsFixed(2)} ✅");
  }

  Future<void> _spend(double amount) async {
    if (amount <= 0) {
      _toast("Enter valid amount");
      return;
    }
    if (amount > balance) {
      _toast("Insufficient balance");
      return;
    }

    setState(() => loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      balance -= amount;
      txs.insert(
        0,
        _Tx(
          type: TxType.spend,
          title: "Payment",
          subtitle: _niceNote(noteCtrl.text.isEmpty ? "Service payment" : noteCtrl.text),
          amount: amount,
          time: DateTime.now(),
          attachmentName: attachedFileName,
        ),
      );

      loading = false;
      noteCtrl.clear();
      attachedFileName = null;
    });

    _toast("Paid RM${amount.toStringAsFixed(2)} ✅");
  }

  void _clearHistory() {
    setState(() => txs.clear());
    _toast("History cleared");
  }

  // ---------- Derived ----------
  List<_Tx> get filteredTxs {
    final q = searchCtrl.text.trim().toLowerCase();

    return txs.where((t) {
      if (filter == TxTypeFilter.topup && t.type != TxType.topup) return false;
      if (filter == TxTypeFilter.spend && t.type != TxType.spend) return false;

      if (q.isEmpty) return true;
      final hay = "${t.title} ${t.subtitle} ${t.amount}".toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  double get totalTopup => txs.where((t) => t.type == TxType.topup).fold(0.0, (a, b) => a + b.amount);
  double get totalSpend => txs.where((t) => t.type == TxType.spend).fold(0.0, (a, b) => a + b.amount);

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Wallet",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            onTap: () => setState(() => hideBalance = !hideBalance),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroBalanceCard(textMain, muted),
          const SizedBox(height: 14),
          _miniStatsRow(muted),
          const SizedBox(height: 18),

          Text(
            "QUICK TOPUP",
            style: TextStyle(
              color: UColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          _quickAmountRow(muted),

          const SizedBox(height: 16),

          Text(
            "TRANSACTION",
            style: TextStyle(
              color: UColors.gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),

          _actionComposer(textMain, muted),

          const SizedBox(height: 14),
          _searchAndFilter(textMain, muted),
          const SizedBox(height: 10),

          _historyHeader(muted),
          const SizedBox(height: 10),

          if (filteredTxs.isEmpty)
            GlassCard(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded, color: muted, size: 34),
                  const SizedBox(height: 8),
                  Text(
                    "No transactions yet.",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Topup or pay a service to see history here.",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: filteredTxs
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _txTile(t, textMain, muted),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _heroBalanceCard(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF0F172A), Color(0xFF020617)]
          : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    );

    return GlassCard(
      gradient: grad,
      borderColor: UColors.gold.withAlpha(90),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: UColors.gold.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: UColors.gold.withAlpha(80)),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: UColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                "UNIPAY BALANCE",
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hideBalance ? "RM ****" : "RM ${balance.toStringAsFixed(2)}",
                style: TextStyle(
                  color: textMain,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Web mode • Offline wallet",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _miniStatsRow(Color muted) {
    return Row(
      children: [
        Expanded(
          child: _miniStat("Total Topup", "RM ${totalTopup.toStringAsFixed(0)}", UColors.success, muted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat("Total Spend", "RM ${totalSpend.toStringAsFixed(0)}", UColors.warning, muted),
        ),
      ],
    );
  }

  Widget _miniStat(String a, String b, Color accent, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withAlpha(60),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 3),
              Text(b, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _quickAmountRow(Color muted) {
    final amounts = [5, 10, 20, 50, 100];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: amounts.map((v) {
        return GestureDetector(
          onTap: loading ? null : () => _topup(v.toDouble()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: muted, size: 18),
                const SizedBox(width: 8),
                Text("RM $v", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _actionComposer(Color textMain, Color muted) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AMOUNT (RM)", style: TextStyle(color: muted, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w900, fontSize: 16),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "10",
                      hintStyle: TextStyle(color: muted),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconSquareButton(
                icon: Icons.attach_file_rounded,
                onTap: _pickReceipt,
                badge: attachedFileName == null
                    ? null
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: UColors.success, shape: BoxShape.circle),
                      ),
              ),
            ],
          ),
          if (attachedFileName != null) ...[
            const SizedBox(height: 10),
            Text(
              "Attached: $attachedFileName",
              style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Text("NOTE (OPTIONAL)", style: TextStyle(color: muted, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(18)),
            ),
            child: TextField(
              controller: noteCtrl,
              style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "e.g. Topup for Runner / Pay Barber",
                hintStyle: TextStyle(color: muted),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: loading ? "..." : "Topup",
                  icon: Icons.add_rounded,
                  bg: UColors.gold,
                  onTap: loading ? () {} : () => _topup(_amountFromField()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  text: loading ? "..." : "Pay",
                  icon: Icons.payments_rounded,
                  bg: UColors.teal,
                  fg: Colors.black,
                  onTap: loading ? () {} : () => _spend(_amountFromField()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchAndFilter(Color textMain, Color muted) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: textMain, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search history...",
                      hintStyle: TextStyle(color: muted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _filterPill(muted),
      ],
    );
  }

  Widget _filterPill(Color muted) {
    String label = "All";
    if (filter == TxTypeFilter.topup) label = "Topup";
    if (filter == TxTypeFilter.spend) label = "Spend";

    return GestureDetector(
      onTap: () async {
        final picked = await showModalBottomSheet<TxTypeFilter>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _filterSheet(),
        );
        if (!mounted) return;
        if (picked != null) setState(() => filter = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withAlpha(18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, color: muted, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _filterSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFFFFFFF);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 46, height: 5, decoration: BoxDecoration(color: Colors.grey.withAlpha(60), borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 14),
          _sheetItem("All", TxTypeFilter.all),
          _sheetItem("Topup only", TxTypeFilter.topup),
          _sheetItem("Spend only", TxTypeFilter.spend),
        ],
      ),
    );
  }

  Widget _sheetItem(String title, TxTypeFilter v) {
    return ListTile(
      onTap: () => Navigator.pop(context, v),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.withAlpha(150)),
    );
  }

  Widget _historyHeader(Color muted) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "HISTORY",
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
        ),
        GestureDetector(
          onTap: _clearHistory,
          child: Text(
            "Clear",
            style: TextStyle(
              color: UColors.danger,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        )
      ],
    );
  }

  Widget _txTile(_Tx t, Color textMain, Color muted) {
    final isTopup = t.type == TxType.topup;
    final accent = isTopup ? UColors.success : UColors.warning;
    final sign = isTopup ? "+" : "-";

    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: BorderRadius.circular(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withAlpha(120)),
            ),
            child: Icon(
              isTopup ? Icons.add_circle_rounded : Icons.payments_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                t.title,
                style: TextStyle(color: textMain, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                "${t.subtitle} • ${_timeLabel(t.time)}",
                style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (t.attachmentName != null) ...[
                const SizedBox(height: 4),
                Text(
                  "📎 ${t.attachmentName}",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ]),
          ),
          const SizedBox(width: 10),
          Text(
            "$sign RM${t.amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: isTopup ? UColors.success : textMain,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  double _amountFromField() {
    final v = double.tryParse(amountCtrl.text.trim()) ?? 0;
    return v.clamp(0, 999999);
  }

  String _niceNote(String s) {
    final t = s.trim();
    return t.isEmpty ? "No note" : t;
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
}

enum TxTypeFilter { all, topup, spend }

class _Tx {
  final TxType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime time;
  final String? attachmentName;

  _Tx({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
    this.attachmentName,
  });
}
