// providers/notification_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:iot_smarthome/Controllers/UnifiedNotificationController.dart';
import 'package:iot_smarthome/Models/UnifiedNotificationModel.dart';

// Controller Providers
final unifiedNotificationControllerProvider = Provider<UnifiedNotificationController>((ref) {
  return UnifiedNotificationController();
});

// Stream Providers
final notificationsStreamProvider = StreamProvider<List<UnifiedNotificationModel>>((ref) {
  final controller = ref.watch(unifiedNotificationControllerProvider);
  return controller.getNotificationStream();
});

final deviceAlertsStreamProvider = StreamProvider<List<UnifiedNotificationModel>>((ref) {
  final controller = ref.watch(unifiedNotificationControllerProvider);
  return controller.getDeviceAlertsStream();
});

final invitationsStreamProvider = StreamProvider<List<UnifiedNotificationModel>>((ref) {
  final controller = ref.watch(unifiedNotificationControllerProvider);
  return controller.getInvitationsStream();
});

// Selection Controller State
class NotificationSelectionState {
  final Set<String> selectedNotifications;
  final bool isSelectionMode;
  final int currentTab;

  NotificationSelectionState({
    required this.selectedNotifications,
    required this.isSelectionMode,
    required this.currentTab,
  });

  NotificationSelectionState copyWith({
    Set<String>? selectedNotifications,
    bool? isSelectionMode,
    int? currentTab,
  }) {
    return NotificationSelectionState(
      selectedNotifications: selectedNotifications ?? this.selectedNotifications,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      currentTab: currentTab ?? this.currentTab,
    );
  }
}

// Selection Controller
class NotificationSelectionController extends StateNotifier<NotificationSelectionState> {
  NotificationSelectionController() : super(NotificationSelectionState(
    selectedNotifications: {},
    isSelectionMode: false,
    currentTab: 0,
  ));

  void toggleNotificationSelection(String notificationId) {
    final newSelected = Set<String>.from(state.selectedNotifications);
    if (newSelected.contains(notificationId)) {
      newSelected.remove(notificationId);
    } else {
      newSelected.add(notificationId);
    }
    state = state.copyWith(
      selectedNotifications: newSelected,
      isSelectionMode: newSelected.isNotEmpty,
    );
  }

  void selectAllNotifications(List<UnifiedNotificationModel> notifications) {
    final newSelected = Set<String>.from(notifications.map((n) => n.id));
    state = state.copyWith(
      selectedNotifications: newSelected,
      isSelectionMode: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedNotifications: {},
      isSelectionMode: false,
    );
  }

  void setCurrentTab(int tabIndex) {
    state = state.copyWith(
      currentTab: tabIndex,
      selectedNotifications: {},
      isSelectionMode: false,
    );
  }

  bool isNotificationSelected(String notificationId) {
    return state.selectedNotifications.contains(notificationId);
  }

  int get totalSelectedCount => state.selectedNotifications.length;
}

// Selection Providers
final notificationSelectionControllerProvider = StateNotifierProvider<NotificationSelectionController, NotificationSelectionState>((ref) {
  return NotificationSelectionController();
});

final selectedNotificationsProvider = Provider<Set<String>>((ref) {
  return ref.watch(notificationSelectionControllerProvider.select((state) => state.selectedNotifications));
});

final isSelectionModeProvider = Provider<bool>((ref) {
  return ref.watch(notificationSelectionControllerProvider.select((state) => state.isSelectionMode));
});

final currentTabProvider = Provider<int>((ref) {
  return ref.watch(notificationSelectionControllerProvider.select((state) => state.currentTab));
});

final totalSelectedCountProvider = Provider<int>((ref) {
  return ref.watch(selectedNotificationsProvider).length;
});