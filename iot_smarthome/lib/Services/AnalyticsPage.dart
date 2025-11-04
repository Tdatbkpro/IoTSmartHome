import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:influxdb_client/api.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final RxBool _isLoading = true.obs;
  final RxString _selectedTimeRange = '24h'.obs;
  final RxString _selectedChartType = 'line'.obs;
  final RxString _selectedMetric = 'temperature'.obs;

  List<TimeSeriesData> temperatureData = [];
  List<TimeSeriesData> humidityData = [];
  List<DeviceUsageData> deviceUsageData = [];

  double avgTemperature = 0;
  double avgHumidity = 0;
  int activeDevices = 0;

  // THAY THẾ TOKEN Ở ĐÂY
  final String influxToken = 'xdy_Po2KolaV4AXkZqIYYUy-Z3-gXkdJDsLDhl90JmMIUywYDKl-WD3WQs2TXDTiQ_p8D3aFITKZaB5YNON3UA==';

  // Options cho dropdown
  final List<Map<String, dynamic>> timeRangeOptions = [
    {'value': '1h', 'label': '1 giờ'},
    {'value': '6h', 'label': '6 giờ'},
    {'value': '24h', 'label': '24 giờ'},
    {'value': '2d', 'label': '2 ngày'},
    {'value': '7d', 'label': '7 ngày'},
    {'value': '30d', 'label': '30 ngày'},
  ];

  final List<Map<String, dynamic>> chartTypeOptions = [
    {'value': 'line', 'label': 'Đường', 'icon': Icons.show_chart},
    {'value': 'area', 'label': 'Vùng', 'icon': Icons.area_chart},
    {'value': 'column', 'label': 'Cột', 'icon': Icons.bar_chart},
    {'value': 'spline', 'label': 'Cong', 'icon': Icons.timeline},
  ];

  final List<Map<String, dynamic>> metricOptions = [
    {'value': 'temperature', 'label': 'Nhiệt độ', 'icon': Icons.thermostat},
    {'value': 'humidity', 'label': 'Độ ẩm', 'icon': Icons.water_drop},
    {'value': 'both', 'label': 'Cả hai', 'icon': Icons.multiline_chart},
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (influxToken == 'your_actual_token_here') {
      _loadSampleDataFromImage();
      return;
    }

    try {
      _isLoading.value = true;
      
      final client = InfluxDBClient(
        url: 'https://us-east-1-1.aws.cloud2.influxdata.com',
        token: influxToken,
        org: 'IoTSmartHome',
        bucket: 'SensorData',
      );

      await _fetchEnvironmentData(client);
      _calculateStatistics();
      
    } catch (e) {
      print('❌ Lỗi fetch data: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải dữ liệu: ${e.toString().contains('401') ? 'Token không đúng' : e}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _fetchEnvironmentData(InfluxDBClient client) async {
    try {
      final query = '''
        from(bucket: "SensorData")
          |> range(start: -${_selectedTimeRange.value})
          |> filter(fn: (r) => r._measurement == "environment")
          |> filter(fn: (r) => r._field == "temperature" or r._field == "humidity")
          |> filter(fn: (r) => r.sensor_name == "dht" or r.sensor_name == "sensor_A" or r.sensor_name == "sensor_B")
      ''';

      final futureStream = client.getQueryService().query(query);
      final stream = await futureStream;
      final records = await _streamToList(stream);
      
      final tempData = <TimeSeriesData>[];
      final humidData = <TimeSeriesData>[];
      
      for (final record in records) {
        _processRecord(record, tempData, humidData);
      }
      
      setState(() {
        temperatureData = tempData;
        humidityData = humidData;
      });
      
    } catch (e) {
      print('❌ Lỗi fetch environment data: $e');
      rethrow;
    }
  }

  void _processRecord(FluxRecord record, List<TimeSeriesData> tempData, List<TimeSeriesData> humidData) {
    final time = record['_time'];
    final value = record['_value'];
    final field = record['_field']?.toString();

    if (time != null && value != null && field != null) {
      final dateTime = _parseDateTime(time);
      final doubleValue = _parseValue(value);

      if (doubleValue != null) {
        final timeSeriesData = TimeSeriesData(
          time: dateTime,
          value: doubleValue,
        );

        if (field == 'temperature') {
          tempData.add(timeSeriesData);
        } else if (field == 'humidity') {
          humidData.add(timeSeriesData);
        }
      }
    }
  }

  DateTime _parseDateTime(dynamic time) {
    if (time is DateTime) return time;
    if (time is String) return DateTime.parse(time);
    return DateTime.now();
  }

  double? _parseValue(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  Future<List<FluxRecord>> _streamToList(Stream<FluxRecord> stream) async {
    final records = <FluxRecord>[];
    try {
      await for (final record in stream) {
        records.add(record);
      }
    } catch (e) {
      print('❌ Lỗi đọc stream: $e');
    }
    return records;
  }

  void _calculateStatistics() {
    if (temperatureData.isNotEmpty) {
      avgTemperature = temperatureData.map((e) => e.value).reduce((a, b) => a + b) / temperatureData.length;
    }
    
    if (humidityData.isNotEmpty) {
      avgHumidity = humidityData.map((e) => e.value).reduce((a, b) => a + b) / humidityData.length;
    }
    
    activeDevices = 3;
  }

  void _loadSampleDataFromImage() {
    final now = DateTime.now();
    final random = Random();
    
    // Dữ liệu chính xác từ ảnh
    temperatureData = [
      TimeSeriesData(time: DateTime.parse('2025-10-23T15:10:56.161Z'), value: 26.4),
      TimeSeriesData(time: DateTime.parse('2025-10-23T15:10:56.184Z'), value: 26.5),
      TimeSeriesData(time: DateTime.parse('2025-10-23T15:11:06.516Z'), value: 26.4),
    ];
    
    humidityData = [
      TimeSeriesData(time: DateTime.parse('2025-10-23T15:10:56.161Z'), value: 64.0),
      TimeSeriesData(time: DateTime.parse('2025-10-23T15:10:56.184Z'), value: 64.0),
      TimeSeriesData(time: DateTime.parse('2025-10-23T15:11:06.516Z'), value: 64.0),
    ];
    
    // Thêm dữ liệu giả lập dựa trên khoảng thời gian được chọn
    final hours = _getHoursFromTimeRange(_selectedTimeRange.value);
    final dataPoints = hours ~/ 2;
    
    for (int i = 1; i <= dataPoints; i++) {
      final time = now.subtract(Duration(hours: i * 2));
      temperatureData.add(TimeSeriesData(
        time: time,
        value: 25.0 + random.nextDouble() * 3,
      ));
      humidityData.add(TimeSeriesData(
        time: time,
        value: 60.0 + random.nextDouble() * 15,
      ));
    }
    
    temperatureData.sort((a, b) => a.time.compareTo(b.time));
    humidityData.sort((a, b) => a.time.compareTo(b.time));
    
    deviceUsageData = [
      DeviceUsageData(deviceName: 'dht', usageCount: 150),
      DeviceUsageData(deviceName: 'sensor_A', usageCount: 120),
      DeviceUsageData(deviceName: 'sensor_B', usageCount: 80),
    ];
    
    _calculateStatistics();
    setState(() {});
  }

  int _getHoursFromTimeRange(String timeRange) {
    switch (timeRange) {
      case '1h': return 1;
      case '6h': return 6;
      case '24h': return 24;
      case '2d': return 48;
      case '7d': return 168;
      case '30d': return 720;
      default: return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Thống kê & Phân tích", 
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
            onPressed: _fetchData,
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: Obx(() => _isLoading.value
          ? _buildLoadingState(theme)
          : _buildContent(theme, colorScheme, isDark)),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (influxToken == 'your_actual_token_here')
            _buildTokenWarning(theme, colorScheme),
          
          _buildStatsHeader(theme, colorScheme),
          const SizedBox(height: 24),

          _buildFiltersSection(theme, colorScheme),
          const SizedBox(height: 24),

          if (temperatureData.isEmpty && humidityData.isEmpty)
            _buildNoDataState(theme, colorScheme)
          else
            Column(
              children: [
                _buildMainChart(theme, colorScheme, isDark),
                const SizedBox(height: 24),

                if (_selectedMetric.value == 'both')
                  _buildSecondaryCharts(theme, colorScheme, isDark),
                
                const SizedBox(height: 24),

                if (deviceUsageData.isNotEmpty)
                  _buildDeviceUsageChart(theme, colorScheme, isDark),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tùy chọn hiển thị',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 600;
                
                if (isWideScreen) {
                  return Row(
                    children: [
                      Expanded(child: _buildFilterDropdown(
                        'Khoảng thời gian',
                        timeRangeOptions,
                        _selectedTimeRange,
                        Icons.access_time,
                        theme,
                        colorScheme,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFilterDropdown(
                        'Loại biểu đồ',
                        chartTypeOptions,
                        _selectedChartType,
                        Icons.auto_graph,
                        theme,
                        colorScheme,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFilterDropdown(
                        'Chỉ số',
                        metricOptions,
                        _selectedMetric,
                        Icons.analytics,
                        theme,
                        colorScheme,
                      )),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildFilterDropdown(
                        'Khoảng thời gian',
                        timeRangeOptions,
                        _selectedTimeRange,
                        Icons.access_time,
                        theme,
                        colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildFilterDropdown(
                        'Loại biểu đồ',
                        chartTypeOptions,
                        _selectedChartType,
                        Icons.auto_graph,
                        theme,
                        colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildFilterDropdown(
                        'Chỉ số',
                        metricOptions,
                        _selectedMetric,
                        Icons.analytics,
                        theme,
                        colorScheme,
                      ),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: _fetchData,
                  icon: Icon(Icons.refresh_rounded, size: 16, color: colorScheme.onPrimary),
                  label: Text('Áp dụng', style: TextStyle(color: colorScheme.onPrimary)),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String title,
    List<Map<String, dynamic>> options,
    RxString selectedValue,
    IconData icon,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          ),
          child: Obx(() => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue.value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
              dropdownColor: colorScheme.surface,
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'] as String,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        if (option['icon'] != null)
                          Icon(
                            option['icon'] as IconData,
                            size: 16,
                            color: colorScheme.onSurface,
                          ),
                        if (option['icon'] != null) const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            option['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  selectedValue.value = newValue;
                }
              },
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildTokenWarning(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang sử dụng dữ liệu mẫu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                Text(
                  'Thay token để kết nối dữ liệu thật',
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có dữ liệu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadSampleDataFromImage,
            icon: Icon(Icons.image_rounded, color: colorScheme.onPrimary),
            label: Text('Tải dữ liệu mẫu', style: TextStyle(color: colorScheme.onPrimary)),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;
              
              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('🌡️', 'Nhiệt độ TB', '${avgTemperature.toStringAsFixed(1)}°C', Colors.orange, colorScheme),
                    _buildStatItem('💧', 'Độ ẩm TB', '${avgHumidity.toStringAsFixed(1)}%', Colors.blue, colorScheme),
                    _buildStatItem('📊', 'Tổng điểm DL', '${temperatureData.length + humidityData.length}', Colors.green, colorScheme),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('🌡️', 'Nhiệt độ', '${avgTemperature.toStringAsFixed(1)}°C', Colors.orange, colorScheme),
                        _buildStatItem('💧', 'Độ ẩm', '${avgHumidity.toStringAsFixed(1)}%', Colors.blue, colorScheme),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem('📊', 'Tổng điểm DL', '${temperatureData.length + humidityData.length}', Colors.green, colorScheme),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Khoảng thời gian: ${_getTimeRangeLabel(_selectedTimeRange.value)}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeRangeLabel(String value) {
    final option = timeRangeOptions.firstWhere(
      (option) => option['value'] == value,
      orElse: () => {'label': '24 giờ'},
    );
    return option['label'] as String;
  }

  Widget _buildStatItem(String emoji, String title, String value, Color color, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainChart(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final showTemperature = _selectedMetric.value == 'temperature' || _selectedMetric.value == 'both';
    final showHumidity = _selectedMetric.value == 'humidity' || _selectedMetric.value == 'both';

    return Card(
      elevation: 2,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getMainChartTitle(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                plotAreaBackgroundColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                primaryXAxis: DateTimeAxis(
                  dateFormat: _getDateFormat(),
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: AxisLine(width: 1, color: colorScheme.outline.withOpacity(0.3)),
                  labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                ),
                primaryYAxis: NumericAxis(
                  labelFormat: _getYAxisFormat(),
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: AxisLine(width: 1, color: colorScheme.outline.withOpacity(0.3)),
                  labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                ),
                legend: Legend(
                  isVisible: showTemperature && showHumidity,
                  position: LegendPosition.top,
                  textStyle: TextStyle(color: colorScheme.onSurface),
                ),
                series: _getChartSeries(showTemperature, showHumidity, isDark),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  color: colorScheme.surfaceContainerHighest,
                  textStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMainChartTitle() {
    switch (_selectedMetric.value) {
      case 'temperature':
        return 'Biểu đồ nhiệt độ';
      case 'humidity':
        return 'Biểu đồ độ ẩm';
      case 'both':
        return 'Biểu đồ nhiệt độ & độ ẩm';
      default:
        return 'Biểu đồ thống kê';
    }
  }

  DateFormat _getDateFormat() {
    switch (_selectedTimeRange.value) {
      case '1h':
      case '6h':
        return DateFormat.Hm();
      case '24h':
        return DateFormat.Md().add_Hm();
      case '2d':
        return DateFormat.Md();
      case '7d':
      case '30d':
        return DateFormat.Md();
      default:
        return DateFormat.Md().add_Hm();
    }
  }

  String _getYAxisFormat() {
    switch (_selectedMetric.value) {
      case 'temperature':
        return '{value}°C';
      case 'humidity':
        return '{value}%';
      case 'both':
        return '{value}';
      default:
        return '{value}';
    }
  }

  List<CartesianSeries<TimeSeriesData, DateTime>> _getChartSeries(bool showTemp, bool showHumid, bool isDark) {
    final series = <CartesianSeries<TimeSeriesData, DateTime>>[];

    if (showTemp && temperatureData.isNotEmpty) {
      series.add(_createSeries(
        data: temperatureData,
        name: 'Nhiệt độ',
        color: isDark ? Colors.orange.shade300 : Colors.orange,
        isDark: isDark,
      ));
    }

    if (showHumid && humidityData.isNotEmpty) {
      series.add(_createSeries(
        data: humidityData,
        name: 'Độ ẩm',
        color: isDark ? Colors.blue.shade300 : Colors.blue,
        isDark: isDark,
      ));
    }

    return series;
  }

  CartesianSeries<TimeSeriesData, DateTime> _createSeries({
    required List<TimeSeriesData> data,
    required String name,
    required Color color,
    required bool isDark,
  }) {
    switch (_selectedChartType.value) {
      case 'line':
        return LineSeries<TimeSeriesData, DateTime>(
          dataSource: data,
          xValueMapper: (data, _) => data.time,
          yValueMapper: (data, _) => data.value,
          name: name,
          color: color,
          width: 2,
          markerSettings: MarkerSettings(
            isVisible: true, 
            height: 4, 
            width: 4,
            color: color,
            borderWidth: 0,
          ),
        );
      case 'area':
        return AreaSeries<TimeSeriesData, DateTime>(
          dataSource: data,
          xValueMapper: (data, _) => data.time,
          yValueMapper: (data, _) => data.value,
          name: name,
          color: color.withOpacity(0.3),
          borderColor: color,
          borderWidth: 2,
        );
      case 'column':
        return ColumnSeries<TimeSeriesData, DateTime>(
          dataSource: data,
          xValueMapper: (data, _) => data.time,
          yValueMapper: (data, _) => data.value,
          name: name,
          color: color,
          width: 0.8,
          spacing: 0.2,
        );
      case 'spline':
        return SplineSeries<TimeSeriesData, DateTime>(
          dataSource: data,
          xValueMapper: (data, _) => data.time,
          yValueMapper: (data, _) => data.value,
          name: name,
          color: color,
          width: 2,
          markerSettings: MarkerSettings(
            isVisible: true, 
            height: 4, 
            width: 4,
            color: color,
            borderWidth: 0,
          ),
        );
      default:
        return LineSeries<TimeSeriesData, DateTime>(
          dataSource: data,
          xValueMapper: (data, _) => data.time,
          yValueMapper: (data, _) => data.value,
          name: name,
          color: color,
          width: 2,
          markerSettings: const MarkerSettings(isVisible: true),
        );
    }
  }

  Widget _buildSecondaryCharts(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        if (isWide) {
          return Row(
            children: [
              if (temperatureData.isNotEmpty)
                Expanded(child: _buildMiniChart(
                  title: 'Nhiệt độ',
                  data: temperatureData,
                  color: isDark ? Colors.orange.shade300 : Colors.orange,
                  unit: '°C',
                  colorScheme: colorScheme,
                )),
              if (temperatureData.isNotEmpty && humidityData.isNotEmpty)
                const SizedBox(width: 12),
              if (humidityData.isNotEmpty)
                Expanded(child: _buildMiniChart(
                  title: 'Độ ẩm',
                  data: humidityData,
                  color: isDark ? Colors.blue.shade300 : Colors.blue,
                  unit: '%',
                  colorScheme: colorScheme,
                )),
            ],
          );
        } else {
          return Column(
            children: [
              if (temperatureData.isNotEmpty)
                _buildMiniChart(
                  title: 'Nhiệt độ',
                  data: temperatureData,
                  color: isDark ? Colors.orange.shade300 : Colors.orange,
                  unit: '°C',
                  colorScheme: colorScheme,
                ),
              if (temperatureData.isNotEmpty && humidityData.isNotEmpty)
                const SizedBox(height: 12),
              if (humidityData.isNotEmpty)
                _buildMiniChart(
                  title: 'Độ ẩm',
                  data: humidityData,
                  color: isDark ? Colors.blue.shade300 : Colors.blue,
                  unit: '%',
                  colorScheme: colorScheme,
                ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMiniChart({
    required String title,
    required List<TimeSeriesData> data,
    required Color color,
    required String unit,
    required ColorScheme colorScheme,
  }) {
    return Card(
      elevation: 1,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: SfCartesianChart(
                plotAreaBackgroundColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                margin: EdgeInsets.zero,
                primaryXAxis: DateTimeAxis(isVisible: false),
                primaryYAxis: NumericAxis(isVisible: false),
                series: <CartesianSeries>[
                  AreaSeries<TimeSeriesData, DateTime>(
                    dataSource: data,
                    xValueMapper: (data, _) => data.time,
                    yValueMapper: (data, _) => data.value,
                    color: color.withOpacity(0.2),
                    borderColor: color,
                    borderWidth: 1,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceUsageChart(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Card(
      elevation: 2,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê sử dụng thiết bị',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                backgroundColor: Colors.transparent,
                series: <CircularSeries>[
                  DoughnutSeries<DeviceUsageData, String>(
                    dataSource: deviceUsageData,
                    xValueMapper: (data, _) => data.deviceName,
                    yValueMapper: (data, _) => data.usageCount,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(color: colorScheme.onSurface),
                    ),
                    enableTooltip: true,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeSeriesData {
  final DateTime time;
  final double value;

  TimeSeriesData({required this.time, required this.value});
}

class DeviceUsageData {
  final String deviceName;
  final int usageCount;

  DeviceUsageData({required this.deviceName, required this.usageCount});
}