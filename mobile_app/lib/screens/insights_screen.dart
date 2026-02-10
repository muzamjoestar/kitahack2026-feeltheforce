import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key}); // Ditambah key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Validation Log"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInsightCard("Sis Sarah", "Mahallah Hafsah", "Danger at night? Need emergency button.", "Added SOS Feature"),
          _buildInsightCard("Sis Aisyah", "Mahallah Aminah", "I prefer female drivers for safety.", "Added Muslimah Filter"),
          _buildInsightCard("Bro Amir", "Mahallah Ali", "Runner prices are inconsistent.", "Added Auto-Price Calc"),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String user, String mah, String feedback, String action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13), // Tukar withOpacity ke withAlpha
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(user[0])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(mah, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ])
            ],
          ),
          const SizedBox(height: 15),
          Text("\"$feedback\"", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25), // Tukar withOpacity ke withAlpha
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text("ACTION: $action", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}