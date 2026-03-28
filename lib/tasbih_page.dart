import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  int _counter = 0;
  final int _target = 33;

  void _incrementCounter() {
    HapticFeedback.lightImpact();
    
    setState(() {
      _counter++;
      if (_counter % _target == 0 && _counter > 0) {
        HapticFeedback.vibrate();
      }
    });
  }

  void _resetCounter() {
    HapticFeedback.heavyImpact();
    setState(() {
      _counter = 0;
    });
  }

  String _getDzikirText() {
    int cycle = (_counter ~/ 33) % 3;
    if (cycle == 0) return "Subhanallah";
    if (cycle == 1) return "Alhamdulillah";
    return "Allahu Akbar";
  }

  String _getArabicText() {
    int cycle = (_counter ~/ 33) % 3;
    if (cycle == 0) return "سُبْحَانَ ٱللَّٰهِ";
    if (cycle == 1) return "ٱلْحَمْدُ لِلَّٰهِ";
    return "ٱللَّٰهُ أَكْبَرُ";
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_counter % _target) / _target;

    if (_counter > 0 && _counter % _target == 0) progress = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F42),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TASBIH DIGITAL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _incrementCounter,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getArabicText(),
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              
              Text(
                _getDzikirText(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 50),

              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white10,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                    
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF152A50), 
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(5, 5),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(-5, -5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_counter',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Ketuk layar',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),

              InkWell(
                onTap: _resetCounter,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'RESET',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}