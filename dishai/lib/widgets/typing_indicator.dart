import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedTypingIndicator extends StatefulWidget {
  const AnimatedTypingIndicator({super.key});

  @override
  State<AnimatedTypingIndicator> createState() => _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator> {
  int _dotCount = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Her 400 milisaniyede bir nokta sayısını güncelleyen bir zamanlayıcı başlat
    _timer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount % 3) + 1; // 1, 2, 3, 1, 2, 3...
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Widget kaldırıldığında zamanlayıcıyı durdur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mevcut nokta sayısına göre metni oluştur: "Typing.", "Typing..", "Typing..."
    String typingText = 'Typing${'.' * _dotCount}';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          typingText,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}