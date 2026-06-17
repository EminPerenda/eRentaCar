import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../vehicle/vehicles_screen.dart';
import '../reservation/reservations_screen.dart';
import '../notification/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../news/news_screen.dart';
import '../../services/signalr_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VehiclesScreen(),
    const ReservationsScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
    const NewsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    SignalRService().connect();
  }

  @override
  void dispose() {
    SignalRService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.textMuted,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'Vozila',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Rezervacije',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Obavijesti',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper),
            label: 'Vijesti',
          ),
        ],
      ),
    );
  }
}