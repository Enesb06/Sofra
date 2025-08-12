import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterChatMessage extends StatefulWidget {
  final String text;
  final VoidCallback onCharacterTyped;
  final VoidCallback onFinishedTyping;

  const TypewriterChatMessage({
    super.key,
    required this.text,
    required this.onCharacterTyped,
    required this.onFinishedTyping,
  });

  @override
  State<TypewriterChatMessage> createState() => _TypewriterChatMessageState();
}

// 1. DEĞİŞİKLİK: "with AutomaticKeepAliveClientMixin" ekliyoruz.
class _TypewriterChatMessageState extends State<TypewriterChatMessage>
    with AutomaticKeepAliveClientMixin<TypewriterChatMessage> {
      
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  // 2. DEĞİŞİKLİK: Widget'ın hayatta kalmak istediğini belirtiyoruz.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Animasyonun sadece bir kez başlamasını sağlamak için kontrol ekleyelim.
    if (_displayedText.isEmpty) {
      _startTyping();
    }
  }

  void _startTyping() {
    final words = widget.text.split(' ');
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentIndex < words.length) {
        if (mounted) {
          setState(() {
            _displayedText += "${words[_currentIndex]} ";
            _currentIndex++;
          });
          widget.onCharacterTyped();
        }
      } else {
        _timer?.cancel();
        widget.onFinishedTyping();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. DEĞİŞİKLİK: Mixin'in düzgün çalışması için super.build(context) çağrısını ekliyoruz.
    super.build(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(_displayedText.trim(), style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}