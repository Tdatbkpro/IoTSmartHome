import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final RxString _selectedType = 'Báo lỗi'.obs;
  final RxString _selectedPriority = 'Trung bình'.obs;
  final RxBool _isSubmitting = false.obs;
  final RxBool _hasEmailPermission = false.obs;

  final List<String> _feedbackTypes = [
    'Báo lỗi',
    'Góp ý tính năng',
    'Đề xuất cải tiến',
    'Vấn đề kỹ thuật',
    'Khác'
  ];

  final List<String> _priorityLevels = [
    'Thấp',
    'Trung bình',
    'Cao',
    'Khẩn cấp'
  ];

  @override
  void initState() {
    super.initState();
    _emailController.text = 'datbkpro225280@gmail.com';
    _checkEmailPermission();
  }

  // Kiểm tra quyền truy cập email
  Future<void> _checkEmailPermission() async {
    try {
      final status = await Permission.contacts.status;
      _hasEmailPermission.value = status.isGranted;
    } catch (e) {
      print("Error checking permission: $e");
    }
  }

  // Xin quyền truy cập email
  Future<void> _requestEmailPermission() async {
    try {
      final status = await Permission.contacts.request();
      
      if (status.isGranted) {
        _hasEmailPermission.value = true;
        Get.snackbar(
          'Thành công',
          'Đã cấp quyền truy cập email',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else if (status.isDenied) {
        Get.snackbar(
          'Thông báo',
          'Quyền truy cập email bị từ chối',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog();
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xin quyền: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Hiển thị dialog hướng dẫn cấp quyền thủ công
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền truy cập bị từ chối'),
        content: const Text(
          'Ứng dụng cần quyền truy cập email để gửi phản hồi. '
          'Vui lòng cấp quyền trong phần Cài đặt ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_hasEmailPermission.value) {
      await _requestEmailPermission();
      return;
    }

    if (_formKey.currentState!.validate()) {
      _isSubmitting.value = true;

      try {
        final subject = Uri.encodeComponent('[$_selectedType - $_selectedPriority] ${_titleController.text}');
        final body = Uri.encodeComponent('''
          Loại: ${_selectedType.value}
          Mức độ ưu tiên: ${_selectedPriority.value}
          Email phản hồi: ${_emailController.text}

          Nội dung:
          ${_descriptionController.text}

          ---
          Gửi từ ứng dụng IoT Smarthome
          ${DateTime.now()}
          ''');

        final uri = Uri.parse('mailto:datbkpro225280@gmail.com?subject=$subject&body=$body');

        bool canLaunchMail = false;
        try {
          canLaunchMail = await canLaunchUrl(uri);
        } catch (e) {
          debugPrint("Lỗi khi kiểm tra canLaunchUrl: $e");
        }

        if (canLaunchMail) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar(
            'Không thể mở email',
            'Thiết bị không có ứng dụng email mặc định (Gmail, Outlook, v.v.)',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể gửi phản hồi: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        _isSubmitting.value = false;
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _selectedType.value = 'Báo lỗi';
    _selectedPriority.value = 'Trung bình';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Phản hồi & Góp ý",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeaderSection(theme),
              const SizedBox(height: 24),

              // Permission Warning
              Obx(() => _hasEmailPermission.value 
                  ? const SizedBox()
                  : _buildPermissionWarning(theme)
              ),
              const SizedBox(height: 16),

              // Feedback Type & Priority
              _buildSelectionSection(theme),
              const SizedBox(height: 20),

              // Title
              _buildTitleField(theme),
              const SizedBox(height: 16),

              // Description
              _buildDescriptionField(theme),
              const SizedBox(height: 16),

              // Email
              _buildEmailField(theme),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.feedback_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            "Chúng tôi lắng nghe ý kiến của bạn",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Mọi phản hồi của bạn sẽ giúp chúng tôi cải thiện ứng dụng tốt hơn",
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarning(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cần cấp quyền truy cập",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Ứng dụng cần quyền truy cập email để gửi phản hồi",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _requestEmailPermission,
            child: Text(
              "Cấp quyền",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Loại phản hồi",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType.value,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down_rounded, 
                        color: theme.colorScheme.primary),
                    items: _feedbackTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _selectedType.value = newValue;
                      }
                    },
                  ),
                ),
              )),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Mức độ ưu tiên",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPriority.value,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down_rounded, 
                        color: theme.colorScheme.primary),
                    items: _priorityLevels.map((String value) {
                      Color? color;
                      if (value == 'Khẩn cấp') color = Colors.red;
                      if (value == 'Cao') color = Colors.orange;
                      if (value == 'Trung bình') color = Colors.blue;
                      if (value == 'Thấp') color = Colors.green;

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: TextStyle(color: theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _selectedPriority.value = newValue;
                      }
                    },
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tiêu đề *",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: "Nhập tiêu đề phản hồi...",
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Vui lòng nhập tiêu đề";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mô tả chi tiết *",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: "Mô tả chi tiết vấn đề hoặc góp ý của bạn...",
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Vui lòng nhập mô tả chi tiết";
            }
            if (value.length < 10) {
              return "Vui lòng mô tả chi tiết hơn (ít nhất 10 ký tự)";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email nhận phản hồi",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: "Nhập email để nhận phản hồi...",
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Icon(Icons.email_rounded, color: theme.colorScheme.primary),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Vui lòng nhập email";
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return "Email không hợp lệ";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        Obx(() => _hasEmailPermission.value 
            ? const SizedBox()
            : Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Vui lòng cấp quyền truy cập email để gửi phản hồi",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              )
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
                child: Text(
                  "Đặt lại",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(() => ElevatedButton(
                onPressed: _isSubmitting.value ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasEmailPermission.value 
                      ? theme.colorScheme.primary
                      : Colors.grey,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Gửi phản hồi",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              )),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}