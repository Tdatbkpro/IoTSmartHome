import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iot_smarthome/Config/Images.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  // Fallback values nếu không lấy được package info
  String _appName = 'IoT Smarthome';
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      // Thử sử dụng package_info_plus, nếu lỗi thì dùng fallback values
      // final info = await PackageInfo.fromPlatform();
      // setState(() {
      //   _appName = info.appName;
      //   _version = info.version;
      //   _buildNumber = info.buildNumber;
      // });
    } catch (e) {
      print('Error getting package info: $e');
      // Sử dụng giá trị mặc định
      setState(() {
        _appName = 'IoT Smarthome';
        _version = '1.0.0';
        _buildNumber = '1';
      });
    }
  }
  // Thêm các URL schemes khác nhau cho Facebook
void _openFacebook() async {
  final urls = [
    'fb://profile/1000000000', // Thay bằng Facebook ID thực tế
    'fb://page/DatManucian2206',
    'https://www.facebook.com/DatManucian2206',
    'https://m.facebook.com/DatManucian2206', // Mobile version
  ];

  for (final url in urls) {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return; // Thoát nếu thành công
      }
    } catch (e) {
      print('Failed to launch: $url - $e');
      continue; // Thử URL tiếp theo
    }
  }
  
  // Nếu tất cả đều thất bại
  Get.snackbar(
    'Thông báo',
    'Không thể mở Facebook. Vui lòng cài đặt ứng dụng Facebook.',
    snackPosition: SnackPosition.BOTTOM,
  );
}
  Future<void> _launchURL(String url) async {
  try {
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault, // Thay đổi thành platformDefault
      );
    } else {
      // Fallback: Thử mở trong trình duyệt web
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView, // Hoặc externalApplication
      );
    }
  } catch (e) {
    print('Error launching URL: $e');
    // Hiển thị thông báo lỗi chi tiết hơn
    Get.snackbar(
      'Không thể mở liên kết',
      'URL: $url\nLỗi: $e',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}


  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giấy phép và Điều khoản'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Điều khoản sử dụng ứng dụng IoT Smarthome',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Get.theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildTermItem('📱', 'Ứng dụng miễn phí sử dụng'),
              _buildTermItem('🏠', 'Dành cho mục đích điều khiển nhà thông minh'),
              _buildTermItem('🔒', 'Cam kết bảo mật dữ liệu người dùng'),
              _buildTermItem('⚖️', 'Tuân thủ các quy định về bảo mật và riêng tư'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chính sách bảo mật'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chúng tôi cam kết bảo vệ quyền riêng tư của bạn.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Get.theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildPolicyItem('📊', 'Thu thập dữ liệu sử dụng để cải thiện ứng dụng'),
              _buildPolicyItem('🔒', 'Mã hóa dữ liệu nhạy cảm'),
              _buildPolicyItem('👥', 'Không chia sẻ thông tin cá nhân với bên thứ ba'),
              _buildPolicyItem('🏠', 'Dữ liệu nhà thông minh được lưu trữ an toàn'),
              _buildPolicyItem('📝', 'Quyền truy cập và xóa dữ liệu cá nhân'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title:  Text(
          "Về ứng dụng",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface
            ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(theme),
            const SizedBox(height: 32),

            // App Info Section
            _buildAppInfoSection(theme),
            const SizedBox(height: 24),

            // Features Section
            _buildFeaturesSection(theme),
            const SizedBox(height: 24),

            // Team & Contact Section
            _buildTeamContactSection(theme),
            const SizedBox(height: 24),

            // Legal Section
            _buildLegalSection(theme),
            const SizedBox(height: 32),

            // Copyright
            _buildCopyrightSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                AssetImages.logoApp
              ),
            )
          ),
          const SizedBox(height: 16),
          Text(
            _appName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Smart Home Automation',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Biến ngôi nhà của bạn thành ngôi nhà thông minh với công nghệ tiên tiến nhất',
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

  Widget _buildAppInfoSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Thông tin ứng dụng",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(theme, 'Phiên bản', '$_version (Build $_buildNumber)'),
            _buildInfoItem(theme, 'Ngày phát hành', '15/09/2025'),
            _buildInfoItem(theme, 'Nhà phát triển', 'Dat'),
            _buildInfoItem(theme, 'Hệ điều hành', 'Android'),
            _buildInfoItem(theme, 'Loại ứng dụng', 'Điều khiển nhà thông minh'),
          ],
        ),

      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(ThemeData theme) {
    final features = [
      _FeatureItem('🏠', 'Điều khiển nhà thông minh', 'Điều khiển mọi thiết bị từ xa'),
      _FeatureItem('🎙️', 'Trợ lý giọng nói', 'Điều khiển bằng giọng nói tiếng Việt'),
      _FeatureItem('⏰', 'Lập lịch tự động', 'Hẹn giờ bật/tắt thiết bị thông minh'),
      _FeatureItem('🔒', 'Bảo mật nâng cao', 'Mã hóa dữ liệu và xác thực đa yếu tố'),
      _FeatureItem('📊', 'Theo dõi tiêu thụ', 'Giám sát năng lượng theo thời gian thực'),
      _FeatureItem('👥', 'Chia sẻ thiết bị', 'Chia sẻ quyền điều khiển với gia đình'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Tính năng nổi bật",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature.title,
                          
                          style: TextStyle(
                            fontSize: 13,
                            
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamContactSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Liên hệ & Hỗ trợ",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              theme,
              Icons.email_rounded,
              'Email hỗ trợ',
              'datbkpro225280@gmail.com',
              () => _launchURL('mailto:datbkpro225280@gmail.com'),
            ),
            _buildContactItem(
              theme,
              Icons.facebook,
              'Facebook',
              'Đạt',
              () => _launchURL('https://www.facebook.com/DatManucian2206'),
            ),
            _buildContactItem(
              theme,
              Icons.help_center_rounded,
              'Trung tâm trợ giúp',
              'Hướng dẫn sử dụng và FAQ',
              () => _launchURL('https://help.iotsmarthome.com'),
            ),
            _buildContactItem(
              theme,
              Icons.bug_report_rounded,
              'Báo lỗi & Góp ý',
              'Giúp chúng tôi cải thiện ứng dụng',
              () => Get.toNamed('/feedBack'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLegalSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gavel_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Thông tin pháp lý",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLegalItem(
              theme,
              'Điều khoản sử dụng',
              _showLicenseDialog,
            ),
            _buildLegalItem(
              theme,
              'Chính sách bảo mật',
              _showPrivacyPolicy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem(ThemeData theme, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.description_rounded, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCopyrightSection(ThemeData theme) {
    return Column(
      children: [
        Text(
          '© 2025 IoT Smarthome. All rights reserved.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Made with ❤️ for smart home enthusiasts',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final String emoji;
  final String title;
  final String description;

  _FeatureItem(this.emoji, this.title, this.description);
}