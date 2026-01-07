// pages/notification/notification_page.dart
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_smarthome/Models/UnifiedNotificationModel.dart';
import 'package:flutter/material.dart';
import 'package:iot_smarthome/Pages/Notification/Widget/NotificationDetail.dart';
import 'package:iot_smarthome/Providers/NotificationProviders.dart';
import 'package:iot_smarthome/pages/home/dialog.dart';
import 'package:kf_drawer/kf_drawer.dart';
import 'package:intl/intl.dart';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      ref.read(notificationSelectionControllerProvider.notifier)
          .setCurrentTab(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Hàm lấy icon và màu sắc theo loại thông báo
  (IconData, Color, Color, Color) _getNotificationStyle(UnifiedNotificationModel notification, bool isDark) {
    final darkMode = isDark;
    
    if (notification.isInvitation) {
      return (
        Icons.mail_outline,
        darkMode ? Color(0xFF60A5FA) : Color(0xFF2563EB),
        darkMode ? Color(0xFF1E3A8A) : Color(0xFFDBEAFE),
        darkMode ? Color(0xFF3B82F6).withOpacity(0.2) : Color(0xFFDBEAFE)
      );
    } else if (notification.isInvitationResponse) {
      final isAccepted = notification.status == 'accepted';
      return (
        isAccepted ? Icons.check_circle : Icons.cancel,
        isAccepted 
          ? (darkMode ? Color(0xFF34D399) : Color(0xFF059669))
          : (darkMode ? Color(0xFFF87171) : Color(0xFFDC2626)),
        isAccepted
          ? (darkMode ? Color(0xFF052E16) : Color(0xFFD1FAE5))
          : (darkMode ? Color(0xFF450A0A) : Color(0xFFFEE2E2)),
        isAccepted
          ? (darkMode ? Color(0xFF10B981).withOpacity(0.2) : Color(0xFFD1FAE5))
          : (darkMode ? Color(0xFFDC2626).withOpacity(0.2) : Color(0xFFFEE2E2))
      );
    } else {
      // Device alerts - giữ nguyên logic cũ
      final type = notification.deviceType?.toLowerCase() ?? 'device';
      switch (type) {
        case 'warning':
          return (
            Icons.warning_amber_rounded,
            darkMode ? Color(0xFFFBBF24) : Color(0xFFD97706),
            darkMode ? Color(0xFF451A03) : Color(0xFFFEF3C7),
            darkMode ? Color(0xFFF59E0B).withOpacity(0.2) : Color(0xFFFEF3C7)
          );
        case 'alert':
          return (
            Icons.security,
            darkMode ? Color(0xFFEF4444) : Color(0xFFDC2626),
            darkMode ? Color(0xFF450A0A) : Color(0xFFFEE2E2),
            darkMode ? Color(0xFFEF4444).withOpacity(0.2) : Color(0xFFFEE2E2)
          );
        case 'info':
          return (
            Icons.info,
            darkMode ? Color(0xFF60A5FA) : Color(0xFF2563EB),
            darkMode ? Color(0xFF172554) : Color(0xFFDBEAFE),
            darkMode ? Color(0xFF3B82F6).withOpacity(0.2) : Color(0xFFDBEAFE)
          );
        case 'success':
          return (
            Icons.check_circle,
            darkMode ? Color(0xFF34D399) : Color(0xFF059669),
            darkMode ? Color(0xFF052E16) : Color(0xFFD1FAE5),
            darkMode ? Color(0xFF10B981).withOpacity(0.2) : Color(0xFFD1FAE5)
          );
        case 'error':
          return (
            Icons.error,
            darkMode ? Color(0xFFF87171) : Color(0xFFDC2626),
            darkMode ? Color(0xFF450A0A) : Color(0xFFFEE2E2),
            darkMode ? Color(0xFFDC2626).withOpacity(0.2) : Color(0xFFFEE2E2)
          );
        case 'device':
          return (
            DialogUtils.getDeviceIcon(type),
            darkMode ? Color(0xFFA78BFA) : Color(0xFF7C3AED),
            darkMode ? Color(0xFF2E1065) : Color(0xFFEDE9FE),
            darkMode ? Color(0xFF8B5CF6).withOpacity(0.2) : Color(0xFFEDE9FE)
          );
        case 'security':
          return (
            Icons.camera_indoor,
            darkMode ? Color(0xFF818CF8) : Color(0xFF4F46E5),
            darkMode ? Color(0xFF1E1B4B) : Color(0xFFE0E7FF),
            darkMode ? Color(0xFF6366F1).withOpacity(0.2) : Color(0xFFE0E7FF)
          );
        case 'trash':
          return (
            Icons.delete,
            darkMode ? Color.fromARGB(255, 77, 239, 68) : Color.fromARGB(255, 4, 198, 33),
            darkMode ? Color.fromARGB(255, 25, 127, 19) : Color.fromARGB(255, 155, 229, 151),
            darkMode ? Color.fromARGB(255, 86, 226, 78).withOpacity(0.2) : Color.fromARGB(255, 242, 247, 242)
          );
        case 'rfid':
          return (
            Icons.security,
            darkMode ? Color.fromRGBO(105, 157, 241, 1) : Color.fromRGBO(105, 157, 241, 1),
            darkMode ? Color.fromRGBO(25, 51, 102, 1) : Color.fromRGBO(25, 51, 102, 1),
            darkMode ? Color.fromRGBO(105, 157, 241, 0.2) : Color.fromRGBO(105, 157, 241, 0.2)
          );
        default:
          return (
            Icons.notifications,
            darkMode ? Color(0xFF9CA3AF) : Color(0xFF6B7280),
            darkMode ? Color(0xFF1F2937) : Color(0xFFF3F4F6),
            darkMode ? Color(0xFF6B7280).withOpacity(0.2) : Color(0xFFF3F4F6)
          );
      }
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  bool get _isDarkMode {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // 🎯 Hàm xóa nhiều thông báo
  void _deleteSelectedItems(BuildContext context) async {
    final selectedNotifications = ref.read(selectedNotificationsProvider).toList();
    final notificationController = ref.read(unifiedNotificationControllerProvider);
    
    if (selectedNotifications.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.delete_forever_rounded, 
                 color: Color(0xFFEF4444), size: 50),
            SizedBox(height: 10),
            Text(
              'Xóa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${selectedNotifications.length} mục đã chọn?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
            ),
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      for (final id in selectedNotifications) {
        await notificationController.deleteNotification(id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${selectedNotifications.length} mục'),
            backgroundColor: _isDarkMode ? Color(0xFFDC2626) : Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: Duration(seconds: 3),
          ),
        );
      }

      ref.read(notificationSelectionControllerProvider.notifier).clearSelection();
    }
  }

  // 🎯 Hàm đánh dấu đã đọc nhiều mục
  void _markSelectedAsRead(BuildContext context) async {
    final selectedNotifications = ref.read(selectedNotificationsProvider).toList();
    final notificationController = ref.read(unifiedNotificationControllerProvider);
    
    if (selectedNotifications.isEmpty) return;

    for (final id in selectedNotifications) {
      await notificationController.markAsRead(id);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đánh dấu ${selectedNotifications.length} mục đã đọc'),
          backgroundColor: _isDarkMode ? Color(0xFF059669) : Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 2),
        ),
      );
    }

    ref.read(notificationSelectionControllerProvider.notifier).clearSelection();
  }

  // 🎯 Hàm xử lý khi tap vào notification
  void _onNotificationTap(UnifiedNotificationModel notification, BuildContext context) {
    final isSelectionMode = ref.read(isSelectionModeProvider);
    final selectionController = ref.read(notificationSelectionControllerProvider.notifier);
    final notificationController = ref.read(unifiedNotificationControllerProvider);
    
    if (isSelectionMode) {
      selectionController.toggleNotificationSelection(notification.id);
    } else {
      if (notification.isDeviceAlert) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotificationDetailPage(notification: notification),
          ),
        );
      } else if (notification.isInvitation && notification.status == 'pending') {
        _showInvitationDialog(notification);
      }
      
      if (!notification.isRead) {
        notificationController.markAsRead(notification.id);
      }
    }
  }

  // 🎯 Hiển thị dialog xử lý invitation
  void _showInvitationDialog(UnifiedNotificationModel invitation) {
    final notificationController = ref.read(unifiedNotificationControllerProvider);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mail_outline, color: Colors.blue, size: 40),
              ),
              
              SizedBox(height: 16),
              
              // Title
              Text(
                '📨 Lời mời tham gia nhà',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              SizedBox(height: 12),
              
              // Content
              Text(
                '${invitation.fromUserName} mời bạn tham gia ngôi nhà ${invitation.homeName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Email: ${invitation.fromUserEmail}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        notificationController.respondToInvitation(invitation.id, 'rejected');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Từ chối'),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        notificationController.respondToInvitation(invitation.id, 'accepted');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Chấp nhận'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(isDark),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Tất cả
                _buildAllNotificationsTab(isDark, context),
                // Tab 1: Thông báo
                _buildNotificationsTab(isDark, context),
                // Tab 2: Lời mời
                _buildInvitationsTab(isDark, context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // 🎯 Xây dựng AppBar
  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      title: Consumer(
        builder: (context, ref, child) {
          final isSelectionMode = ref.watch(isSelectionModeProvider);
          final totalSelected = ref.watch(totalSelectedCountProvider);
          
          return isSelectionMode 
            ? Text(
                'Đã chọn: $totalSelected',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: isDark ? Colors.white : Color(0xFF0F172A),
                ),
              )
            : Text(
                "Thông Báo",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: isDark ? Colors.white : Color(0xFF0F172A),
                ),
              );
        },
      ),
      leading: Consumer(
        builder: (context, ref, child) {
          final isSelectionMode = ref.watch(isSelectionModeProvider);
          final selectionController = ref.read(notificationSelectionControllerProvider.notifier);
          
          return isSelectionMode
            ? IconButton(
                icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Color(0xFF0F172A)),
                onPressed: selectionController.clearSelection,
              )
            : IconButton(
                icon: Icon(Icons.menu, color: isDark ? Colors.white : Color(0xFF0F172A)),
                onPressed: () => KFDrawer.of(context)?.toggle(),
              );
        },
      ),
      backgroundColor: isDark ? Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      centerTitle: false,
      shadowColor: isDark ? Colors.transparent : Colors.black12,
      surfaceTintColor: Colors.transparent,
      actions: _buildAppBarActions(isDark),
    );
  }

  // 🎯 Xây dựng TabBar
  PreferredSizeWidget _buildTabBar(bool isDark) {
    return TabBar(
      controller: _tabController,
      indicatorColor: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
      labelColor: isDark ? Colors.white : Colors.blue.shade700,
      unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      tabs: [
        Tab(text: 'Tất cả'),
        Tab(text: 'Cảnh báo'),
        Tab(text: 'Lời mời'),
      ],
    );
  }

  // 🎯 Xây dựng actions cho AppBar
  List<Widget> _buildAppBarActions(bool isDark) {
    return [
      Consumer(
        builder: (context, ref, child) {
          final isSelectionMode = ref.watch(isSelectionModeProvider);
          final totalSelected = ref.watch(totalSelectedCountProvider);
          
          if (isSelectionMode) {
            return Row(
              children: [
                // Nút đánh dấu đã đọc
                IconButton(
                  icon: Icon(Icons.mark_email_read_rounded, 
                             color: isDark ? Colors.white : Color(0xFF0F172A)),
                  onPressed: totalSelected > 0 
                      ? () => _markSelectedAsRead(context)
                      : null,
                  tooltip: 'Đánh dấu đã đọc',
                ),
                // Nút xóa
                IconButton(
                  icon: Icon(Icons.delete_rounded, 
                             color: isDark ? Color(0xFFEF4444) : Color(0xFFDC2626)),
                  onPressed: totalSelected > 0
                      ? () => _deleteSelectedItems(context)
                      : null,
                  tooltip: 'Xóa',
                ),
              ],
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    ];
  }

  // 🎯 Tab: Tất cả
  Widget _buildAllNotificationsTab(bool isDark, BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notificationsAsync = ref.watch(notificationsStreamProvider);
        
        return notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return _buildEmptyState(isDark);
            }
            return _buildNotificationList(notifications, isDark, context);
          },
          loading: () => _buildLoadingState(isDark),
          error: (error, stack) {
            debugPrint("Error: ${error.toString()}");
            return _buildErrorState(isDark);
          },
        );
      },
    );
  }

  // 🎯 Tab: Thông báo (chỉ device alerts)
  Widget _buildNotificationsTab(bool isDark, BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notificationsAsync = ref.watch(deviceAlertsStreamProvider);
        
        return notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return _buildEmptyTabState(isDark, 'Không có thông báo nào');
            }
            return _buildNotificationList(notifications, isDark, context);
          },
          loading: () => _buildLoadingState(isDark),
          error: (error, stack) {
            debugPrint("Error: ${error.toString()}");
            return _buildErrorState(isDark);
          },
        );
      },
    );
  }

  // 🎯 Tab: Lời mời
  Widget _buildInvitationsTab(bool isDark, BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notificationsAsync = ref.watch(invitationsStreamProvider);
        
        return notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return _buildEmptyTabState(isDark, 'Không có lời mời nào');
            }
            return _buildNotificationList(notifications, isDark, context);
          },
          loading: () => _buildLoadingState(isDark),
          error: (error, stack) => _buildErrorState(isDark),
        );
      },
    );
  }

  // 🎯 Xây dựng danh sách chung
  Widget _buildNotificationList(List<UnifiedNotificationModel> notifications, bool isDark, BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Consumer(
            builder: (context, ref, child) {
              final isSelectionMode = ref.watch(isSelectionModeProvider);
              final totalSelected = ref.watch(totalSelectedCountProvider);
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSelectionMode ? "Đang chọn" : "Danh sách",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSelectionMode 
                          ? "$totalSelected mục được chọn"
                          : "${notifications.length} mục • $unreadCount chưa đọc",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (!isSelectionMode && unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark 
                            ? [Color(0xFFEF4444), Color(0xFFDC2626)]
                            : [Color(0xFFDC2626), Color(0xFFB91C1C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(isDark ? 0.3 : 0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            "$unreadCount chưa đọc",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Selection toolbar (khi đang chọn)
        Consumer(
          builder: (context, ref, child) {
            final isSelectionMode = ref.watch(isSelectionModeProvider);
            
            return isSelectionMode 
                ? _buildSelectionToolbar(isDark, context, notifications)
                : const SizedBox.shrink();
          },
        ),
        
        // List
        Expanded(
          child: ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification, isDark, context);
            },
          ),
        ),
      ],
    );
  }

  // 🎯 Widget notification item thống nhất
  Widget _buildNotificationItem(UnifiedNotificationModel notification, bool isDark, BuildContext context) {
    final (icon, color, bgColor, glowColor) = _getNotificationStyle(notification, isDark);
    final timeText = _formatTime(notification.timestamp);
    final isPendingInvitation = notification.isInvitation && notification.status == 'pending';
    
    return Builder(
      builder: (BuildContext innerContext) {
        return Consumer(
          builder: (context, ref, child) {
            final isSelected = ref.watch(notificationSelectionControllerProvider
                .select((state) => state.selectedNotifications.contains(notification.id)));
            final isSelectionMode = ref.watch(isSelectionModeProvider);
            final selectionController = ref.read(notificationSelectionControllerProvider.notifier);
            final notificationController = ref.read(unifiedNotificationControllerProvider);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Slidable(
                key: ValueKey('notification_${notification.id}'),
                endActionPane: isSelectionMode ? null : ActionPane(
                  motion: const StretchMotion(),
                  children: [
                    const SizedBox(width: 10),
                    SlidableAction(
                      onPressed: (context) {
                        if (!notification.isRead) {
                          notificationController.markAsRead(notification.id);
                        }
                      },
                      backgroundColor: isDark ? Color(0xFF059669) : Color(0xFF10B981),
                      icon: Icons.mark_email_read,
                      label: notification.isRead ? 'Đã đọc' : 'Đánh dấu đã đọc',
                      borderRadius: BorderRadius.circular(16),
                      spacing: 8,
                      foregroundColor: Colors.white,
                    ),
                    if (notification.isDeviceAlert) ...[
                      const SizedBox(width: 10),
                      SlidableAction(
                        onPressed: (innerContext) => _deleteNotification(notification, innerContext),
                        backgroundColor: isDark ? Color(0xFFDC2626) : Color(0xFFEF4444),
                        icon: Icons.delete_rounded,
                        label: 'Xóa',
                        borderRadius: BorderRadius.circular(16),
                        spacing: 8,
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _onNotificationTap(notification, context),
                  onLongPress: () => selectionController.toggleNotificationSelection(notification.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? (isDark ? Color(0xFF3B82F6).withOpacity(0.3) : Color(0xFFDBEAFE))
                        : (isDark 
                            ? (notification.isRead ? Color(0xFF1E293B) : Color(0xFF1E3A8A))
                            : (notification.isRead ? Colors.white : Color(0xFFE0F2FE))),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!notification.isRead && !isSelected)
                          BoxShadow(
                            color: glowColor,
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        BoxShadow(
                          color: isDark 
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected
                          ? (isDark ? Color(0xFF3B82F6) : Color(0xFF2563EB))
                          : (isDark
                              ? (notification.isRead ? Colors.transparent : color.withOpacity(0.3))
                              : (notification.isRead ? Colors.grey.shade200 : color.withOpacity(0.3))),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Selection indicator
                        if (isSelected)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isDark ? Color(0xFF3B82F6) : Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? Color(0xFF3B82F6) : Color(0xFF2563EB)).withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(Icons.check_rounded, 
                                        color: Colors.white, 
                                        size: 16),
                            ),
                          ),
                        
                        // Background pattern
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: isDark ? 0.05 : 0.03,
                            child: Icon(icon, size: 80, color: color),
                          ),
                        ),
                        
                        Padding(
                          padding: EdgeInsets.all(20).copyWith(
                            left: isSelected ? 44 : 20,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon với background glow effect
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? (isDark ? Color(0xFF3B82F6) : Color(0xFF2563EB))
                                    : bgColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    if (!isSelected)
                                      BoxShadow(
                                        color: color.withOpacity(isDark ? 0.3 : 0.2),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                  ],
                                ),
                                child: Icon(icon, 
                                          color: isSelected ? Colors.white : color, 
                                          size: 26),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Nội dung
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notification.message,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                                              color: isSelected 
                                                ? (isDark ? Colors.white : Color(0xFF0F172A))
                                                : (isDark ? Colors.white : Color(0xFF0F172A)),
                                              height: 1.4,
                                            ),
                                            maxLines: notification.isInvitation ? 2 : 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (notification.isDeviceAlert)
                                          Chip(
                                            label: Text(
                                              notification.isProcessed ? 'Đã xử lý' : 'Chưa xử lý',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isDark ? FontWeight.w500 : FontWeight.w600,
                                                color: notification.isProcessed 
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700, 
                                              ),
                                            ),
                                          )
                                        else if (notification.isInvitation)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isPendingInvitation 
                                                ? Colors.orange 
                                                : (notification.status == 'accepted' ? Colors.green : Colors.red)
                                              ).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isPendingInvitation 
                                                ? 'Chờ xử lý'
                                                : (notification.status == 'accepted' ? 'Đã chấp nhận' : 'Đã từ chối'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isPendingInvitation 
                                                  ? Colors.orange
                                                  : (notification.status == 'accepted' ? Colors.green : Colors.red),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Thông tin bổ sung
                                    if (notification.isInvitation) ...[
                                      Text(
                                        'Từ: ${notification.fromUserName} (${notification.fromUserEmail})',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isSelected
                                            ? (isDark ? Colors.white.withOpacity(0.8) : Colors.blue.shade700)
                                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Ngôi nhà: ${notification.homeName}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isSelected
                                            ? (isDark ? Colors.white.withOpacity(0.8) : Colors.blue.shade700)
                                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                        ),
                                      ),
                                    ] else if (notification.isDeviceAlert) ...[
                                      if (notification.deviceName?.isNotEmpty == true)
                                        Text(
                                          'Thiết bị: ${notification.deviceName}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isSelected
                                              ? (isDark ? Colors.white.withOpacity(0.8) : Colors.blue.shade700)
                                              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                          ),
                                        ),
                                    ],
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Thời gian
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                          ? (isDark ? Colors.white.withOpacity(0.2) : Colors.blue.shade100)
                                          : (isDark ? Colors.black.withOpacity(0.4) : Colors.grey.shade100),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                            ? (isDark ? Colors.white.withOpacity(0.3) : Colors.blue.shade200)
                                            : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time, size: 14, 
                                               color: isSelected
                                                 ? (isDark ? Colors.white : Colors.blue.shade700)
                                                 : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                          const SizedBox(width: 6),
                                          Text(
                                            timeText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected
                                                ? (isDark ? Colors.white : Colors.blue.shade700)
                                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Indicator chưa đọc
                              if (!notification.isRead && !isSelected)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🎯 Toolbar khi đang chọn nhiều mục
  Widget _buildSelectionToolbar(bool isDark, BuildContext context, List<UnifiedNotificationModel> notifications) {
    return Consumer(
      builder: (context, ref, child) {
        final selectionController = ref.read(notificationSelectionControllerProvider.notifier);
        final totalSelected = ref.watch(totalSelectedCountProvider);
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF334155) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Select All
              TextButton.icon(
                onPressed: () {
                  selectionController.selectAllNotifications(notifications);
                },
                icon: Icon(Icons.select_all_rounded, 
                           size: 18, 
                           color: isDark ? Colors.blue.shade300 : Colors.blue.shade600),
                label: Text(
                  'Chọn tất cả',
                  style: TextStyle(
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Actions
              Row(
                children: [
                  // Mark as read
                  IconButton(
                    icon: Icon(Icons.mark_email_read_rounded,
                               color: isDark ? Colors.green.shade300 : Colors.green.shade600),
                    onPressed: totalSelected > 0 
                        ? () => _markSelectedAsRead(context)
                        : null,
                    tooltip: 'Đánh dấu đã đọc',
                  ),
                  
                  // Delete (chỉ cho device alerts)
                  IconButton(
                    icon: Icon(Icons.delete_rounded,
                               color: isDark ? Colors.red.shade300 : Colors.red.shade600),
                    onPressed: totalSelected > 0
                        ? () => _deleteSelectedItems(context)
                        : null,
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 🎯 Floating Action Button cho chế độ chọn nhiều
  Widget _buildFloatingActionButton(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isSelectionMode = ref.watch(isSelectionModeProvider);
        final selectionController = ref.read(notificationSelectionControllerProvider.notifier);
        
        if (isSelectionMode) {
          return FloatingActionButton.extended(
            onPressed: selectionController.clearSelection,
            icon: Icon(Icons.clear_rounded),
            label: Text('Hủy chọn'),
            backgroundColor: _isDarkMode ? Color(0xFF64748B) : Color(0xFF94A3B8),
            foregroundColor: Colors.white,
            elevation: 4,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Các hàm loading, error, empty states
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Color(0xFF60A5FA) : Color(0xFF3B82F6)
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Đang tải...",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E293B) : Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 50,
              color: isDark ? Colors.red.shade400 : Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Không thể tải dữ liệu",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vui lòng kiểm tra kết nối internet",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E293B) : Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 60,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Không có thông báo",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tất cả thông báo và lời mời sẽ hiển thị tại đây",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E293B) : Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 50,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(UnifiedNotificationModel notification, BuildContext context) async {
    final notificationController = ref.read(unifiedNotificationControllerProvider);
    final currentContext = context;
    final messengerState = ScaffoldMessenger.of(currentContext);
    final deletedNotification = notification;
    
    await notificationController.deleteNotification(notification.id);
    
    final snackBar = SnackBar(
      content: Text('Đã xóa thông báo'),
      backgroundColor: _isDarkMode ? Color(0xFFDC2626) : Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Hoàn tác',
        textColor: Colors.white,
        onPressed: () async {
          await notificationController.restoreNotification(deletedNotification.id, deletedNotification);
        },
      ),
    );
    
    messengerState.showSnackBar(snackBar);
  }
}