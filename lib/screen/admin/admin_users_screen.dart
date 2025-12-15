import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/Models/user_model.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList();

        if (users.isEmpty) {
          return const Center(child: Text('Chưa có người dùng nào'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _UserCard(user: users[index]);
          },
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple[100],
          backgroundImage: user.avatar != null
              ? NetworkImage(user.avatar!)
              : null,
          child: user.avatar == null
              ? Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.deepPurple[700],
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(user.fullName),
        subtitle: Text(user.email),
        trailing: _RoleChip(role: user.role),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final UserRole role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (role) {
      case UserRole.customer:
        color = Colors.blue;
        label = 'Khách';
        break;
      case UserRole.admin:
        color = Colors.purple;
        label = 'Admin';
        break;
      case UserRole.manager:
        color = Colors.orange;
        label = 'Quản lý';
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
