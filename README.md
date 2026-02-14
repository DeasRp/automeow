# 🐾 AutoMeow: IoT-Based Smart Pet Feeder

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase&logoColor=white)
![MQTT](https://img.shields.io/badge/MQTT-Broker-orange?style=for-the-badge&logo=mqtt&logoColor=white)

> **Solusi cerdas untuk memastikan anabul Anda tetap kenyang, tepat waktu, di mana pun Anda berada.**

AutoMeow bukan sekadar aplikasi remote control; ini adalah ekosistem pemantauan kesehatan hewan peliharaan yang mengintegrasikan presisi sensor hardware dengan kemudahan antarmuka mobile.

---

## 🚀 Mengapa AutoMeow?

Menjaga jadwal makan hewan peliharaan seringkali sulit di tengah kesibukan. **AutoMeow** hadir untuk menjembatani jarak tersebut dengan fitur:

* **🎯 Precision Feeding:** Integrasi sensor beban (Load Cell HX711) memastikan pakan yang keluar sesuai takaran.
* **📡 Real-Time Monitoring:** Menggunakan protokol MQTT untuk sinkronisasi data instan tanpa delay yang berarti.
* **📊 Insightful History:** Data pemberian pakan disimpan secara lokal dengan SQLite, memungkinkan Anda memantau pola makan anabul.
* **🔋 Reliable Hardware:** Dirancang untuk berjalan pada ESP32 dengan sistem manajemen daya baterai 18650 yang efisien.

---

## 🛠️ Tech Stack & Hardware

### Software
- **Frontend:** Flutter Framework (Cross-platform Android/iOS).
- **Local Storage:** SQLite untuk manajemen data riwayat.
- **Messaging:** MQTT Protocol via HiveMQ Cloud.

### Hardware (The Brain)
- **Microcontroller:** ESP32 DevKit V1.
- **Sensors:** HC-SR04 (Dispenser level) & HX711 (Weight scale).
- **Actuator:** SG90 Servo (Gate mechanism).
- **Power:** 3x 18650 Li-ion Batteries + LM2596 Step-down Converter.

---

## 📱 Cuplikan Antarmuka

| Dashboard Utama | Riwayat Makan | Pengaturan Alat |
| :---: | :---: | :---: |
| ![Dashboard](https://github.com/DeasRp/automeow/blob/main/assets/screenshots/homepage.jpeg) | ![History]([https://via.placeholder.com/200x400?text=History](https://github.com/DeasRp/automeow/blob/main/assets/screenshots/graphpage.jpeg) | ![Scheduler](https://github.com/DeasRp/automeow/blob/main/assets/screenshots/schedulerpage.jpg) |

