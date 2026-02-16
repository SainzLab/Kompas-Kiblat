import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math.dart' show radians;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kompas Kiblat Premium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2C3E50),
        useMaterial3: true,
      ),
      home: const KiblatPage(),
    );
  }
}

class KiblatPage extends StatefulWidget {
  const KiblatPage({super.key});

  @override
  State<KiblatPage> createState() => _KiblatPageState();
}

class _KiblatPageState extends State<KiblatPage> {
  bool _hasPermissions = false;
  double? _qiblaDirection;
  String _locationStatus = "Menunggu lokasi...";
  double? _distanceToKaaba;

  final double _kaabaLat = 21.422487;
  final double _kaabaLng = 39.826206;

  double _lastDirection = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() {
        _hasPermissions = true;
      });
      _calculateQiblaData();
    } else {
      setState(() {
        _locationStatus = "Izin lokasi diperlukan";
      });
    }
  }

  Future<void> _calculateQiblaData() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double lat = position.latitude;
      double lng = position.longitude;

      double qibla = _getBearing(lat, lng, _kaabaLat, _kaabaLng);
      double distanceInMeters = Geolocator.distanceBetween(
        lat, lng, _kaabaLat, _kaabaLng
      );

      setState(() {
        _qiblaDirection = qibla;
        _distanceToKaaba = distanceInMeters / 1000;
        _locationStatus = "Lokasi Terkunci";
      });
    } catch (e) {
      setState(() {
        _locationStatus = "Gagal mengambil lokasi";
      });
    }
  }

  double _getBearing(double startLat, double startLng, double endLat, double endLng) {
    var startLatRad = radians(startLat);
    var startLngRad = radians(startLng);
    var endLatRad = radians(endLat);
    var endLngRad = radians(endLng);

    var dLon = endLngRad - startLngRad;

    var y = math.sin(dLon) * math.cos(endLatRad);
    var x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLon);

    var bearing = math.atan2(y, x);
    var bearingDegrees = (bearing * 180 / math.pi);
    return (bearingDegrees + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1), // Biru Tua
              Color(0xFF000000), // Hitam
            ],
          ),
        ),
        child: SafeArea(
          child: !_hasPermissions
              ? Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _checkPermissions,
                    child: const Text("Izinkan Akses Lokasi"),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    
                    Expanded(
                      child: StreamBuilder<CompassEvent>(
                        stream: FlutterCompass.events,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const Text('Error Kompas');
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.amber));
                          }

                          double? direction = snapshot.data?.heading;
                          if (direction == null) return const Text("No Sensor");
                          
                          if (direction - _lastDirection > 180) {
                            _lastDirection += 360;
                          } else if (direction - _lastDirection < -180) {
                            _lastDirection -= 360;
                          }
                          _lastDirection = direction;
                          
                          double qiblaAngle = (_qiblaDirection ?? 0) - _lastDirection;
                          
                          double compassTurns = -1 * (_lastDirection / 360);
                          double qiblaTurns = qiblaAngle / 360;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                         
                              AnimatedRotation(
                                turns: compassTurns,
                                duration: const Duration(milliseconds: 400), // Durasi halusinasi gerakan
                                curve: Curves.easeOut,
                                child: CustomPaint(
                                  size: const Size(300, 300),
                                  painter: CompassDialPainter(),
                                ),
                              ),

                              AnimatedRotation(
                                turns: qiblaTurns,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                child: const Icon(
                                  Icons.navigation,
                                  size: 60,
                                  color: Color(0xFFFFD700),
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 10)
                                  ],
                                ),
                              ),

                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              
                              Positioned(
                                top: 40,
                                child: Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    _buildFooterInfo(),
                    const SizedBox(height: 30),
                  ],
                ),
        ),
      ),
    );
  }
  //mwehehe
  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          "PENCARI KIBLAT",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _locationStatus == "Lokasi Terkunci" ? Icons.gps_fixed : Icons.gps_not_fixed,
                size: 16,
                color: _locationStatus == "Lokasi Terkunci" ? Colors.greenAccent : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                _locationStatus,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem("Arah Kiblat", "${_qiblaDirection?.toStringAsFixed(1) ?? '-'}°", Icons.compass_calibration),
          Container(width: 1, height: 40, color: Colors.white24),
          _infoItem("Jarak", "${_distanceToKaaba?.toStringAsFixed(0) ?? '-'} km", Icons.flight_takeoff),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.fill;
    
    final paintBorder = Paint()
      ..color = Colors.amber.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, paintCircle);
    canvas.drawCircle(center, radius, paintBorder);

    final paintTick = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final paintMainTick = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 5) {
      double angle = (i - 90) * math.pi / 180;
      bool isCardinal = i % 90 == 0;
      bool isMajor = i % 30 == 0;
      
      double outerR = radius - 10;
      double innerR = isCardinal ? radius - 25 : (isMajor ? radius - 20 : radius - 15);
      Paint p = isCardinal ? paintMainTick : paintTick;

      double x1 = center.dx + outerR * math.cos(angle);
      double y1 = center.dy + outerR * math.sin(angle);
      double x2 = center.dx + innerR * math.cos(angle);
      double y2 = center.dy + innerR * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    }

    drawText(canvas, center, radius - 40, "N", 0, Colors.redAccent, true);
    drawText(canvas, center, radius - 40, "E", 90, Colors.white, false);
    drawText(canvas, center, radius - 40, "S", 180, Colors.white, false);
    drawText(canvas, center, radius - 40, "W", 270, Colors.white, false);
  }

  void drawText(Canvas canvas, Offset center, double radius, String text, double angleDeg, Color color, bool isBold) {
    double angle = (angleDeg - 90) * math.pi / 180;
    
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: isBold ? 24 : 18,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double x = center.dx + radius * math.cos(angle) - (textPainter.width / 2);
    double y = center.dy + radius * math.sin(angle) - (textPainter.height / 2);
    
    canvas.save();
    canvas.translate(x + textPainter.width/2, y + textPainter.height/2);
    canvas.rotate(angle + math.pi/2);
    canvas.translate(-(x + textPainter.width/2), -(y + textPainter.height/2));
    
    textPainter.paint(canvas, Offset(x, y));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}