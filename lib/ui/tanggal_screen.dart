import 'package:flutter/material.dart';
import 'package:mobile_kelompok/ui/sidebar/sidebar.dart';
import 'package:mobile_kelompok/services/order_session.dart';
import 'package:mobile_kelompok/ui/pembayaran_screen.dart';

class TanggalScreen extends StatefulWidget {
  const TanggalScreen({super.key});

  @override
  State<TanggalScreen> createState() => _TanggalScreenState();
}

class _TanggalScreenState extends State<TanggalScreen> {
  late DateTime displayedMonth;
  DateTime? selectedDate;
  bool isSelectableDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    return !target.isBefore(today);
  }

  static const List<String> namaHari = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> namaBulan = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = OrderSession.selectedDate;
    displayedMonth = selectedDate != null
        ? DateTime(selectedDate!.year, selectedDate!.month)
        : DateTime(now.year, now.month);
  }

  void gantiBulan(int delta) {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + delta,
      );
    });
  }

  List<DateTime?> buildCalendarDays() {
    final firstDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;
    final leadingBlanks = firstDayOfMonth.weekday - 1;

    final List<DateTime?> days = List.filled(
      leadingBlanks,
      null,
      growable: true,
    );
    for (int d = 1; d <= daysInMonth; d++) {
      days.add(DateTime(displayedMonth.year, displayedMonth.month, d));
    }
    while (days.length % 7 != 0) {
      days.add(null);
    }
    return days;
  }

  void submitTanggal() {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tanggal terlebih dahulu')),
      );
      return;
    }

    OrderSession.selectedDate = selectedDate;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PembayaranScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = buildCalendarDays();

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      drawer: const SidebarWidget(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildKembali(context),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: () => gantiBulan(-1),
                          ),
                          Text(
                            '${namaBulan[displayedMonth.month - 1]} ${displayedMonth.year}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: () => gantiBulan(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: namaHari
                            .map(
                              (h) => Expanded(
                                child: Center(
                                  child: Text(
                                    h,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: days.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                            ),
                        itemBuilder: (context, index) {
                          final tanggal = days[index];

                          if (tanggal == null) {
                            return const SizedBox.shrink();
                          }

                          final bisaDipilih = isSelectableDate(tanggal);

                          final terpilih =
                              selectedDate != null &&
                              selectedDate!.year == tanggal.year &&
                              selectedDate!.month == tanggal.month &&
                              selectedDate!.day == tanggal.day;

                          return GestureDetector(
                            onTap: bisaDipilih
                                ? () {
                                    setState(() {
                                      selectedDate = tanggal;
                                    });
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: terpilih
                                    ? const Color(0xFF1E88E5)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${tanggal.day}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: !bisaDipilih
                                      ? Colors.grey.shade400
                                      : terpilih
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: bisaDipilih
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: submitTanggal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BENGKEL KITA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'BENGKEL OTOMOTIF',
                style: TextStyle(
                  fontSize: 6,
                  color: Colors.black54,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(height: 1, color: Colors.grey.shade300, width: 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKembali(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE5E5E5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_back, size: 18, color: Colors.black87),
            SizedBox(width: 8),
            Text(
              'Kembali',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
