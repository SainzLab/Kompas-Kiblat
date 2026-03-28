import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key});

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  late HijriCalendar _hijriToday;
  late DateTime _gregorianToday;
  late PageController _pageController;

  late DateTime _selectedDate;
  late HijriCalendar _selectedHijri;

  final List<String> _bulanHijriah = [
    '', 'Muharram', 'Safar', 'Rabiul Awal', 'Rabiul Akhir',
    'Jumadil Awal', 'Jumadil Akhir', 'Rajab', 'Sya\'ban',
    'Ramadhan', 'Syawal', 'Dzulqa\'dah', 'Dzulhijjah'
  ];

  final List<String> _hariMasehi = [
    '', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];
  final List<String> _bulanMasehi = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _gregorianToday = DateTime.now();
    _hijriToday = HijriCalendar.now();
    
    _selectedDate = _gregorianToday;
    _selectedHijri = _hijriToday;

    int initialPage = (_gregorianToday.year * 12) + _gregorianToday.month - 1;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getMoonPhaseIcon(int hijriDay) {
    if (hijriDay >= 1 && hijriDay <= 3) return '🌒';
    if (hijriDay >= 4 && hijriDay <= 7) return '🌓';
    if (hijriDay >= 8 && hijriDay <= 12) return '🌔';
    if (hijriDay >= 13 && hijriDay <= 16) return '🌕';
    if (hijriDay >= 17 && hijriDay <= 21) return '🌖';
    if (hijriDay >= 22 && hijriDay <= 25) return '🌗';
    if (hijriDay >= 26 && hijriDay <= 28) return '🌘';
    return '🌑';
  }

  @override
  Widget build(BuildContext context) {
    String moonIcon = _getMoonPhaseIcon(_selectedHijri.hDay);
    String namaBulanHijriah = _bulanHijriah[_selectedHijri.hMonth];
    String namaHari = _hariMasehi[_selectedDate.weekday];
    String namaBulanMasehi = _bulanMasehi[_selectedDate.month];
    String formattedMasehi = '$namaHari, ${_selectedDate.day} $namaBulanMasehi ${_selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F42), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, 
        centerTitle: true,
        title: const Text(
          'KALENDER & FASE BULAN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            Text(
              moonIcon,
              style: const TextStyle(fontSize: 100), 
            ),
            const SizedBox(height: 20),
            
            Text(
              '${_selectedHijri.hDay} $namaBulanHijriah ${_selectedHijri.hYear} H',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 28, 
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            Container(
              width: 150,
              height: 2,
              color: Colors.white24,
            ),
            const SizedBox(height: 15),
            
            Text(
              formattedMasehi,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 30),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  int tahun = index ~/ 12;
                  int bulan = (index % 12) + 1;
                  return _buildKalenderBulan(bulan, tahun);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKalenderBulan(int bulan, int tahun) {
    int totalHariBulanIni = DateTime(tahun, bulan + 1, 0).day;
    int hariPertama = DateTime(tahun, bulan, 1).weekday;
    String namaBulan = _bulanMasehi[bulan];

    List<String> singkatanHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              Text(
                "$namaBulan $tahun",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: singkatanHari.map((hari) => Expanded(
              child: Text(
                hari,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 10),
          
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalHariBulanIni + (hariPertama - 1),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                if (index < hariPertama - 1) {
                  return const SizedBox.shrink();
                }
                
                int tanggalBerapa = index - (hariPertama - 2);
                DateTime cellDate = DateTime(tahun, bulan, tanggalBerapa);
                
                bool isSelected = (cellDate.year == _selectedDate.year) && 
                                  (cellDate.month == _selectedDate.month) && 
                                  (cellDate.day == _selectedDate.day);
                                  
                bool isToday = (cellDate.year == _gregorianToday.year) && 
                               (cellDate.month == _gregorianToday.month) && 
                               (cellDate.day == _gregorianToday.day);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                      _selectedHijri = HijriCalendar.fromDate(_selectedDate); 
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected 
                          ? Border.all(color: const Color(0xFFFFD700), width: 1.5) 
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        tanggalBerapa.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}