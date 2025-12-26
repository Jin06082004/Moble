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
      appBar: AppBar(
        title: const Text(
          'Cài đặt thông báo',
          style: TextStyle(
            color: Color(0xFF667eea),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF667eea)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Thông báo qua Email',
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Nhận thông báo về đặt phòng qua email'),
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                  },
                  activeColor: const Color(0xFF764ba2),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text(
                    'Thông báo đặt phòng',
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Nhận thông báo khi có cập nhật đặt phòng',
                  ),
                  value: _bookingNotifications,
                  onChanged: (value) {
                    setState(() => _bookingNotifications = value);
                  },
                  activeColor: const Color(0xFF764ba2),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text(
                    'Thông báo khuyến mãi',
                    style: TextStyle(
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Nhận thông báo về các chương trình ưu đãi',
                  ),
                  value: _promotionNotifications,
                  onChanged: (value) {
                    setState(() => _promotionNotifications = value);
                  },
                  activeColor: const Color(0xFF764ba2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.zero,
                elevation: 0,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu cài đặt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
