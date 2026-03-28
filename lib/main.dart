import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math.dart' show radians;
import 'package:geocoding/geocoding.dart'; 
import 'package:adhan/adhan.dart';
import 'kalender_page.dart';
import 'tasbih_page.dart';

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

class KiblatPage extends StatelessWidget {
  const KiblatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1), 
              Color(0xFF000000),
            ],
          ),
        ),
        child: const SafeArea(child: KiblatBody()),
      ),
    );
  }
}

class KiblatBody extends StatefulWidget {
  const KiblatBody({super.key});

  @override
  State<KiblatBody> createState() => _KiblatBodyState();
}

class _KiblatBodyState extends State<KiblatBody> {
  bool _hasPermissions = false;
  double? _qiblaDirection;
  String _locationStatus = "Menunggu lokasi...";
  double? _distanceToKaaba;

  final double _kaabaLat = 21.422487;
  final double _kaabaLng = 39.826206;

  double _lastDirection = 0;
  
  PrayerTimes? _prayerTimes;
  
  DateTime _selectedPrayerDate = DateTime.now();

  final List<String> _hariMasehi = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  final List<String> _bulanMasehi = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _refreshData() async {
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _locationStatus = "Mengecek sensor...";
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationStatus = "GPS belum dinyalakan";
        _hasPermissions = false;
      });
      return; 
    }

    PermissionStatus status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isGranted) {
      setState(() {
        _hasPermissions = true;
        _locationStatus = "Mencari kordinat...";
      });
      await _calculateQiblaData();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _locationStatus = "Izin ditolak permanen. Buka setting HP.";
        _hasPermissions = false;
      });
      openAppSettings();
    } else {
      setState(() {
        _locationStatus = "Izin lokasi diperlukan";
        _hasPermissions = false;
      });
    }
  }

  Future<void> _calculateQiblaData() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double lat = position.latitude;
      double lng = position.longitude;

      double qibla = _getBearing(lat, lng, _kaabaLat, _kaabaLng);
      double distanceInMeters = Geolocator.distanceBetween(lat, lng, _kaabaLat, _kaabaLng);

      String namaKotaBaru = "Lokasi Terkunci"; 
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String? kota = place.subAdministrativeArea; 
          if (kota == null || kota.isEmpty) {
            kota = place.locality; 
          }
          if (kota != null) {
            kota = kota.replaceAll("Kabupaten ", "Kab. "); 
            namaKotaBaru = kota; 
          }
        }
      } catch (e) {
        debugPrint("Gagal Reverse Geocoding: $e");
      }

      _updatePrayerTimes(lat, lng, _selectedPrayerDate);

      setState(() {
        _qiblaDirection = qibla;
        _distanceToKaaba = distanceInMeters / 1000;
        _locationStatus = namaKotaBaru; 
      });
    } catch (e) {
      setState(() {
        _locationStatus = "Gagal mengambil lokasi";
      });
    }
  }

  void _updatePrayerTimes(double lat, double lng, DateTime dateForPrayer) {
    final coordinates = Coordinates(lat, lng);
    final date = DateComponents.from(dateForPrayer);
    final params = CalculationMethod.singapore.getParameters();

    params.fajrAngle = 20.0;
    params.ishaAngle = 18.0;
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(coordinates, date, params);
    
    setState(() {
      _prayerTimes = prayerTimes; 
      _selectedPrayerDate = dateForPrayer;
    });
  }

  void _changePrayerDate(int daysToAdd) async {
    DateTime newDate = _selectedPrayerDate.add(Duration(days: daysToAdd));
    
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      _updatePrayerTimes(position.latitude, position.longitude, newDate);
    } catch (e) {
       debugPrint("Gagal update jadwal: $e");
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

  String _formatTime(DateTime time) {
    final localTime = time.toLocal(); 
    return "${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -250) { 
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const KalenderPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0); 
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        }
        else if (details.primaryVelocity! > 250) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const TasbihPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0); 
                const end = Offset.zero;
                const curve = Curves.easeOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        }
      },
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            color: Colors.amber,
            child: !_hasPermissions
                ? CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _locationStatus,
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: _checkPermissions,
                                child: const Text("Cek Lokasi / Izin"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: screenHeight * 0.82, 
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildHeader(),
                              
                              Expanded(
                                child: StreamBuilder<CompassEvent>(
                                  stream: FlutterCompass.events,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) return const Center(child: Text('Error Kompas', style: TextStyle(color: Colors.white)));
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                                    }

                                    double? direction = snapshot.data?.heading;
                                    if (direction == null) return const Center(child: Text("Sensor kompas tidak ditemukan", style: TextStyle(color: Colors.white)));
                                    
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
                                          duration: const Duration(milliseconds: 400),
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
                            ],
                          ),
                        ),
                      ),
                      
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            if (_prayerTimes != null) _buildJadwalSholatUI(),
                            const SizedBox(height: 50),
                          ],
                        ),
                      )
                    ],
                  ),
          ),

          if (_hasPermissions)
            Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: 0.7,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                    border: Border(left: BorderSide(color: Colors.white12, width: 1), top: BorderSide(color: Colors.white12, width: 1), bottom: BorderSide(color: Colors.white12, width: 1)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, color: Colors.white54, size: 22),
                      SizedBox(height: 4),
                      RotatedBox(quarterTurns: 3, child: Text("KALENDER", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2))),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),

          if (_hasPermissions)
            Align(
              alignment: Alignment.centerLeft,
              child: Opacity(
                opacity: 0.7,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                    border: Border(right: BorderSide(color: Colors.white12, width: 1), top: BorderSide(color: Colors.white12, width: 1), bottom: BorderSide(color: Colors.white12, width: 1)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_right, color: Colors.white54, size: 22),
                      SizedBox(height: 4),
                      RotatedBox(quarterTurns: 1, child: Text("TASBIH", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2))),
                      SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJadwalSholatUI() {
   
    DateTime now = DateTime.now();
    bool isToday = _selectedPrayerDate.year == now.year && 
                   _selectedPrayerDate.month == now.month && 
                   _selectedPrayerDate.day == now.day;

    Prayer nextPrayer = isToday ? _prayerTimes!.nextPrayer() : Prayer.none;
    
    String namaHari = _hariMasehi[_selectedPrayerDate.weekday];
    String namaBulan = _bulanMasehi[_selectedPrayerDate.month];
    String headerTitle = isToday ? "JADWAL HARI INI" : "$namaHari, ${_selectedPrayerDate.day} $namaBulan ${_selectedPrayerDate.year}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: () => _changePrayerDate(-1),
              ),
              Text(
                headerTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: () => _changePrayerDate(1), 
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          _prayerRow("Subuh", _prayerTimes!.fajr, nextPrayer == Prayer.fajr),
          const Divider(color: Colors.white12, height: 1),
          _prayerRow("Dzuhur", _prayerTimes!.dhuhr, nextPrayer == Prayer.dhuhr),
          const Divider(color: Colors.white12, height: 1),
          _prayerRow("Ashar", _prayerTimes!.asr, nextPrayer == Prayer.asr),
          const Divider(color: Colors.white12, height: 1),
          _prayerRow("Maghrib", _prayerTimes!.maghrib, nextPrayer == Prayer.maghrib),
          const Divider(color: Colors.white12, height: 1),
          _prayerRow("Isya", _prayerTimes!.isha, nextPrayer == Prayer.isha),
        ],
      ),
    );
  }

  Widget _prayerRow(String name, DateTime time, bool isNext) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isNext ? Colors.amber.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isNext ? Border.all(color: Colors.amber.withOpacity(0.5)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isNext) 
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.access_time_filled, color: Colors.amber, size: 18),
                ),
              Text(
                name,
                style: TextStyle(
                  color: isNext ? Colors.amber : Colors.white70,
                  fontSize: 16,
                  fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            _formatTime(time),
            style: TextStyle(
              color: isNext ? Colors.amber : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    bool isLocationFixed = (_distanceToKaaba != null);
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isLocationFixed ? const Color(0xFF152A50) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: isLocationFixed ? Border.all(color: Colors.white12) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock, 
                size: 16,
                color: isLocationFixed ? const Color(0xFFFFD700) : Colors.orange, 
              ),
              const SizedBox(width: 8),
              Text(
                _locationStatus,
                style: TextStyle(
                  color: isLocationFixed ? Colors.white : Colors.white70, 
                  fontSize: 14,
                  fontWeight: isLocationFixed ? FontWeight.bold : FontWeight.normal,
                ),
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
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

    final paintCircle = Paint()..color = const Color(0xFF212121)..style = PaintingStyle.fill;
    final paintBorder = Paint()..color = Colors.amber.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 4;

    canvas.drawCircle(center, radius, paintCircle);
    canvas.drawCircle(center, radius, paintBorder);

    final paintTick = Paint()..color = Colors.white38..strokeWidth = 2..strokeCap = StrokeCap.round;
    final paintMainTick = Paint()..color = Colors.white..strokeWidth = 3..strokeCap = StrokeCap.round;

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
    
    final textSpan = TextSpan(text: text, style: TextStyle(color: color, fontSize: isBold ? 24 : 18, fontWeight: isBold ? FontWeight.bold : FontWeight.normal));
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
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