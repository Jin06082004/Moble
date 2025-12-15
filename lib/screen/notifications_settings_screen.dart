import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _emailNotifications = true;
  bool _bookingNotifications = true;
  bool _promotionNotifications = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        setState(() {
          _emailNotifications = doc.data()?['emailNotifications'] ?? true;
          _bookingNotifications = doc.data()?['bookingNotifications'] ?? true;
          _promotionNotifications =
              doc.data()?['promotionNotifications'] ?? false;
        });
      }
    } catch (e) {
      print('Lỗi tải cài đặt: $e');
    }
  }

  Future<void> _saveSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set({
            'emailNotifications': _emailNotifications,
            'bookingNotifications': _bookingNotifications,
            'promotionNotifications': _promotionNotifications,
            'updatedAt': Timestamp.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt thông báo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Thông báo qua Email'),
            subtitle: const Text('Nhận thông báo về đặt phòng qua email'),
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Thông báo đặt phòng'),
            subtitle: const Text('Nhận thông báo khi có cập nhật đặt phòng'),
            value: _bookingNotifications,
            onChanged: (value) {
              setState(() => _bookingNotifications = value);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Thông báo khuyến mãi'),
            subtitle: const Text('Nhận thông báo về các chương trình ưu đãi'),
            value: _promotionNotifications,
            onChanged: (value) {
              setState(() => _promotionNotifications = value);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu cài đặt'),
            ),
          ),
        ],
      ),
    );
  }
}
