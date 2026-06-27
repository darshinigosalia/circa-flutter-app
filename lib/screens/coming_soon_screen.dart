import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: CircaColors.ink),
      ),
      body: Center(
        child: Text(
          "Coming soon",
          style: CircaColors.title,
        ),
      ),
    );
  }
}
