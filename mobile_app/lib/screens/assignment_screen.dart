import 'package:flutter/material.dart';
import '../ui/uniserve_ui.dart';
import '../theme/colors.dart';

enum AssignmentType { report, slides, coding }

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  // user inputs
  AssignmentType type = AssignmentType.report;
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: "1"); // pages/slides/tasks
  final dueCtrl = TextEditingController(); // just text for now
  final finalPriceCtrl = TextEditingController(); // optional override

  // add-ons
  bool addReferences = false; // +8
  bool addPlagiarism = false; // +10
  bool addDiagrams = false; // +6
  bool urgent = false; // +30%

  // rules (kau boleh adjust bila-bila)
  static const double baseFee = 5.0;
  static const double minPrice = 15.0;

  static const double rateReportPerPage = 6.0;
  static const double rateSlidesPerSlide = 4.0;
  static const double rateCodingPerTask = 20.0;

  static const double addonReferences = 8.0;
  static const double addonPlagiarism = 10.0;
  static const double addonDiagrams = 6.0;

  static const double urgentMultiplier = 1.30;

  int get qty {
    final v = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    return v.clamp(0, 9999);
  }

  double get unitRate {
    switch (type) {
      case AssignmentType.report:
        return rateReportPerPage;
      case AssignmentType.slides:
        return rateSlidesPerSlide;
      case AssignmentType.coding:
        return rateCodingPerTask;
    }
  }

  String get qtyLabel {
    switch (type) {
      case AssignmentType.report:
        return "Pages";
      case AssignmentType.slides:
        return "Slides";
      case AssignmentType.coding:
        return "Tasks";
    }
  }

  double get addonsTotal {
    double s = 0;
    if (addReferences) s += addonReferences;
    if (addPlagiarism) s += addonPlagiarism;
    if (addDiagrams) s += addonDiagrams;
    return s;
  }

  double get estimatedBeforeUrgent {
    final subtotal = baseFee + (qty * unitRate) + addonsTotal;
    return subtotal < minPrice ? minPrice : subtotal;
  }

  double get estimatedTotal {
    final v = estimatedBeforeUrgent;
    if (!urgent) return v;
    return (v * urgentMultiplier);
  }

  double? get finalOverride {
    final t = finalPriceCtrl.text.trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null) return null;
    return v.clamp(0, 999999);
  }

  double get payable => finalOverride ?? estimatedTotal;

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    qtyCtrl.dispose();
    dueCtrl.dispose();
    finalPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark ? UColors.darkText : UColors.lightText;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return PremiumScaffold(
      title: "Assignment Helper",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconSquareButton(
            icon: Icons.info_outline_rounded,
            onTap: () => _toast("Auto quote + breakdown. Final price boleh override."),
          ),
        )
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // hero
          GlassCard(
            borderColor: UColors.info.withAlpha(110),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: UColors.info.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: UColors.info.withAlpha(100)),
                  ),
                  child: const Icon(Icons.assignment_rounded, color: UColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Submit assignment details. System will estimate price automatically.",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 1) type selector
          Text("1) TYPE",
              style: TextStyle(
                color: UColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 11,
              )),
          const SizedBox(height: 10),
          _typeChips(muted),
          const SizedBox(height: 16),

          // 2) details
          Text("2) DETAILS",
              style: TextStyle(
                color: UColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 11,
              )),
          const SizedBox(height: 10),

          PremiumField(
            label: "Title",
            hint: "e.g. CSC3101 Report (Chapter 3)",
            controller: titleCtrl,
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 12),

          PremiumField(
            label: "Description",
            hint: "Explain what you need (format, topic, rubric, etc.)",
            controller: descCtrl,
            icon: Icons.description_rounded,
            maxLines: 4,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: PremiumField(
                  label: qtyLabel,
                  hint: "Enter number",
                  controller: qtyCtrl,
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PremiumField(
                  label: "Due (optional)",
                  hint: "e.g. Tomorrow 11PM",
                  controller: dueCtrl,
                  icon: Icons.calendar_month_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3) add-ons
          Text("3) ADD-ONS",
              style: TextStyle(
                color: UColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 11,
              )),
          const SizedBox(height: 10),

          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _toggleRow(
                  title: "References (IEEE/APA)",
                  subtitle: "+RM ${addonReferences.toStringAsFixed(0)}",
                  value: addReferences,
                  onChanged: (v) => setState(() => addReferences = v),
                ),
                const SizedBox(height: 10),
                _toggleRow(
                  title: "Plagiarism Check",
                  subtitle: "+RM ${addonPlagiarism.toStringAsFixed(0)}",
                  value: addPlagiarism,
                  onChanged: (v) => setState(() => addPlagiarism = v),
                ),
                const SizedBox(height: 10),
                _toggleRow(
                  title: "Diagrams / Figures",
                  subtitle: "+RM ${addonDiagrams.toStringAsFixed(0)}",
                  value: addDiagrams,
                  onChanged: (v) => setState(() => addDiagrams = v),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withAlpha(18)),
                const SizedBox(height: 12),
                _toggleRow(
                  title: "Urgent (same-day)",
                  subtitle: "+30%",
                  value: urgent,
                  onChanged: (v) => setState(() => urgent = v),
                  highlight: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4) pricing
          Text("4) PRICING",
              style: TextStyle(
                color: UColors.gold,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                fontSize: 11,
              )),
          const SizedBox(height: 10),

          GlassCard(
            borderColor: UColors.gold.withAlpha(110),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line("Base Fee", "RM ${baseFee.toStringAsFixed(0)}", muted),
                const SizedBox(height: 6),
                _line("$qtyLabel × Rate", "RM ${(qty * unitRate).toStringAsFixed(0)}", muted,
                    smallHint: "(RM ${unitRate.toStringAsFixed(0)} each)"),
                const SizedBox(height: 6),
                _line("Add-ons", "RM ${addonsTotal.toStringAsFixed(0)}", muted),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withAlpha(18)),
                const SizedBox(height: 8),
                _line("Estimated (before urgent)",
                    "RM ${estimatedBeforeUrgent.toStringAsFixed(0)}",
                    muted,
                    valueColor: Colors.white),
                const SizedBox(height: 6),
                _line("Urgent multiplier", urgent ? "× ${urgentMultiplier.toStringAsFixed(2)}" : "—", muted),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Estimated Total",
                        style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      "RM ${estimatedTotal.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: UColors.gold,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(color: UColors.gold.withAlpha(70), blurRadius: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Optional: Final price (helper/admin override)",
                  style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _finalPriceField(textMain, muted),
                if (finalOverride != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text("Final Payable",
                            style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                      ),
                      Text(
                        "RM ${payable.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: UColors.success,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // submit
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: "Submit Request",
              icon: Icons.send_rounded,
              bg: UColors.gold,
              onTap: _submit,
            ),
          ),

          const SizedBox(height: 10),
          Text(
            "Note: upload rubric/file akan kita sambung lepas DB siap (UI boleh tambah later).",
            style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _typeChips(Color muted) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(
          active: type == AssignmentType.report,
          label: "Report / Essay",
          icon: Icons.article_rounded,
          onTap: () => setState(() => type = AssignmentType.report),
        ),
        _chip(
          active: type == AssignmentType.slides,
          label: "Slides",
          icon: Icons.slideshow_rounded,
          onTap: () => setState(() => type = AssignmentType.slides),
        ),
        _chip(
          active: type == AssignmentType.coding,
          label: "Coding",
          icon: Icons.code_rounded,
          onTap: () => setState(() => type = AssignmentType.coding),
        ),
      ],
    );
  }

  Widget _chip({
    required bool active,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final c = active ? UColors.gold : Colors.white.withAlpha(160);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? UColors.gold.withAlpha(25) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? UColors.gold : Colors.white.withAlpha(25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool highlight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? UColors.darkMuted : UColors.lightMuted;

    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              title,
              style: TextStyle(
                color: highlight ? UColors.gold : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: highlight ? UColors.gold : UColors.success,
        ),
      ],
    );
  }

  Widget _line(String a, String b, Color muted, {Color? valueColor, String? smallHint}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(a, style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
              if (smallHint != null) ...[
                const SizedBox(width: 6),
                Text(smallHint, style: TextStyle(color: muted.withAlpha(170), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
        Text(
          b,
          style: TextStyle(color: valueColor ?? Colors.white.withAlpha(210), fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _finalPriceField(Color textMain, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? UColors.darkInput : UColors.lightInput;
    final border = isDark ? UColors.darkBorder : UColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: finalPriceCtrl,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: textMain, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.price_change_rounded, color: muted),
          hintText: "Leave empty to use estimated price",
          hintStyle: TextStyle(color: muted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  void _submit() {
    if (titleCtrl.text.trim().isEmpty) {
      _toast("Please fill title.");
      return;
    }
    if (qty <= 0) {
      _toast("Enter valid $qtyLabel.");
      return;
    }
    _toast("Request submitted ✅ (price: RM ${payable.toStringAsFixed(0)})");
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
