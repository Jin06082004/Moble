import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../database/Models/hotel_model.dart';
import 'hotel_booking_screen.dart';

class HotelAISearchScreen extends StatefulWidget {
  const HotelAISearchScreen({super.key});

  @override
  State<HotelAISearchScreen> createState() => _HotelAISearchScreenState();
}

class _HotelAISearchScreenState extends State<HotelAISearchScreen> {
  // Hotel search state
  final _destinationController = TextEditingController();
  List<Hotel> _hotels = [];
  bool _isLoading = false;
  String? _selectedBudget;
  String? _selectedHotelType;
  List<String> _selectedPreferences = [];

  final List<String> _budgetOptions = [
    'Tiết kiệm (< 1 triệu/đêm)',
    'Trung bình (1-3 triệu/đêm)',
    'Cao cấp (3-5 triệu/đêm)',
    'Sang trọng (> 5 triệu/đêm)',
  ];

  final List<String> _hotelTypes = [
    'Khách sạn',
    'Resort',
    'Homestay',
    'Villa',
    'Hotel',
  ];

  final List<String> _preferenceOptions = [
    'Gần biển',
    'Trung tâm thành phố',
    'View đẹp',
    'Có bể bơi',
    'Có spa',
    'Thân thiện gia đình',
    'Phù hợp công tác',
  ];

  // AI chat state
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _history = [];
  bool _isAILoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedBudget = _budgetOptions[1];
    _selectedHotelType = _hotelTypes[0];
  }

  // Hotel search logic
  Future<void> _searchHotels() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hotels')
          .get();
      final hotels = snapshot.docs
          .map((doc) => Hotel.fromJson(doc.data()))
          .toList();
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bộ lọc tìm kiếm',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Ngân sách',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._budgetOptions.map(
                      (budget) => RadioListTile<String>(
                        title: Text(budget),
                        value: budget,
                        groupValue: _selectedBudget,
                        activeColor: const Color(0xFF764ba2),
                        onChanged: (value) {
                          setState(() => _selectedBudget = value);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Loại hình lưu trú',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _hotelTypes
                          .map(
                            (type) => ChoiceChip(
                              label: Text(type),
                              selected: _selectedHotelType == type,
                              selectedColor: const Color(0xFFe0e7ff),
                              labelStyle: TextStyle(
                                color: _selectedHotelType == type
                                    ? const Color(0xFF667eea)
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedHotelType = selected ? type : null;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Tiện ích mong muốn',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _preferenceOptions
                          .map(
                            (pref) => FilterChip(
                              label: Text(pref),
                              selected: _selectedPreferences.contains(pref),
                              selectedColor: const Color(0xFFe0e7ff),
                              labelStyle: TextStyle(
                                color: _selectedPreferences.contains(pref)
                                    ? const Color(0xFF667eea)
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedPreferences.add(pref);
                                  } else {
                                    _selectedPreferences.remove(pref);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _searchHotels();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Áp dụng bộ lọc',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AI chat logic
  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _history.add(_ChatMessage(message: message, isUser: true));
      _textController.clear();
      _isAILoading = true;
    });
    _scrollToBottom();

    try {
      final responseText = await _callOpenAIGPT(message);
      setState(() {
        _history.add(_ChatMessage(message: responseText, isUser: false));
        _isAILoading = false;
      });
    } catch (e) {
      setState(() {
        _history.add(
          _ChatMessage(message: 'Đã có lỗi xảy ra: $e', isUser: false),
        );
        _isAILoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _callOpenAIGPT(String userMessage) async {
    final prompt =
        '''
Bạn là trợ lý AI chuyên hỗ trợ đặt khách sạn trong ứng dụng mobile.

Nhiệm vụ của bạn:
- Khi người dùng yêu cầu tìm khách sạn, hãy đề xuất các khách sạn CỤ THỂ
- Trả lời bằng tiếng Việt, giọng thân thiện, dễ hiểu
- Không trả lời chung chung hay chỉ gợi ý website

Với mỗi khách sạn, hãy cung cấp đầy đủ:
- Tên khách sạn
- Khu vực / địa chỉ
- Hạng sao
- Giá tham khảo mỗi đêm
- Tiện ích nổi bật
- Đánh giá trung bình (nếu có)

Nếu người dùng không nói rõ ngân sách hay khu vực, hãy tự đề xuất 3–5 khách sạn phổ biến, phù hợp với đa số du khách.

Câu hỏi của người dùng:
"$userMessage"
''';

    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw 'Lỗi: Không tìm thấy OPENAI_API_KEY trong file .env';
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 512,
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content']?.trim() ??
          'Không có phản hồi từ AI.';
    } else {
      throw 'Lỗi API: ${response.statusCode} - ${response.body}';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Tìm khách sạn & Trợ lý AI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF667eea),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF667eea),
            unselectedLabelColor: Color(0xFF764ba2),
            indicatorColor: Color(0xFF667eea),
            tabs: [
              Tab(icon: Icon(Icons.hotel), text: 'Tìm khách sạn'),
              Tab(icon: Icon(Icons.smart_toy), text: 'Trợ lý AI'),
            ],
          ),
          actions: [
            Builder(
              builder: (context) {
                final tabIndex = DefaultTabController.of(context)?.index ?? 0;
                if (tabIndex == 0) {
                  return IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF764ba2)),
                    onPressed: _showFilterBottomSheet,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Hotel Search Tab
            Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          hintText: 'Bạn muốn đi đâu?',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF667eea),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onSubmitted: (_) => _searchHotels(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showFilterBottomSheet,
                              icon: const Icon(
                                Icons.filter_list,
                                size: 18,
                                color: Color(0xFF764ba2),
                              ),
                              label: Text(
                                _selectedBudget?.split('(')[0].trim() ??
                                    'Ngân sách',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF667eea),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF667eea),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _searchHotels,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.search,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isLoading ? 'Đang tìm...' : 'Tìm khách sạn',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFF667eea),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Hotel List
                Expanded(
                  child: _hotels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.hotel,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nhập điểm đến để tìm khách sạn',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hệ thống sẽ gợi ý những lựa chọn tốt nhất cho bạn',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _hotels.length,
                          itemBuilder: (context, index) {
                            final hotel = _hotels[index];
                            return _buildHotelCard(hotel);
                          },
                        ),
                ),
              ],
            ),
            // AI Chat Tab
            _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            final chat = _history[index];
                            return _ChatBubble(
                              message: chat.message,
                              isUser: chat.isUser,
                            );
                          },
                        ),
                      ),
                      if (_isAILoading)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      _buildInputArea(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Hotel Card
  Widget _buildHotelCard(Hotel hotel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: const Color(0xFF667eea).withOpacity(0.08),
      child: InkWell(
        onTap: () => _showHotelDetails(hotel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              hotel.imageUrl.isNotEmpty
                  ? hotel.imageUrl
                  : 'https://via.placeholder.com/400x200?text=Hotel+Image',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.hotel, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hotel.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF764ba2),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hotel.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hotel.priceRange,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showHotelDetails(hotel),
                        child: const Text('Xem chi tiết →'),
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

  void _showHotelDetails(Hotel hotel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                hotel.imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Icon(Icons.hotel, size: 80),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            hotel.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667eea),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              hotel.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF764ba2)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hotel.location,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hotel.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tiện nghi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hotel.amenities.map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                amenity,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Giá phòng',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hotel.priceRange,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HotelBookingScreen(hotel: hotel),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              backgroundColor: const Color(0xFF667eea),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Đặt ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map, color: Color(0xFF764ba2)),
                      label: const Text(
                        'Xem bản đồ',
                        style: TextStyle(color: Color(0xFF667eea)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF667eea)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final availableMaps = await MapLauncher.installedMaps;
                        if (availableMaps.isNotEmpty) {
                          await availableMaps.first.showMarker(
                            coords: Coords(hotel.latitude, hotel.longitude),
                            title: hotel.name,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AI chat input area
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: (_isAILoading) ? null : _sendMessage,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  final String message;
  final bool isUser;
  _ChatMessage({required this.message, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 12),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
