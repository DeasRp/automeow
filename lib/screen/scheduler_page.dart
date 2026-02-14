import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../service/mqtt_service.dart';

class SchedulerPage extends StatefulWidget {
  const SchedulerPage({super.key});

  @override
  State<SchedulerPage> createState() => _SchedulerPageState();
}

class _SchedulerPageState extends State<SchedulerPage> {

  // Fungsi untuk mengedit jadwal (Popup Time Picker & Slider)
  Future<void> _editSchedule(int index) async {
    final mqtt = Provider.of<MQTTService>(context, listen: false);
    final s = mqtt.schedules[index];
    
    // Pastikan casting tipe data aman
    TimeOfDay initialTime = s['time'] as TimeOfDay;
    int duration = s['duration'];

    // 1. Pilih Waktu (Time Picker)
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.blue.shade700),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // 2. Pilih Durasi (Bottom Sheet)
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Durasi Pakan (Detik)", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.timer, color: Colors.grey),
                      Text("$duration detik", 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)
                      ),
                    ],
                  ),
                  Slider(
                    value: duration.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: "$duration s",
                    activeColor: Colors.blue.shade700,
                    onChanged: (val) {
                      setSheetState(() => duration = val.toInt());
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                      child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );

    // 3. Simpan ke Provider (MQTT Service)
    // Otomatis set ke 'true' (aktif) jika user mengedit jadwal
    mqtt.updateSchedule(index, pickedTime.hour, pickedTime.minute, duration, true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jadwal ${s['label']} diperbarui!"), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan Provider.of untuk mendengarkan perubahan data secara realtime
    final mqtt = Provider.of<MQTTService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: isDark ? Colors.black : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Jadwal Pakan',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          
          // Peringatan jika MQTT Putus
          if (mqtt.connectionStatus != 'Connected')
             SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.wifi_off, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text("MQTT Terputus. Data tidak sinkron.", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = mqtt.schedules[index];
                return _buildScheduleCard(index, item, isDark, mqtt);
              },
              childCount: mqtt.schedules.length, 
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(int index, Map<String, dynamic> item, bool isDark, MQTTService mqtt) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: item['enabled'] 
            ? Border.all(color: Colors.blue.withValues(alpha:0.3), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _editSchedule(index),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Jam
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item['enabled'] ? Colors.blue.withValues(alpha:0.1) : Colors.grey.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.clock,
                    color: item['enabled'] ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Text Informasi Jadwal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['label'], style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                        (item['time'] as TimeOfDay).format(context),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: item['enabled'] ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                        ),
                      ),
                      Text("Durasi: ${item['duration']} detik", style: TextStyle(fontSize: 12, color: Colors.blue.shade400)),
                    ],
                  ),
                ),

                // Switch ON/OFF
                Switch(
                  value: item['enabled'],
                  activeThumbColor: Colors.blue,
                  onChanged: (val) {
                    // Disini kita langsung panggil Service, tidak butuh _updateDevice lokal
                    final t = item['time'] as TimeOfDay;
                    mqtt.updateSchedule(index, t.hour, t.minute, item['duration'], val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}