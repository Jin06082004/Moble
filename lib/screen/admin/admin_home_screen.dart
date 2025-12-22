import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_screen.dart';
import '../home_screen.dart';
import 'admin_statistics_screen.dart';
import 'admin_rooms_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminStatisticsScreen(),
    AdminRoomsScreen(),
    AdminBookingsScreen(),
    AdminUsersScreen(),
  ];

  Future<void> uploadHotelsToFirestore(BuildContext context) async {
    try {
      // Đọc file JSON từ assets
      final contents = await rootBundle.loadString('data/hotels_vietnam.json');
      final List<dynamic> hotels = json.decode(contents);

      // Đẩy từng khách sạn lên Firestore
      for (var hotel in hotels) {
        await FirebaseFirestore.instance.collection('hotels').add(hotel);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đẩy dữ liệu lên Firestore thành công!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đẩy dữ liệu lên Firestore: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.deepPurple,
        elevation: 0,
        title: const Text('Quản trị viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Chuyển sang chế độ khách hàng',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _screens[_selectedIndex]),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => uploadHotelsToFirestore(context),
              child: const Text('Đẩy dữ liệu khách sạn lên Firestore'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.deepPurple[50],
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Thống kê'),
          NavigationDestination(icon: Icon(Icons.hotel), label: 'Phòng'),
          NavigationDestination(
            icon: Icon(Icons.book_online),
            label: 'Đặt phòng',
          ),
          NavigationDestination(icon: Icon(Icons.people), label: 'Người dùng'),
        ],
      ),
    );
  }
}
