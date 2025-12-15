import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ giúp')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Câu hỏi thường gặp',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _FAQTile(
            question: 'Làm thế nào để đặt phòng?',
            answer:
                'Chọn phòng bạn muốn, nhấn "Đặt phòng ngay", chọn ngày nhận/trả phòng, điền thông tin và thanh toán.',
          ),
          _FAQTile(
            question: 'Tôi có thể hủy đặt phòng không?',
            answer:
                'Có, bạn có thể hủy đặt phòng trong mục "Đặt phòng của tôi" khi trạng thái đang chờ hoặc đã xác nhận.',
          ),
          _FAQTile(
            question: 'Các phương thức thanh toán nào được hỗ trợ?',
            answer:
                'Chúng tôi hỗ trợ thanh toán bằng tiền mặt, thẻ tín dụng, thẻ ghi nợ, chuyển khoản ngân hàng, MoMo và ZaloPay.',
          ),
          _FAQTile(
            question: 'Làm thế nào để thay đổi thông tin cá nhân?',
            answer:
                'Vào "Tài khoản" > "Chỉnh sửa thông tin" để cập nhật họ tên và số điện thoại.',
          ),
          _FAQTile(
            question: 'Làm thế nào để đổi mật khẩu?',
            answer:
                'Vào "Tài khoản" > "Đổi mật khẩu", nhập mật khẩu hiện tại và mật khẩu mới.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Liên hệ hỗ trợ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Hotline'),
              subtitle: const Text('1900-xxxx'),
              trailing: const Icon(Icons.call),
              onTap: () async {
                final Uri uri = Uri(scheme: 'tel', path: '1900xxxx');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('support@bookingapp.com'),
              trailing: const Icon(Icons.mail),
              onTap: () async {
                final Uri uri = Uri(
                  scheme: 'mailto',
                  path: 'support@bookingapp.com',
                  query: 'subject=Yêu cầu hỗ trợ',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat trực tuyến'),
              subtitle: const Text('8:00 - 22:00 hàng ngày'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chức năng chat đang phát triển'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQTile({required this.question, required this.answer});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(widget.question),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.answer),
          ),
        ],
      ),
    );
  }
}
