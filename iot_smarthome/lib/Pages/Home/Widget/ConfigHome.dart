import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iot_smarthome/Controllers/DeviceController.dart';
import 'package:iot_smarthome/Models/HomeModel.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:iot_smarthome/Controllers/PickImageController.dart';
import 'package:uuid/uuid.dart';

class AddHomePage {
  final bool isAddHome;
  final HomeModel? homeModel;
  
  AddHomePage({
    this.isAddHome = true, 
    this.homeModel
  });

  final PickImageController pickImageController = Get.put(PickImageController());
  
  String _formatVietnameseAddress(Placemark placemark) {
    List<String> components = [];
    
    if (placemark.street != null && 
        placemark.street!.isNotEmpty && 
        !placemark.street!.contains('+')) {
      components.add(placemark.street!);
    }
    
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      components.add(placemark.subLocality!);
    }
    
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      components.add(placemark.locality!);
    }
    
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      components.add(placemark.administrativeArea!);
    }
    
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      components.add(placemark.country!);
    }
    
    return components.isEmpty ? 'Vị trí hiện tại' : components.join(', ');
  }

  void show(BuildContext context) {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    String? imageHome;
    double? selectedLatitude;
    double? selectedLongitude;
    bool isLoadingLocation = false;
    bool showMap = false;
    LatLng? _selectedLatLng;
    MapController _mapController = MapController();

    // Khởi tạo giá trị nếu là edit mode
    if (!isAddHome && homeModel != null) {
      nameCtrl.text = homeModel!.name;
      imageHome = homeModel!.image;
      locationCtrl.text = homeModel!.location ?? '';
      selectedLatitude = homeModel!.latitude;
      selectedLongitude = homeModel!.longitude;
      
      if (homeModel!.latitude != null && homeModel!.longitude != null) {
        _selectedLatLng = LatLng(homeModel!.latitude!, homeModel!.longitude!);
        showMap = true;
      }
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: isAddHome ? "Add Home" : "Edit Home",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Hàm lấy địa chỉ từ tọa độ
            Future<String> _getAddressFromLatLng(double lat, double lng) async {
              try {
                List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

                if (placemarks.isNotEmpty) {
                  Placemark placemark = placemarks.first;
                  return _formatVietnameseAddress(placemark);
                }
              } catch (e) {
                print('Lỗi geocoding: $e');
              }
              return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
            }

            // Hàm lấy vị trí hiện tại
            Future<void> getCurrentLocation() async {
              setState(() {
                isLoadingLocation = true;
              });

              try {
                LocationPermission permission = await Geolocator.checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.denied) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
                    );
                    return;
                  }
                }

                if (permission == LocationPermission.deniedForever) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn')),
                  );
                  return;
                }

                Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );

                // Cập nhật vị trí cho map
                _selectedLatLng = LatLng(position.latitude, position.longitude);

                // Lấy địa chỉ từ tọa độ
                final address = await _getAddressFromLatLng(position.latitude, position.longitude);
                
                setState(() {
                  locationCtrl.text = address;
                  selectedLatitude = position.latitude;
                  selectedLongitude = position.longitude;
                  showMap = true;
                });

                // Di chuyển map đến vị trí mới
                _mapController.move(_selectedLatLng!, 15.0);

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi lấy vị trí: $e')),
                );
              } finally {
                setState(() {
                  isLoadingLocation = false;
                });
              }
            }

            // Hàm tìm kiếm địa chỉ bằng OpenStreetMap Nominatim
            Future<void> _searchLocation(String query) async {
              if (query.isEmpty) return;

              try {
                final response = await http.get(
                  Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=1&accept-language=vi'),
                );

                if (response.statusCode == 200) {
                  final List<dynamic> data = json.decode(response.body);
                  if (data.isNotEmpty) {
                    final result = data[0];
                    final lat = double.parse(result['lat']);
                    final lng = double.parse(result['lon']);
                    
                    final latLng = LatLng(lat, lng);
                    _selectedLatLng = latLng;

                    setState(() {
                      locationCtrl.text = result['display_name'];
                      selectedLatitude = lat;
                      selectedLongitude = lng;
                      showMap = true;
                    });

                    // Di chuyển map đến vị trí tìm kiếm
                    _mapController.move(latLng, 15.0);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không tìm thấy địa chỉ')),
                    );
                  }
                }
              } catch (e) {
                print('Lỗi search: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi khi tìm kiếm địa chỉ: $e')),
                );
              }
            }

            Future<void> _updateAddressFromLatLng(LatLng latLng) async {
              final address = await _getAddressFromLatLng(latLng.latitude, latLng.longitude);
              setState(() {
                locationCtrl.text = address;
                selectedLatitude = latLng.latitude;
                selectedLongitude = latLng.longitude;
              });
            }

            // Hàm khi tap trên map
            void _onMapTap(TapPosition tapPosition, LatLng latLng) {
              setState(() {
                _selectedLatLng = latLng;
              });
              _updateAddressFromLatLng(latLng);
            }

            // Hàm chọn ảnh
            Future<void> _pickImage() async {
              final url = await pickImageController.pickImageFileAndUpload();
              if (url != null && url.isNotEmpty) {
                setState(() {
                  imageHome = url;
                });
              }
            }

            // Hàm xử lý lưu home (thêm hoặc sửa)
            Future<void> _saveHome() async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tên home')),
                );
                return;
              }

              final deviceController = Get.find<DeviceController>();
              
              try {
                if (isAddHome) {
                  // Thêm home mới
                  final home = HomeModel(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    ownerId: FirebaseAuth.instance.currentUser!.uid,
                    image: imageHome,
                    location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                  );
                  
                  await deviceController.addHome(home);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm home "${nameCtrl.text.trim()}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Sửa home hiện tại
                  final updatedHome = HomeModel(
                    id: homeModel!.id,
                    name: nameCtrl.text.trim(),
                    ownerId: homeModel!.ownerId,
                    image: imageHome ?? homeModel!.image,
                    location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                    latitude: selectedLatitude,
                    longitude: selectedLongitude,
                    members: homeModel!.members,
                    rooms: homeModel!.rooms, // Giữ nguyên danh sách rooms
                  );
                  
                  await deviceController.updateHome(updatedHome);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã cập nhật home "${nameCtrl.text.trim()}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                
                Navigator.pop(context);
                
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Material(
                  color: Theme.of(context).dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              Icons.home_work_outlined,
                              color: Theme.of(context).primaryColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isAddHome ? "Thêm Home Mới" : "Chỉnh sửa ${homeModel?.name}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Form content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Tên Home
                                Text(
                                  "Tên Home *",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: nameCtrl,
                                  decoration: InputDecoration(
                                    hintText: "Nhập tên home...",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[400]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Ảnh Home
                                Text(
                                  "Ảnh Home",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                if (imageHome != null)
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageHome!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.error_outline, color: Colors.red),
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                else if (!isAddHome && homeModel?.image != null)
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        homeModel!.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.error_outline, color: Colors.red),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: Text(imageHome != null || (!isAddHome && homeModel?.image != null) ? "Đổi ảnh" : "Chọn ảnh"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(context).primaryColor,
                                    side: BorderSide(color: Theme.of(context).primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Vị trí với OpenStreetMap
                                Row(
                                  children: [
                                    Text(
                                      "Vị trí",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!showMap)
                                      ElevatedButton.icon(
                                        onPressed: isLoadingLocation ? null : getCurrentLocation,
                                        icon: isLoadingLocation 
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Theme.of(context).colorScheme.onPrimary,
                                                  ),
                                                ),
                                              )
                                            : const Icon(Icons.map),
                                        label: const Text("Chọn trên bản đồ"),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Search location
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: locationCtrl,
                                        decoration: InputDecoration(
                                          hintText: isAddHome?  "Nhập địa chỉ hoặc chọn trên bản đồ..." : homeModel?.location ?? "Nhập địa chỉ hoặc chọn trên bản đồ..." ,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[400]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Theme.of(context).primaryColor),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        onSubmitted: _searchLocation,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _searchLocation(locationCtrl.text),
                                      icon: const Icon(Icons.search),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.all(16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // OpenStreetMap
                                if (showMap)
                                  Container(
                                    height: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: _selectedLatLng ?? const LatLng(21.0285, 105.8542),
                                          initialZoom: 13.0,
                                          onTap: _onMapTap,
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName: 'com.example.iot_smarthome',
                                          ),
                                          MarkerLayer(
                                            markers: _selectedLatLng != null
                                                ? [
                                                    Marker(
                                                      point: _selectedLatLng!,
                                                      width: 40,
                                                      height: 40,
                                                      child: const Icon(
                                                        Icons.location_pin,
                                                        color: Colors.red,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                if (showMap) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    "Chạm vào bản đồ để chọn vị trí chính xác",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text("Hủy"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _saveHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                isAddHome ? "Thêm Home" : "Cập nhật",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }
}