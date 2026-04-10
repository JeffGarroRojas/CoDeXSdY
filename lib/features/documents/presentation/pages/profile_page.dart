import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/database_service.dart';
import '../../data/models/user_profile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider) ?? 'guest';
    final isGuest = userId.startsWith('guest_');
    final profileAsync = ref.watch(profileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(context, ref, profile, isGuest),
                const SizedBox(height: 24),
                _buildStatsGrid(profile),
                const SizedBox(height: 24),
                _buildSettingsSection(context, ref, profile, isGuest),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool isGuest,
  ) {
    final displayName = profile.name ?? (isGuest ? 'Invitado' : 'Usuario');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.secondaryColor.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isGuest ? 'Modo Invitado (Local)' : 'Cuenta Local',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          if (isGuest) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Modo Invitado',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildStatsGrid(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.style,
                  '${profile.totalCardsStudied}',
                  'Flashcards',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.menu_book,
                  '${profile.totalDocuments}',
                  'Documentos',
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.timer,
                  '${profile.totalStudyMinutes}m',
                  'Estudiando',
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.local_fire_department,
                  '${profile.currentStreak}',
                  'Días racha',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    bool isGuest,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuración',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                'Recordatorios',
                Icons.notifications_outlined,
                () => _showReminderDialog(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                'Acerca de',
                Icons.info_outline,
                () => _showAboutDialog(context),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                'Borrar Datos',
                Icons.delete_outline,
                () => _showClearDataDialog(context),
                iconColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Borrar Datos'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres borrar todos tus datos locales? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.clearUserData(
                ref.read(currentUserIdProvider) ?? 'guest',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Datos borrados correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  void _showReminderDialog(BuildContext context) {
    int selectedHour = 8;
    int selectedMinute = 0;
    bool reminderEnabled = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Recordatorios',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Configura una alarma para estudiar',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      reminderEnabled ? Icons.alarm_on : Icons.alarm_off,
                      color: reminderEnabled
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recordatorio',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            reminderEnabled
                                ? '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}'
                                : 'Desactivado',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: reminderEnabled,
                      onChanged: (value) {
                        setState(() => reminderEnabled = value);
                        if (value) {
                          NotificationService.instance.requestPermissions();
                        }
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              if (reminderEnabled) ...[
                const SizedBox(height: 16),
                const Text(
                  'Hora:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQuickTimeChip(7, 0, selectedHour, selectedMinute, (
                      h,
                      m,
                    ) {
                      setState(() {
                        selectedHour = h;
                        selectedMinute = m;
                      });
                    }),
                    _buildQuickTimeChip(8, 0, selectedHour, selectedMinute, (
                      h,
                      m,
                    ) {
                      setState(() {
                        selectedHour = h;
                        selectedMinute = m;
                      });
                    }),
                    _buildQuickTimeChip(12, 0, selectedHour, selectedMinute, (
                      h,
                      m,
                    ) {
                      setState(() {
                        selectedHour = h;
                        selectedMinute = m;
                      });
                    }),
                    _buildQuickTimeChip(18, 0, selectedHour, selectedMinute, (
                      h,
                      m,
                    ) {
                      setState(() {
                        selectedHour = h;
                        selectedMinute = m;
                      });
                    }),
                    _buildQuickTimeChip(20, 0, selectedHour, selectedMinute, (
                      h,
                      m,
                    ) {
                      setState(() {
                        selectedHour = h;
                        selectedMinute = m;
                      });
                    }),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (reminderEnabled) {
                      try {
                        await NotificationService.instance
                            .scheduleDailyReminder(
                              hour: selectedHour,
                              minute: selectedMinute,
                              userId: '',
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Recordatorio para las ${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Activa los permisos de alarma en configuración',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } else {
                      await NotificationService.instance
                          .cancelAllNotifications();
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(reminderEnabled ? 'Guardar' : 'Desactivar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTimeChip(
    int hour,
    int minute,
    int selectedHour,
    int selectedMinute,
    Function(int, int) onSelected,
  ) {
    final isSelected = selectedHour == hour && selectedMinute == minute;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        ),
        backgroundColor: isSelected
            ? AppTheme.primaryColor
            : AppTheme.surfaceColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
        ),
        onPressed: () => onSelected(hour, minute),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CoDeXSdY'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: const Icon(Icons.smart_toy, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text('Versión 1.4.0 (Local)'),
            const SizedBox(height: 8),
            Text(
              'Asistente de estudio con IA',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(
              '100% datos locales',
              style: TextStyle(color: Colors.green[400], fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text('Creado por Jeff'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
