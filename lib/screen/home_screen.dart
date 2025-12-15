import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/Models/room_model.dart';
import 'room_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'profie_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    RoomListView(),
    MyBookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              surfaceTintColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: const Text('Danh Sách Phòng'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            )
          : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Đặt phòng'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}

class RoomListView extends StatefulWidget {
  const RoomListView({super.key});

  @override
  State<RoomListView> createState() => _RoomListViewState();
}

class _RoomListViewState extends State<RoomListView> {
  RoomType? _selectedRoomType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter - Remove background color
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm phòng...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _selectedRoomType == null,
                      onSelected: (selected) {
                        setState(() => _selectedRoomType = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ...RoomType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getRoomTypeLabel(type)),
                          selected: _selectedRoomType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRoomType = selected ? type : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Room List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .where('status', isEqualTo: RoomStatus.available.name)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final rooms = snapshot.data!.docs
                  .map((doc) => RoomModel.fromFirestore(doc))
                  .where((room) {
                    // Filter by type
                    if (_selectedRoomType != null &&
                        room.type != _selectedRoomType) {
                      return false;
                    }
                    // Filter by search query
                    if (_searchQuery.isNotEmpty) {
                      return room.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          room.description.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                    }
                    return true;
                  })
                  .toList();

              if (rooms.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hotel_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Không tìm thấy phòng',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return RoomCard(room: room);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getRoomTypeLabel(RoomType type) {
    switch (type) {
      case RoomType.standard:
        return 'Tiêu chuẩn';
      case RoomType.deluxe:
        return 'Cao cấp';
      case RoomType.suite:
        return 'Suite';
      case RoomType.presidential:
        return 'Tổng thống';
    }
  }
}

class RoomCard extends StatelessWidget {
  final RoomModel room;

  const RoomCard({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RoomDetailScreen(room: room)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: room.images.isNotEmpty
                  ? Image.network(
                      room.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.hotel, size: 64),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.hotel, size: 64),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRoomTypeLabel(room.type),
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    room.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${room.maxGuests} khách'),
                      const SizedBox(width: 16),
                      Icon(Icons.bed, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${room.bedCount} giường'),
                      const SizedBox(width: 16),
                      Icon(Icons.bathtub, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${room.bathroomCount} WC'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${room.pricePerNight.toStringAsFixed(0)} VNĐ/đêm',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RoomDetailScreen(room: room),
                            ),
                          );
                        },
                        child: const Text('Xem chi tiết'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoomTypeLabel(RoomType type) {
    switch (type) {
      case RoomType.standard:
        return 'Tiêu chuẩn';
      case RoomType.deluxe:
        return 'Cao cấp';
      case RoomType.suite:
        return 'Suite';
      case RoomType.presidential:
        return 'Tổng thống';
    }
  }
}
