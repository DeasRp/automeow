import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../service/mqtt_service.dart';
import 'package:automatic_feeder/screen/calibrate_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea(
        child: Consumer<MQTTService>(
          builder: (context, mqtt, child) {
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: isDark ? Colors.black : Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Smart Pet Feeder',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: mqtt.connectionStatus == 'Connected'
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                mqtt.connectionStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        FontAwesomeIcons.gear, 
                        size: 20,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CalibrationPage()),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                  ],
    
                ),
                
                // Content
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Status Cards
                      // Status Cards dengan Visualisasi Baru
                    Row(
                      children: [
                        // Visualisasi Real-time Weight (HX711)
                        Expanded(
                          child: _buildWeightCard(
                            context,
                            mqtt.beratPakan,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Visualisasi Stok Pakan (Ultrasonik)
                        Expanded(
                          child: _buildStockCard(
                            context,
                            mqtt.sisaPakan,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 24),
                      // Mode Switch Card
                      _buildModeCard(context, mqtt, isDark),
                      const SizedBox(height: 24),
                      // Control Card
                      _buildControlCard(context, mqtt, isDark),
                      
                      const SizedBox(height: 24),
                      // Feed History
                      _buildFeedHistory(context, mqtt, isDark),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
Widget _buildWeightCard(BuildContext context, double berat, bool isDark) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[900] : Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Berat Pakan',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '${berat.toStringAsFixed(2)} Kg',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        // Ikon timbangan kecil di pojok
        Positioned(
          right: 0,
          top: 0,
          child: FaIcon(
            FontAwesomeIcons.weightScale,
            size: 16,
            color: Colors.blue.withValues(alpha:0.5),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStockCard(BuildContext context, int sisa, bool isDark) {
  // Logika warna: merah jika < 20%
  Color statusColor = sisa < 20 ? Colors.red : Colors.green;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[900] : Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sisa Pakan',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '$sisa%',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
        // Visualisasi Indikator Tabung Vertikal
        Container(
          width: 12,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              FractionallySizedBox(
                heightFactor: sisa / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildModeCard(BuildContext context, MQTTService mqtt, bool isDark) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[900] : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(
                  mqtt.isAutoMode ? FontAwesomeIcons.robot : FontAwesomeIcons.hand,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mode Pengoperasian',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            // Switch Mode
            Switch(
              value: mqtt.isAutoMode,
              onChanged: mqtt.connectionStatus == 'Connected'
                  ? (value) => mqtt.toggleAutoMode(value)
                  : null,
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          mqtt.isAutoMode
              ? 'ESP32 akan memberi makan secara otomatis berdasarkan jadwal yang telah ditentukan.'
              : 'Mode manual aktif. Anda dapat mengontrol feeder menggunakan tombol di bawah.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildControlCard(BuildContext context, MQTTService mqtt, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kontrol Feeder',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (mqtt.connectionStatus == 'Connected' && !mqtt.isAutoMode)
                      ? () => mqtt.openServo()
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.handHoldingHeart, size: 18),
                  label: Text(
                    mqtt.isAutoMode ? 'Auto Mode Aktif' : 'Beri Makan',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: mqtt.connectionStatus == 'Connected'
                      ? () => mqtt.closeServo()
                      : null,
                  icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
                  label: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Colors.red.withValues(alpha:0.3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeedHistory(BuildContext context, MQTTService mqtt, bool isDark) {
    if (mqtt.feedHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat pemberian makan',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Pemberian Makan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          ...mqtt.feedHistory.take(5).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.bowlFood,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['action'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['amount'].toStringAsFixed(2)} Kg',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(item['time']),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}