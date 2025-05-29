// TODO Implement this library.// lib/presentation/widgets/quick_stats_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/athlete.dart';
import 'dashboard_card.dart';

class QuickStatsWidget extends StatelessWidget {
  final int athleteCount;
  final List<Athlete> recentAthletes;

  const QuickStatsWidget({
    super.key,
    required this.athleteCount,
    required this.recentAthletes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı İstatistikler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Stats Cards Row
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Toplam Atlet',
                value: athleteCount.toString(),
                subtitle: 'Kayıtlı atlet',
                icon: Icons.people,
                color: Colors.blue,
                onTap: () {
                  // Navigation to athletes screen could be added here
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Bu Hafta',
                value: '0', // Mock data - gerçek test sayısı gelecek
                subtitle: 'Test yapıldı',
                icon: Icons.timeline,
                color: Colors.green,
              ),
            ),
          ],
        ),
        
        if (recentAthletes.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Son Güncellenen Atletler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildRecentAthletes(),
        ],
      ],
    );
  }

  Widget _buildRecentAthletes() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...recentAthletes.take(3).map((athlete) => _buildAthleteListItem(athlete)),
          if (recentAthletes.length > 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '+${recentAthletes.length - 3} daha...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAthleteListItem(Athlete athlete) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: athlete.gender == 'M' 
                ? Colors.blue.withOpacity(0.1)
                : Colors.pink.withOpacity(0.1),
            child: Text(
              athlete.firstName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: athlete.gender == 'M' ? Colors.blue : Colors.pink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  athlete.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${athlete.age} yaş${athlete.sport != null ? ' • ${athlete.sport}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Last updated
          Text(
            _formatLastUpdated(athlete.updatedAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Şimdi';
    }
  }
}