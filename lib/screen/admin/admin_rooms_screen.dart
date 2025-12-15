import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/Models/room_model.dart';
import 'add_edit_room_screen.dart';

class AdminRoomsScreen extends StatelessWidget {
  const AdminRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList();

          if (rooms.isEmpty) {
            return const Center(child: Text('Chưa có phòng nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _RoomAdminCard(room: room);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddEditRoomScreen()));
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _RoomAdminCard extends StatelessWidget {
  final RoomModel room;

  const _RoomAdminCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: room.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  room.images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.hotel),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hotel),
              ),
        title: Text(room.name),
        subtitle: Text('${room.pricePerNight.toStringAsFixed(0)} VNĐ/đêm'),
        trailing: _StatusChip(status: room.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.description),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.people,
                        label: 'Khách',
                        value: '${room.maxGuests}',
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.bed,
                        label: 'Giường',
                        value: '${room.bedCount}',
                      ),
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.bathtub,
                        label: 'Phòng tắm',
                        value: '${room.bathroomCount}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditRoomScreen(room: room),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Sửa'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateRoomStatus(context, room),
                        icon: const Icon(Icons.sync),
                        label: const Text('Đổi trạng thái'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRoomStatus(BuildContext context, RoomModel room) async {
    final newStatus = await showDialog<RoomStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn trạng thái mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoomStatus.values.map((status) {
            return ListTile(
              title: Text(_getStatusLabel(status)),
              trailing: room.status == status
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && newStatus != room.status) {
      try {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(room.id)
            .update({'status': newStatus.name});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật trạng thái phòng')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  String _getStatusLabel(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Có sẵn';
      case RoomStatus.occupied:
        return 'Đã đặt';
      case RoomStatus.maintenance:
        return 'Bảo trì';
      case RoomStatus.reserved:
        return 'Đã giữ chỗ';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final RoomStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case RoomStatus.available:
        color = Colors.green;
        label = 'Có sẵn';
        break;
      case RoomStatus.occupied:
        color = Colors.red;
        label = 'Đã đặt';
        break;
      case RoomStatus.maintenance:
        color = Colors.orange;
        label = 'Bảo trì';
        break;
      case RoomStatus.reserved:
        color = Colors.blue;
        label = 'Đã giữ';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
