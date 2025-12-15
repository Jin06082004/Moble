import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/Models/room_model.dart';

class AddEditRoomScreen extends StatefulWidget {
  final RoomModel? room; // null nếu thêm mới, có giá trị nếu sửa

  const AddEditRoomScreen({super.key, this.room});

  @override
  State<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends State<AddEditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _maxGuestsController;
  late TextEditingController _bedCountController;
  late TextEditingController _bathroomCountController;
  late TextEditingController _sizeController;
  late TextEditingController _imageUrlController;

  List<String> _imageUrls = [];
  List<String> _amenities = [];
  RoomType _type = RoomType.standard;
  RoomStatus _status = RoomStatus.available;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final room = widget.room;

    _nameController = TextEditingController(text: room?.name ?? '');
    _descriptionController = TextEditingController(
      text: room?.description ?? '',
    );
    _priceController = TextEditingController(
      text: room?.pricePerNight.toString() ?? '',
    );
    _maxGuestsController = TextEditingController(
      text: room?.maxGuests.toString() ?? '',
    );
    _bedCountController = TextEditingController(
      text: room?.bedCount.toString() ?? '',
    );
    _bathroomCountController = TextEditingController(
      text: room?.bathroomCount.toString() ?? '',
    );
    _sizeController = TextEditingController(text: room?.area.toString() ?? '');
    _imageUrlController = TextEditingController();

    if (room != null) {
      _imageUrls = List.from(room.images);
      _amenities = List.from(room.amenities);
      _type = room.type;
      _status = room.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _maxGuestsController.dispose();
    _bedCountController.dispose();
    _bathroomCountController.dispose();
    _sizeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 hình ảnh')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.room != null;
      final roomRef = isEditing
          ? FirebaseFirestore.instance.collection('rooms').doc(widget.room!.id)
          : FirebaseFirestore.instance.collection('rooms').doc();

      final room = RoomModel(
        id: roomRef.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        pricePerNight: double.parse(_priceController.text),
        maxGuests: int.parse(_maxGuestsController.text),
        bedCount: int.parse(_bedCountController.text),
        bathroomCount: int.parse(_bathroomCountController.text),
        area: double.parse(_sizeController.text),
        images: _imageUrls,
        amenities: _amenities,
        status: _status,
        createdAt: widget.room?.createdAt ?? DateTime.now(),
      );

      await roomRef.set(room.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Đã cập nhật phòng' : 'Đã thêm phòng mới',
            ),
          ),
        );
        Navigator.pop(context);
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

  void _addImageUrl() {
    if (_imageUrlController.text.trim().isNotEmpty) {
      setState(() {
        _imageUrls.add(_imageUrlController.text.trim());
        _imageUrlController.clear();
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _addAmenity() async {
    final amenity = await showDialog<String>(
      context: context,
      builder: (context) {
        String value = '';
        return AlertDialog(
          title: const Text('Thêm tiện nghi'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Ví dụ: WiFi miễn phí'),
            onChanged: (text) => value = text,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );

    if (amenity != null && amenity.isNotEmpty) {
      setState(() {
        _amenities.add(amenity);
      });
    }
  }

  void _removeAmenity(int index) {
    setState(() {
      _amenities.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.room != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Sửa phòng' : 'Thêm phòng mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên phòng',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên phòng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giá/đêm (VNĐ)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập giá';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Giá không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diện tích (m²)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập diện tích';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxGuestsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số khách',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập số khách';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bedCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số giường',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập số giường';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _bathroomCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số toilet',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập số toilet';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RoomType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Loại phòng',
                  border: OutlineInputBorder(),
                ),
                items: RoomType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RoomStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: RoomStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusLabel(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Hình ảnh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        hintText: 'URL hình ảnh',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addImageUrl,
                    child: const Text('Thêm'),
                  ),
                ],
              ),
              if (_imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrls.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _imageUrls[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tiện nghi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addAmenity,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_amenities.isEmpty)
                const Text(
                  'Chưa có tiện nghi nào',
                  style: TextStyle(color: Colors.grey),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenities.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      onDeleted: () => _removeAmenity(entry.key),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Cập nhật' : 'Thêm phòng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return 'Còn trống';
      case RoomStatus.occupied:
        return 'Đã đặt';
      case RoomStatus.maintenance:
        return 'Bảo trì';
      case RoomStatus.reserved:
        return 'Đã đặt trước';
    }
  }

  String _getTypeLabel(RoomType type) {
    switch (type) {
      case RoomType.standard:
        return 'Phòng tiêu chuẩn';
      case RoomType.deluxe:
        return 'Phòng cao cấp';
      case RoomType.suite:
        return 'Phòng suite';
      case RoomType.presidential:
        return 'Phòng tổng thống';
    }
  }
}
