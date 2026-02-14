import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

class MQTTService extends ChangeNotifier {
  String broker = 'broker.emqx.io';
  int port = 1883;

  final String topicBerat = 'feeder/berat';
  final String topicSisa = 'feeder/sisa';
  final String topicServo = 'feeder/servo';
  final String topicStatus = 'feeder/status';
  final String topicJadwal = 'feeder/jadwal/set';
  final String topicMode = 'feeder/mode';
  final String topicCalibrate = 'feeder/calibrate';
  final String topicConfigSisa = 'feeder/config/sisa';

  MqttServerClient? client;
  double beratPakan = 0.0;
  int sisaPakan = 0;
  String connectionStatus = 'Disconnected';
  bool isAutoMode = false;
  List<Map<String, dynamic>> feedHistory = [];

  // Database service instance
  final DatabaseService _dbService = DatabaseService.instance;

  // Data Default
  List<Map<String, dynamic>> schedules = [
    {
      'time': const TimeOfDay(hour: 7, minute: 0),
      'duration': 3,
      'enabled': true,
      'label': 'Makan Pagi'
    },
    {
      'time': const TimeOfDay(hour: 12, minute: 0),
      'duration': 3,
      'enabled': true,
      'label': 'Makan Siang'
    },
    {
      'time': const TimeOfDay(hour: 18, minute: 0),
      'duration': 3,
      'enabled': true,
      'label': 'Makan Sore'
    },
    {
      'time': const TimeOfDay(hour: 0, minute: 0),
      'duration': 3,
      'enabled': false,
      'label': 'Slot Tambahan 1'
    },
    {
      'time': const TimeOfDay(hour: 0, minute: 0),
      'duration': 3,
      'enabled': false,
      'label': 'Slot Tambahan 2'
    },
  ];

  MQTTService() {
    _loadConfigAndConnect();
  }

  Future<void> _loadConfigAndConnect() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Broker Config (keep in SharedPreferences)
    broker = prefs.getString('mqtt_broker') ?? 'broker.emqx.io';
    port = int.tryParse(prefs.getString('mqtt_port') ?? '1883') ?? 1883;

    // 2. Load Mode from SharedPreferences
    isAutoMode = prefs.getBool('local_mode') ?? false;

    // 3. Load Feed History from Database
    try {
      feedHistory = await _dbService.getAllFeedHistory();
    } catch (e) {
      debugPrint("Error loading history from database: $e");
    }

    // 4. Load Schedules from Database
    try {
      final dbSchedules = await _dbService.getAllSchedules();
      if (dbSchedules.isNotEmpty) {
        schedules = dbSchedules;
      } else {
        // If database is empty, initialize with default schedules
        await _initializeDefaultSchedules();
      }
    } catch (e) {
      debugPrint("Error loading schedules from database: $e");
      await _initializeDefaultSchedules();
    }

    notifyListeners();
    connect();
  }

  // Initialize default schedules in database
  Future<void> _initializeDefaultSchedules() async {
    for (int i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];
      final time = schedule['time'] as TimeOfDay;
      await _dbService.upsertSchedule(
        slotIndex: i,
        hour: time.hour,
        minute: time.minute,
        duration: schedule['duration'],
        enabled: schedule['enabled'],
        label: schedule['label'],
      );
    }
  }

  // ... (Kode connect, refreshConnection, _onConnected tetap sama) ...
  Future<void> refreshConnection() async {
    if (client != null) client!.disconnect();
    await _loadConfigAndConnect();
  }

  Future<void> connect() async {
    connectionStatus = 'Connecting...';
    notifyListeners();
    client = MqttServerClient.withPort(broker,
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}', port);
    client!.secure = false;
    client!.keepAlivePeriod = 60;
    client!.onConnected = _onConnected;
    client!.onDisconnected = _onDisconnected;
    try {
      await client!.connect();
    } catch (e) {
      connectionStatus = 'Error';
      notifyListeners();
    }
  }

  void _onConnected() {
    connectionStatus = 'Connected';
    client!.subscribe(topicBerat, MqttQos.atMostOnce);
    client!.subscribe(topicSisa, MqttQos.atMostOnce);
    client!
        .subscribe(topicStatus, MqttQos.atMostOnce); // Pastikan baris ini ada
    client!.subscribe(topicMode, MqttQos.atMostOnce);
    client!.updates!.listen(_onMessage);
    notifyListeners();
  }

  void tareScale() {
    if (_isConnected()) {
      // Mengirim perintah "TARE" sesuai logika ESP32
      _publish(topicCalibrate, 'TARE');
      notifyListeners();
    }
  }

  void calibrateWithKnownWeight(double actualWeightInKg) {
    if (_isConnected()) {
      // Mengirim format "SET:1.0" sesuai logika ESP32
      // ESP32 akan menghitung faktor baru dan menyimpannya
      _publish(topicCalibrate, 'SET:${actualWeightInKg.toString()}');
    }
  }

  void calibrateStokPakan(double tinggiCm) {
    if (_isConnected()) {
      // Format: "TINGGI:30.5"
      _publish(topicConfigSisa, 'TINGGI:${tinggiCm.toString()}');
      notifyListeners();
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    final recMessage = messages[0].payload as MqttPublishMessage;
    final payload =
        MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
    final topic = messages[0].topic;

    if (topic == topicBerat) {
      beratPakan = double.tryParse(payload) ?? beratPakan;
      // Log sensor reading to database
      _logSensorReading();
    } else if (topic == topicSisa) {
      sisaPakan = int.tryParse(payload) ?? sisaPakan;
      // Log sensor reading to database
      _logSensorReading();
    } else if (topic == topicMode) {
      bool newMode = (payload == "AUTO");
      if (isAutoMode != newMode) {
        isAutoMode = newMode;
        _saveModeToPrefs(newMode);
      }
    } else if (topic == topicStatus) {
      if (payload.contains("Auto Feed")) {
        // Insert to feed history in database
        _addFeedHistory(
          amount: beratPakan,
          action: payload,
        );
      }
    }
    notifyListeners();
  }

  // Toggle Mode with persistence
  void toggleAutoMode(bool value) {
    isAutoMode = value;
    _saveModeToPrefs(value);

    if (_isConnected()) {
      _publish(topicMode, value ? "AUTO" : "MANUAL");
    }
    notifyListeners();
  }

  // Update Schedule with database persistence
  void updateSchedule(
      int index, int hour, int minute, int duration, bool enabled) {
    schedules[index]['time'] = TimeOfDay(hour: hour, minute: minute);
    schedules[index]['duration'] = duration;
    schedules[index]['enabled'] = enabled;

    // Save to database
    _saveScheduleToDatabase(index);

    if (_isConnected()) {
      _publish(
          topicJadwal, "$index,$hour,$minute,$duration,${enabled ? 1 : 0}");
    }
    notifyListeners();
  }

  // Helper to save mode to SharedPreferences
  Future<void> _saveModeToPrefs(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('local_mode', value);
  }

  // Helper to save a single schedule to database
  Future<void> _saveScheduleToDatabase(int index) async {
    try {
      final schedule = schedules[index];
      final time = schedule['time'] as TimeOfDay;
      await _dbService.upsertSchedule(
        slotIndex: index,
        hour: time.hour,
        minute: time.minute,
        duration: schedule['duration'],
        enabled: schedule['enabled'],
        label: schedule['label'],
      );
    } catch (e) {
      debugPrint("Error saving schedule to database: $e");
    }
  }

  // Helper to add feed history to database
  Future<void> _addFeedHistory({
    required double amount,
    required String action,
  }) async {
    try {
      await _dbService.insertFeedHistory(
        timestamp: DateTime.now(),
        amount: amount,
        action: action,
      );
      // Reload history from database
      feedHistory = await _dbService.getAllFeedHistory();
    } catch (e) {
      debugPrint("Error adding feed history to database: $e");
    }
  }

  // Helper to log sensor readings to database (throttled)
  DateTime? _lastSensorLog;
  Future<void> _logSensorReading() async {
    // Only log every 5 minutes to avoid database bloat
    final now = DateTime.now();
    if (_lastSensorLog != null &&
        now.difference(_lastSensorLog!).inMinutes < 5) {
      return;
    }

    try {
      await _dbService.insertSensorReading(
        timestamp: now,
        weight: beratPakan,
        stockLevel: sisaPakan,
      );
      _lastSensorLog = now;
    } catch (e) {
      debugPrint("Error logging sensor reading: $e");
    }
  }

  // ... (Sisa kode openServo, closeServo, _publish, dll tetap sama) ...
  void openServo() {
    if (_isConnected()) {
      _publish(topicServo, 'OPEN');

      // Add to feed history in database
      _addFeedHistory(
        amount: beratPakan,
        action: 'Manual Feed',
      );

      notifyListeners();
    }
  }

  void closeServo() {
    if (_isConnected()) {
      _publish(topicServo, 'CLOSE');
    }
  }

  void _publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  bool _isConnected() =>
      client?.connectionStatus?.state == MqttConnectionState.connected;
  void _onDisconnected() {
    connectionStatus = 'Disconnected';
    notifyListeners();
  }
}
