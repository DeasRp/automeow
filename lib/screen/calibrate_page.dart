import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../service/mqtt_service.dart';

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MQTTService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Kalibrasi Timbangan'),
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Monitor Berat Real-time
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Column(
                children: [
                  const Text('Bacaan Sensor Saat Ini', style: TextStyle(color: Colors.blue)),
                  const SizedBox(height: 5),
                  Text(
                    '${mqtt.beratPakan.toStringAsFixed(3)} Kg',
                    style: const TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.blueAccent
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // --- LANGKAH 1: TARE ---
            const Text(
              'Langkah 1: Zeroing (Tare)', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan wadah pakan KOSONG, lalu tekan tombol di bawah untuk mengenolkan timbangan.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: mqtt.connectionStatus == 'Connected' 
                  ? () {
                      mqtt.tareScale();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perintah TARE dikirim ke ESP32')),
                      );
                    }
                  : null,
              icon: const FaIcon(FontAwesomeIcons.arrowsToCircle, size: 16),
              label: const Text('Nol-kan Timbangan (TARE)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),

            const Divider(height: 40, thickness: 1),

            // --- LANGKAH 2: KALIBRASI BEBAN ---
            const Text(
              'Langkah 2: Kalibrasi Beban', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Letakkan benda yang diketahui beratnya (misal: HP, Air Mineral 600ml).\n'
              '2. Masukkan berat benda tersebut dalam Kg (misal: 0.6).\n'
              '3. Tekan tombol Kalibrasi.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Berat Benda (Kg)',
                hintText: 'Cth: 0.5',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixText: 'Kg',
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: mqtt.connectionStatus == 'Connected' 
                  ? () {
                      final val = double.tryParse(_weightController.text.replaceAll(',', '.'));
                      if (val != null && val > 0) {
                        mqtt.calibrateWithKnownWeight(val);
                        FocusScope.of(context).unfocus(); // Tutup keyboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Mengirim Faktor Kalibrasi untuk beban $val Kg...')),
                        );
                        _weightController.clear();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Masukkan berat yang valid!')),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Kalibrasi Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const Text(
              'Langkah 3: Kalibrasi Stok Pakan (Ultrasonik)', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan tinggi total wadah pakan Anda (dari sensor ke dasar wadah) dalam cm.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tinggi Wadah (cm)',
                hintText: 'Cth: 30.0',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixText: 'cm',
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: mqtt.connectionStatus == 'Connected' 
                  ? () {
                      final val = double.tryParse(_heightController.text.replaceAll(',', '.'));
                      if (val != null && val > 0) {
                        mqtt.calibrateStokPakan(val);
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tinggi wadah diset ke $val cm')),
                        );
                        _heightController.clear();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Bedakan warna agar user tidak bingung
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Simpan Tinggi Wadah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}