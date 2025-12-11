import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iot_smarthome/Models/DeviceStatusModel.dart';
import 'package:iot_smarthome/Models/RoomModel.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EnergyConsumptionPage extends StatefulWidget {
  final RoomModel room;
  final List<Device> devices;
  final Map<String, DeviceStatus> deviceStatusMap;

  const EnergyConsumptionPage({
    Key? key,
    required this.room,
    required this.devices,
    required this.deviceStatusMap,
  }) : super(key: key);

  @override
  State<EnergyConsumptionPage> createState() => _EnergyConsumptionPageState();
}

class _EnergyConsumptionPageState extends State<EnergyConsumptionPage> {
  final TextEditingController _priceController = TextEditingController(text: '3000');
  double _electricityPrice = 3000;
  final List<EnergyData> _energyData = [];
  ChartType _selectedChartType = ChartType.bar;
  DateTime _selectedMonth = DateTime.now(); // 🆕 Tháng được chọn
  ViewType _selectedView = ViewType.monthly; // 🆕 Loại view

  @override
  void initState() {
    super.initState();
    _calculateEnergyData();
  }

  // 🆕 TÍNH TOÁN DỮ LIỆU THEO THÁNG
  void _calculateEnergyData() {
    _energyData.clear();
    
    if (_selectedView == ViewType.monthly) {
      _calculateMonthlyData();
    } else {
      _calculateDailyData();
    }
  }

  // 🆕 TÍNH DỮ LIỆU THEO THÁNG (30 ngày gần nhất)
  void _calculateMonthlyData() {
    final now = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dailyConsumption = _calculateDailyRealConsumption(date);
      
      _energyData.add(EnergyData(
        date: date,
        consumption: dailyConsumption,
        cost: dailyConsumption * _electricityPrice,
      ));
    }
  }

  // 🆕 TÍNH DỮ LIỆU THEO NGÀY (trong tháng được chọn)
  void _calculateDailyData() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final dailyConsumption = _calculateDailyRealConsumption(date);
      
      _energyData.add(EnergyData(
        date: date,
        consumption: dailyConsumption,
        cost: dailyConsumption * _electricityPrice,
      ));
    }
  }

  // 🆕 TÍNH TIÊU THỤ THỰC TẾ THEO NGÀY
  double _calculateDailyRealConsumption(DateTime date) {
    double totalConsumption = 0;
    
    for (var device in widget.devices) {
      final deviceStatus = widget.deviceStatusMap[device.id];
      if (deviceStatus != null && device.power != null) {
        final energy = deviceStatus.calculateDailyEnergyConsumption(
          device.power!, 
          date
        );
        totalConsumption += energy;
      }
    }
    
    return totalConsumption;
  }

  // 🆕 TÍNH TỔNG TIÊU THỤ THÁNG NÀY
  double get _currentMonthConsumption {
    double total = 0;
    final currentMonth = DateTime.now();
    
    for (var device in widget.devices) {
      final deviceStatus = widget.deviceStatusMap[device.id];
      if (deviceStatus != null && device.power != null) {
        final energy = deviceStatus.calculateMonthlyEnergyConsumption(
          device.power!, 
          currentMonth
        );
        total += energy;
      }
    }
    
    return total;
  }

  // 🆕 TÍNH TỔNG CHI PHÍ THÁNG NÀY
  double get _currentMonthCost {
    return _currentMonthConsumption * _electricityPrice;
  }

  // 🆕 TÍNH CHI PHÍ THỰC TẾ CHO TỪNG THIẾT BỊ TRONG THÁNG
  double _calculateDeviceMonthlyCost(Device device) {
    final deviceStatus = widget.deviceStatusMap[device.id];
    if (deviceStatus != null && device.power != null) {
      final consumption = deviceStatus.calculateMonthlyEnergyConsumption(
        device.power!, 
        DateTime.now()
      );
      return consumption * _electricityPrice;
    }
    return 0;
  }

  void _updatePrice() {
    final price = double.tryParse(_priceController.text);
    if (price != null && price > 0) {
      setState(() {
        _electricityPrice = price;
        _calculateEnergyData();
      });
    }
  }

  void _refreshData() {
    setState(() {
      _calculateEnergyData();
    });
  }

  // 🆕 CHUYỂN ĐỔI GIỮA XEM THEO THÁNG VÀ THEO NGÀY
  void _changeView(ViewType newView) {
    setState(() {
      _selectedView = newView;
      _calculateEnergyData();
    });
  }

  // 🆕 THAY ĐỔI THÁNG
  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _calculateEnergyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final double monthConsumption = _currentMonthConsumption;
    final double monthCost = _currentMonthCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê Điện Năng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Cập nhật dữ liệu',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomHeader(isSmallScreen),
            const SizedBox(height: 20),
            _buildMonthlyOverview(monthConsumption, monthCost, isSmallScreen),
            const SizedBox(height: 20),
            _buildViewSelector(isSmallScreen),
            const SizedBox(height: 20),
            _buildPriceSettings(isSmallScreen),
            const SizedBox(height: 20),
            _buildChartSection(isSmallScreen),
            const SizedBox(height: 20),
            _buildDeviceList(isSmallScreen),
          ],
        ),
      ),
    );
  }

  // 🆕 OVERVIEW THEO THÁNG
  Widget _buildMonthlyOverview(double consumption, double cost, bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tháng ${DateTime.now().month}/${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                Text(
                  'Tính đến: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Điện tiêu thụ',
                    '${consumption.toStringAsFixed(2)} kWh',
                    Icons.bolt,
                    Colors.orange.shade100,
                    Colors.orange,
                    isSmallScreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Thành tiền',
                    '${NumberFormat('#,###').format(cost.round())} VND',
                    Icons.attach_money,
                    Colors.green.shade100,
                    Colors.green,
                    isSmallScreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '📊 Dựa trên thời gian sử dụng thực tế theo ngày',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 SELECTOR CHỌN LOẠI VIEW
  Widget _buildViewSelector(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chế Độ Xem',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildViewTypeButton(
                    'Theo Tháng',
                    ViewType.monthly,
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildViewTypeButton(
                    'Theo Ngày',
                    ViewType.daily,
                    Icons.bar_chart,
                  ),
                ),
              ],
            ),
            if (_selectedView == ViewType.daily) ...[
              const SizedBox(height: 16),
              _buildMonthSelector(isSmallScreen),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewTypeButton(String text, ViewType viewType, IconData icon) {
    return ElevatedButton(
      onPressed: () => _changeView(viewType),
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedView == viewType 
            ? Colors.deepPurple 
            : Colors.grey.shade300,
        foregroundColor: _selectedView == viewType 
            ? Colors.white 
            : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 🆕 SELECTOR CHỌN THÁNG
  Widget _buildMonthSelector(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  // 🆕 CẬP NHẬT PHẦN CHART
  Widget _buildChartSection(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedView == ViewType.monthly 
                      ? 'Biểu Đồ 30 Ngày Gần Nhất'
                      : 'Biểu Đồ Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                DropdownButton<ChartType>(
                  value: _selectedChartType,
                  onChanged: (type) {
                    setState(() {
                      _selectedChartType = type!;
                    });
                  },
                  items: ChartType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type == ChartType.bar ? 'Biểu đồ cột' : 'Biểu đồ đường',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 250 : 300,
              child: SfCartesianChart(
                margin: EdgeInsets.zero,
                primaryXAxis: DateTimeAxis(
                  dateFormat: _selectedView == ViewType.monthly 
                      ? DateFormat('dd/MM')
                      : DateFormat('dd'),
                  interval: _selectedView == ViewType.monthly ? 5 : 1,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compact(),
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                series: <CartesianSeries<EnergyData, DateTime>>[
                  if (_selectedChartType == ChartType.bar)
                    ColumnSeries<EnergyData, DateTime>(
                      dataSource: _energyData,
                      xValueMapper: (EnergyData data, _) => data.date,
                      yValueMapper: (EnergyData data, _) => data.consumption,
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(4),
                    )
                  else
                    LineSeries<EnergyData, DateTime>(
                      dataSource: _energyData,
                      xValueMapper: (EnergyData data, _) => data.date,
                      yValueMapper: (EnergyData data, _) => data.consumption,
                      color: Colors.deepPurple,
                      markerSettings: const MarkerSettings(isVisible: true),
                    ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'Ngày: point.x\nTiêu thụ: point.y kWh',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 CẬP NHẬT DEVICE LIST HIỂN THỊ THEO THÁNG
  Widget _buildDeviceList(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thiết Bị Trong Phòng (Tháng ${DateTime.now().month})',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.devices.map((device) => _buildDeviceItem(device, isSmallScreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(Device device, bool isSmallScreen) {
    final deviceStatus = widget.deviceStatusMap[device.id];
    final monthlyConsumption = deviceStatus?.calculateMonthlyEnergyConsumption(
      device.power ?? 0, 
      DateTime.now()
    ) ?? 0;
    final monthlyCost = _calculateDeviceMonthlyCost(device);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 40 : 48,
            height: isSmallScreen ? 40 : 48,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getDeviceIcon(device.type),
              size: isSmallScreen ? 20 : 24,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name ?? 'Unknown',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.power?.toStringAsFixed(0) ?? '0'}W • '
                  '${monthlyConsumption.toStringAsFixed(2)} kWh',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat('#,###').format(monthlyCost.round())} VND',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
              Text(
                'tháng này',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Các phương thức khác giữ nguyên...
  Widget _buildRoomHeader(bool isSmallScreen) {
    // Giữ nguyên như cũ
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 50 : 60,
              height: isSmallScreen ? 50 : 60,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.energy_savings_leaf,
                color: Colors.white,
                size: isSmallScreen ? 24 : 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.devices.length} thiết bị điện • '
                    'Tháng ${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSettings(bool isSmallScreen) {
    // Giữ nguyên như cũ
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài Đặt Đơn Giá',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Đơn giá (VND/kWh)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixText: 'VND',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _updatePrice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cập nhật',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
    bool isSmallScreen,
  ) {
    // Giữ nguyên như cũ
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 32 : 36,
                height: isSmallScreen ? 32 : 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: isSmallScreen ? 16 : 18, color: iconColor),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'light':
        return Icons.lightbulb;
      case 'fan':
        return Icons.air;
      case 'tv':
        return Icons.tv;
      case 'speaker':
        return Icons.speaker;
      default:
        return Icons.devices;
    }
  }
}

// 🆕 THÊM ENUM CHO LOẠI VIEW
enum ViewType { monthly, daily }

class EnergyData {
  final DateTime date;
  final double consumption;
  final double cost;

  EnergyData({
    required this.date,
    required this.consumption,
    required this.cost,
  });
}

enum ChartType { bar, line }