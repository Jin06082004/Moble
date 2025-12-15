import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  // Đọc cấu hình SMTP từ file .env
  static String get _username =>
      dotenv.env['SMTP_USERNAME'] ?? 'your-email@gmail.com';
  static String get _password =>
      dotenv.env['SMTP_PASSWORD'] ?? 'your-app-password';

  static SmtpServer get smtpServer => gmail(_username, _password);

  static Future<void> sendRegistrationEmail({
    required String recipientEmail,
    required String fullName,
  }) async {
    final message = Message()
      ..from = Address(_username, 'Booking App')
      ..recipients.add(recipientEmail)
      ..subject = 'Đăng ký tài khoản thành công'
      ..html =
          '''
        <h2>Chào mừng $fullName!</h2>
        <p>Cảm ơn bạn đã đăng ký tài khoản tại Booking App.</p>
        <p>Bạn có thể bắt đầu đặt phòng ngay bây giờ.</p>
        <p>Trân trọng,<br>Booking App Team</p>
      ''';

    try {
      await send(message, smtpServer);
      print('Email đăng ký đã được gửi đến $recipientEmail');
    } catch (e) {
      print('Lỗi gửi email: $e');
    }
  }

  static Future<void> sendBookingConfirmationEmail({
    required String recipientEmail,
    required String fullName,
    required String roomName,
    required String checkInDate,
    required String checkOutDate,
    required String totalPrice,
  }) async {
    final message = Message()
      ..from = Address(_username, 'Booking App')
      ..recipients.add(recipientEmail)
      ..subject = 'Xác nhận đặt phòng thành công'
      ..html =
          '''
        <h2>Xin chào $fullName!</h2>
        <p>Đặt phòng của bạn đã được xác nhận thành công.</p>
        <h3>Thông tin đặt phòng:</h3>
        <ul>
          <li><strong>Phòng:</strong> $roomName</li>
          <li><strong>Ngày nhận phòng:</strong> $checkInDate</li>
          <li><strong>Ngày trả phòng:</strong> $checkOutDate</li>
          <li><strong>Tổng tiền:</strong> $totalPrice VNĐ</li>
        </ul>
        <p>Cảm ơn bạn đã tin tưởng sử dụng dịch vụ của chúng tôi!</p>
        <p>Trân trọng,<br>Booking App Team</p>
      ''';

    try {
      await send(message, smtpServer);
      print('Email xác nhận đặt phòng đã được gửi đến $recipientEmail');
    } catch (e) {
      print('Lỗi gửi email: $e');
    }
  }

  static Future<void> sendPaymentConfirmationEmail({
    required String recipientEmail,
    required String fullName,
    required String roomName,
    required String totalPrice,
    required String transactionId,
  }) async {
    final message = Message()
      ..from = Address(_username, 'Booking App')
      ..recipients.add(recipientEmail)
      ..subject = 'Xác nhận thanh toán thành công'
      ..html =
          '''
        <h2>Xin chào $fullName!</h2>
        <p>Thanh toán của bạn đã được xử lý thành công.</p>
        <h3>Thông tin thanh toán:</h3>
        <ul>
          <li><strong>Phòng:</strong> $roomName</li>
          <li><strong>Số tiền:</strong> $totalPrice VNĐ</li>
          <li><strong>Mã giao dịch:</strong> $transactionId</li>
        </ul>
        <p>Vui lòng giữ lại email này làm biên lai thanh toán.</p>
        <p>Trân trọng,<br>Booking App Team</p>
      ''';

    try {
      await send(message, smtpServer);
      print('Email xác nhận thanh toán đã được gửi đến $recipientEmail');
    } catch (e) {
      print('Lỗi gửi email: $e');
    }
  }
}
