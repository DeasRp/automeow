import 'package:flutter/material.dart';
import 'package:automatic_feeder/screen/home_page.dart';
import 'package:automatic_feeder/screen/chart_page.dart';
//import 'package:automatic_feeder/screen/setting_page.dart';
import 'package:automatic_feeder/screen/scheduler_page.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // HAPUS 'const' di sini agar tidak error
        children: [
          const HomeScreen(),
          const ChartPage(),
          const SchedulerPage(),
          //const SettingsPage(), // Pastikan SettingsPage juga punya const constructor jika pakai const
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        },
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: "Grafik",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            activeIcon: Icon(Icons.schedule),
            label: "Jadwal",
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.settings),
          //   activeIcon: Icon(Icons.settings),
          //   label: "Pengaturan",
          //),
        ],
      ),
    );
  }
}
