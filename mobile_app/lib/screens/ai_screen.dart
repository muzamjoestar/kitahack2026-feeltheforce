import 'package:flutter/material.dart';

class AiScreenPlaceholder extends StatelessWidget {
  const AiScreenPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: const Center(
        child: Text('AI feature coming soon!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}

class AiScreen extends StatelessWidget {
  const AiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AiScreenPlaceholder();
  }
}
