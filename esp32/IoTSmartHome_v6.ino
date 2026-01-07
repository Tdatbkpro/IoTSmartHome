#include <WiFi.h>
#include <Preferences.h>
#define MQTT_MAX_PACKET_SIZE 2048
#include <PubSubClient.h>
#include <Firebase_ESP_Client.h>
#include <ArduinoJson.h>
#include <WiFiClientSecure.h>
#include <DHT.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <ESP32Servo.h>
#include <MFRC522.h>
#include <SPI.h>

// ---------- Preferences (Lưu trữ flash) ----------
Preferences preferences;

// ---------- DHT ----------
#define DHTPIN 32
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// ---------- PIR ----------
#define PIR_PIN 26
bool pirLastState = LOW;
unsigned long lastPirTrigger = 0;
const int REQ_COUNT = 3;           
const unsigned long REQ_MS = 500;  
int consecHigh = 0;
unsigned long firstHighAt = 0;
bool pirStateConfirmed = false;
unsigned long bootTime;
const unsigned long warmUpMs = 30000;

// ---------- HC-SR04 ----------
#define TRIG_PIN 12
#define ECHO_PIN 14
#define MIN_DISTANCE 15
unsigned long lastDistanceCheck = 0;
const unsigned long DISTANCE_CHECK_INTERVAL = 500;
float lastDistance = 0;
bool trashStatus = false;
int trashFillLevel = 0;

// ---------- Servo ----------
#define SERVO_PIN 13
Servo myServo;
bool trashControlMode = false;

// ---------- RFID ----------
#define SS_PIN 5
#define RST_PIN 17
MFRC522 mfrc522(SS_PIN, RST_PIN);

// Thẻ RFID với chức năng riêng biệt
String authorizedCards[] = {
  "DD 3C 85 04",  // Thẻ 1: Mở thùng rác
  "F9 8E D4 05"   // Thẻ 2: Đóng thùng rác
};

const String OPEN_CARD = "DD 3C 85 04";     // Thẻ mở
const String CLOSE_CARD = "F9 8E D4 05";    // Thẻ đóng

const int authorizedCardsCount = 2;

// Biến lưu trạng thái RFID
bool rfidAccess = false;
String lastCardUID = "";
unsigned long lastRFIDCheck = 0;
const unsigned long RFID_CHECK_INTERVAL = 1000;
bool rfidLocked = false;
unsigned long rfidLockTime = 0;
const unsigned long RFID_LOCK_DURATION = 10000;
int failedAttempts = 0;
const int MAX_FAILED_ATTEMPTS = 5;

// ---------- LED RGB ----------
#define LED_R_PIN 25
#define LED_G_PIN 33
#define LED_B_PIN 27

// Trạng thái LED
unsigned long lastLedBlink = 0;
const unsigned long LED_BLINK_INTERVAL = 300;
bool ledBlinkState = false;
int currentColor = 0; // 0: off, 1: green, 2: red, 3: blue
bool ledBlinking = false;

// ---------- MQTT ----------
const char* mqtt_server = "h2bad201.ala.asia-southeast1.emqxsl.com";
const int mqtt_port = 8883;

const char* mqtt_users[] = {
  "iotsmarthome",
  ""
};

const char* mqtt_passwords[] = {
  "Tqdat22062004@",
  ""
};

int currentAuthMethod = 0;
const int totalAuthMethods = 2;

const char* mqtt_user = mqtt_users[currentAuthMethod];
const char* mqtt_pass = mqtt_passwords[currentAuthMethod];

WiFiClientSecure wifiClient;   
PubSubClient client(wifiClient);

// ---------- FIREBASE ----------
FirebaseData fbdo;
FirebaseConfig config;
FirebaseAuth auth;

// ---------- DEVICE CONFIG ----------
#define LED_PIN 2
String ledTopic = "getDevice/Light/arduino";
String dhtTopic = "getDevice/Temperature Humidity Sensor/dht";
String pirTopic = "getDevice/Security/pir";
String trashTopic = "getDevice/Trash/servo";
String rfidTopic = "getDevice/RFID/rfid";

// ---------- MQTT CALLBACK ----------
String mainLedTopic = "";
String mainDhtTopic = "";
String mainPirTopic = "";
String mainTrashTopic = "";
String mainRfidTopic = "";
String trashStatusTopic = "";
String rfidStatusTopic = "";

String owerHomeIdPir = "";
String homeIdPir = "";
String roomIdPir = "";
String deviceIdPir = "";
String localDevice = "";

String owerHomeIdTrash = "";
String homeIdTrash = "";
String roomIdTrash = "";
String deviceIdTrash = "";

String owerHomeIdRfid = "";
String homeIdRfid = "";
String roomIdRfid = "";
String deviceIdRfid = "";

bool statusDht;
unsigned long lastSend = 0;
bool mqttConnected = false;

// Biến lưu trạng thái RFID từ Firebase
bool rfidFirebaseStatus = false;

// ========== PIR QUEUE ==========
struct PirQueueItem {
  unsigned long timestamp;
  String homeId;
  String roomId;
  String deviceId;
  String owerHomeId;
  String localDevice;
};
#define PIR_QUEUE_SIZE 10
PirQueueItem pirQueue[PIR_QUEUE_SIZE];
int pirQueueCount = 0;

// ---------- AP MODE ----------
WebServer server(80);
DNSServer dnsServer;
bool deviceProvisioned = false;
bool apModeActive = false;
const char* apSSID = "ESP32-SmartHome-AP";
const char* apPassword = "12345678";

// ========== WIFI CREDENTIALS STRUCT ==========
struct WiFiCredentials {
  char ssid[32];
  char password[64];
  bool valid;
};

// ========== HTML PAGES ==========
const char* index_html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ESP32 SmartHome - WiFi Setup</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.2);
            width: 100%;
            max-width: 500px;
            overflow: hidden;
            animation: slideIn 0.5s ease-out;
        }
        @keyframes slideIn {
            from { transform: translateY(30px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        .header {
            background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
        }
        .header p {
            opacity: 0.9;
            font-size: 16px;
        }
        .content {
            padding: 40px;
        }
        .form-group {
            margin-bottom: 25px;
        }
        label {
            display: block;
            margin-bottom: 8px;
            color: #4b5563;
            font-weight: 600;
            font-size: 14px;
        }
        input, select {
            width: 100%;
            padding: 15px;
            border: 2px solid #e5e7eb;
            border-radius: 12px;
            font-size: 16px;
            transition: all 0.3s;
        }
        input:focus, select:focus {
            outline: none;
            border-color: #4f46e5;
            box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
        }
        select {
            background-color: white;
            cursor: pointer;
        }
        .btn {
            background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
            color: white;
            border: none;
            padding: 18px;
            border-radius: 12px;
            font-size: 18px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            transition: all 0.3s;
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(79, 70, 229, 0.3);
        }
        .btn:active {
            transform: translateY(0);
        }
        .btn i {
            font-size: 20px;
        }
        .status {
            margin-top: 20px;
            padding: 15px;
            border-radius: 12px;
            display: none;
            text-align: center;
            font-weight: 500;
        }
        .success {
            background-color: #d1fae5;
            color: #065f46;
            border: 2px solid #a7f3d0;
        }
        .error {
            background-color: #fee2e2;
            color: #991b1b;
            border: 2px solid #fca5a5;
        }
        .loading {
            background-color: #e0fdfa;
            color: #0d9488;
            border: 2px solid #99f6e4;
        }
        .wifi-list {
            max-height: 300px;
            overflow-y: auto;
            border: 2px solid #e5e7eb;
            border-radius: 12px;
            margin-bottom: 20px;
            display: none;
        }
        .wifi-item {
            padding: 15px;
            border-bottom: 1px solid #e5e7eb;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        .wifi-item:hover {
            background-color: #f3f4f6;
        }
        .wifi-item:last-child {
            border-bottom: none;
        }
        .wifi-icon {
            color: #4f46e5;
            font-size: 20px;
        }
        .wifi-info {
            flex: 1;
        }
        .wifi-ssid {
            font-weight: 600;
            color: #1f2937;
        }
        .wifi-strength {
            font-size: 12px;
            color: #6b7280;
            margin-top: 4px;
        }
        .refresh-btn {
            background: #f3f4f6;
            color: #4b5563;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            font-size: 14px;
            cursor: pointer;
            margin-bottom: 15px;
            transition: all 0.2s;
        }
        .refresh-btn:hover {
            background: #e5e7eb;
        }
        .manual-toggle {
            text-align: center;
            margin: 20px 0;
        }
        .toggle-link {
            color: #4f46e5;
            text-decoration: none;
            font-weight: 500;
            cursor: pointer;
        }
        .toggle-link:hover {
            text-decoration: underline;
        }
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><i class="fas fa-wifi"></i> WiFi Setup</h1>
            <p>ESP32 SmartHome Device Configuration</p>
        </div>
        <div class="content">
            <div class="form-group">
                <label for="wifiList"><i class="fas fa-search"></i> Available Networks</label>
                <div class="wifi-list" id="wifiList"></div>
                <button type="button" class="refresh-btn" onclick="scanNetworks()">
                    <i class="fas fa-sync-alt"></i> Scan Networks
                </button>
                <div class="manual-toggle">
                    <a class="toggle-link" onclick="toggleManual()">
                        <i class="fas fa-keyboard"></i> Enter WiFi details manually
                    </a>
                </div>
            </div>
            
            <div class="form-group" id="manualForm" style="display: none;">
                <label for="ssid"><i class="fas fa-network-wired"></i> WiFi Network (SSID)</label>
                <input type="text" id="ssid" placeholder="Enter your WiFi network name">
                
                <label for="password" style="margin-top: 15px;"><i class="fas fa-lock"></i> Password</label>
                <input type="password" id="password" placeholder="Enter your WiFi password">
            </div>
            
            <button type="button" class="btn" onclick="connectWiFi()">
                <i class="fas fa-plug"></i> Connect to WiFi
            </button>
            
            <div class="status" id="status"></div>
        </div>
    </div>

    <script>
        function toggleManual() {
            const manualForm = document.getElementById('manualForm');
            const wifiList = document.getElementById('wifiList');
            const toggleLink = document.querySelector('.toggle-link');
            
            if (manualForm.style.display === 'none') {
                manualForm.style.display = 'block';
                wifiList.style.display = 'none';
                toggleLink.innerHTML = '<i class="fas fa-wifi"></i> Select from available networks';
            } else {
                manualForm.style.display = 'none';
                wifiList.style.display = 'block';
                toggleLink.innerHTML = '<i class="fas fa-keyboard"></i> Enter WiFi details manually';
            }
        }
        
        function scanNetworks() {
            const wifiList = document.getElementById('wifiList');
            const refreshBtn = document.querySelector('.refresh-btn');
            
            wifiList.innerHTML = '<div class="wifi-item"><i class="fas fa-spinner fa-spin wifi-icon"></i><div class="wifi-info"><div class="wifi-ssid">Scanning...</div></div></div>';
            wifiList.style.display = 'block';
            refreshBtn.disabled = true;
            refreshBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Scanning...';
            
            fetch('/scan')
                .then(response => response.json())
                .then(data => {
                    wifiList.innerHTML = '';
                    if (data.networks && data.networks.length > 0) {
                        data.networks.forEach(wifi => {
                            const item = document.createElement('div');
                            item.className = 'wifi-item';
                            item.onclick = () => selectWifi(wifi.ssid, wifi.encryption);
                            
                            let strengthIcon = 'fa-wifi';
                            let strengthText = 'Good';
                            let strengthColor = '#10b981';
                            
                            if (wifi.rssi <= -80) {
                                strengthIcon = 'fa-wifi';
                                strengthText = 'Weak';
                                strengthColor = '#ef4444';
                            } else if (wifi.rssi <= -70) {
                                strengthIcon = 'fa-wifi';
                                strengthText = 'Fair';
                                strengthColor = '#f59e0b';
                            } else {
                                strengthIcon = 'fa-wifi';
                                strengthText = 'Strong';
                                strengthColor = '#10b981';
                            }
                            
                            let lockIcon = wifi.encryption !== 'OPEN' ? 
                                '<i class="fas fa-lock" style="color: #ef4444; margin-right: 5px;"></i>' : 
                                '<i class="fas fa-unlock" style="color: #10b981; margin-right: 5px;"></i>';
                            
                            item.innerHTML = `
                                <i class="fas ${strengthIcon} wifi-icon" style="color: ${strengthColor}"></i>
                                <div class="wifi-info">
                                    <div class="wifi-ssid">${lockIcon} ${wifi.ssid}</div>
                                    <div class="wifi-strength">Signal: ${strengthText} (${wifi.rssi} dBm) • ${wifi.channel} Channel</div>
                                </div>
                                <i class="fas fa-chevron-right" style="color: #9ca3af;"></i>
                            `;
                            wifiList.appendChild(item);
                        });
                    } else {
                        wifiList.innerHTML = '<div class="wifi-item"><div class="wifi-info"><div class="wifi-ssid">No networks found</div></div></div>';
                    }
                    
                    document.getElementById('manualForm').style.display = 'none';
                    document.querySelector('.toggle-link').innerHTML = 
                        '<i class="fas fa-keyboard"></i> Enter WiFi details manually';
                })
                .catch(error => {
                    wifiList.innerHTML = '<div class="wifi-item"><div class="wifi-info"><div class="wifi-ssid">Error scanning networks</div></div></div>';
                    console.error('Error:', error);
                })
                .finally(() => {
                    refreshBtn.disabled = false;
                    refreshBtn.innerHTML = '<i class="fas fa-sync-alt"></i> Scan Networks';
                });
        }
        
        function selectWifi(ssid, encryption) {
            document.getElementById('ssid').value = ssid;
            
            if (encryption !== 'OPEN') {
                document.getElementById('password').focus();
            } else {
                document.getElementById('password').value = '';
            }
            
            toggleManual();
        }
        
        function connectWiFi() {
            const ssid = document.getElementById('ssid').value.trim();
            const password = document.getElementById('password').value;
            const statusDiv = document.getElementById('status');
            const connectBtn = document.querySelector('.btn');
            
            if (!ssid) {
                showStatus('Please enter WiFi network name', 'error');
                return;
            }
            
            connectBtn.disabled = true;
            connectBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Connecting...';
            statusDiv.className = 'status loading';
            statusDiv.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Connecting to ' + ssid + '...';
            statusDiv.style.display = 'block';
            
            const formData = new FormData();
            formData.append('ssid', ssid);
            formData.append('password', password);
            
            fetch('/connect', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    showStatus('<i class="fas fa-check-circle"></i> Connected successfully! IP: ' + data.ip + '<br>Device will restart in 5 seconds...', 'success');
                    
                    setTimeout(() => {
                        statusDiv.innerHTML += '<br><br><small>Connecting to MQTT server...</small>';
                    }, 2000);
                    
                    setTimeout(() => {
                        window.location.href = '/success';
                    }, 5000);
                } else {
                    showStatus('<i class="fas fa-exclamation-circle"></i> Connection failed: ' + data.message, 'error');
                    connectBtn.disabled = false;
                    connectBtn.innerHTML = '<i class="fas fa-plug"></i> Connect to WiFi';
                }
            })
            .catch(error => {
                showStatus('<i class="fas fa-exclamation-circle"></i> Error: ' + error, 'error');
                connectBtn.disabled = false;
                connectBtn.innerHTML = '<i class="fas fa-plug"></i> Connect to WiFi';
            });
        }
        
        function showStatus(message, type) {
            const statusDiv = document.getElementById('status');
            statusDiv.className = 'status ' + type;
            statusDiv.innerHTML = message;
            statusDiv.style.display = 'block';
        }
        
        window.onload = function() {
            scanNetworks();
        };
    </script>
</body>
</html>
)rawliteral";

const char* success_html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Setup Complete</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.2);
            width: 100%;
            max-width: 500px;
            overflow: hidden;
            text-align: center;
            animation: popIn 0.5s ease-out;
        }
        @keyframes popIn {
            0% { transform: scale(0.9); opacity: 0; }
            100% { transform: scale(1); opacity: 1; }
        }
        .header {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 50px 30px;
        }
        .success-icon {
            font-size: 80px;
            margin-bottom: 20px;
            animation: bounce 1s ease infinite alternate;
        }
        @keyframes bounce {
            0% { transform: translateY(0); }
            100% { transform: translateY(-10px); }
        }
        .header h1 {
            font-size: 32px;
            margin-bottom: 10px;
        }
        .header p {
            opacity: 0.9;
            font-size: 16px;
        }
        .content {
            padding: 40px;
        }
        .info-box {
            background: #f0fdf4;
            border: 2px solid #bbf7d0;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 25px;
            text-align: left;
        }
        .info-item {
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .info-item i {
            color: #10b981;
            width: 20px;
        }
        .btn {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            border: none;
            padding: 18px;
            border-radius: 12px;
            font-size: 18px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            transition: all 0.3s;
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
            text-decoration: none;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(16, 185, 129, 0.3);
        }
        .note {
            margin-top: 20px;
            color: #6b7280;
            font-size: 14px;
            line-height: 1.5;
        }
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="success-icon">
                <i class="fas fa-check-circle"></i>
            </div>
            <h1>Setup Complete!</h1>
            <p>Your ESP32 SmartHome is now connected</p>
        </div>
        <div class="content">
            <div class="info-box">
                <div class="info-item">
                    <i class="fas fa-wifi"></i>
                    <span>WiFi: <strong>%SSID%</strong></span>
                </div>
                <div class="info-item">
                    <i class="fas fa-home"></i>
                    <span>Device IP: <strong>%IP%</strong></span>
                </div>
                <div class="info-item">
                    <i class="fas fa-microchip"></i>
                    <span>Device ID: <strong>%DEVICEID%</strong></span>
                </div>
                <div class="info-item">
                    <i class="fas fa-bolt"></i>
                    <span>Status: <strong style="color: #10b981;">Online & Ready</strong></span>
                </div>
            </div>
            
            <p class="note">
                <i class="fas fa-info-circle"></i> The access point has been turned off. 
                You can now close this page. The device will automatically connect 
                to your home network on next boot.
            </p>
            
            <a href="http://%IP%" class="btn" target="_blank">
                <i class="fas fa-external-link-alt"></i> Access Device Dashboard
            </a>
        </div>
</body>
</html>
)rawliteral";

// ========== FUNCTION DECLARATIONS ==========
void saveWiFiCredentials(const char* ssid, const char* password);
WiFiCredentials loadWiFiCredentials();
void clearWiFiCredentials();
bool connectToWiFi(const char* ssid, const char* password);
void setupAPMode();
void handleRoot();
void handleScan();
void handleConnect();
void handleSuccess();
void handleNotFound();
void stopAPMode();
void reconnectMQTT();
void switchToNextAuthMethod();
void checkMQTTStatus();
void processPirQueue();
void publishPirAlert(String owerHomeId, String homeId, String roomId, String deviceId, String localDevice);
void publishDhtData();
void enqueuePir(String owerHomeId, String homeId, String roomId, String deviceId, String localDevice);
float getDistance();
void controlTrash(bool open);
void controlGate(bool open);
void publishTrashStatus();
void checkDistanceAndControlTrash();
int calculateTrashFillLevel(float distance);
void initRFID();
String readRFID();
bool checkRFIDAccess(String uid);
int getRFIDCardFunction(String uid); // Hàm mới: xác định chức năng thẻ
void handleRFID();
void publishRFIDStatus(bool success, String cardUID, String function);
void sendRFIDAlert(String cardUID, bool authorized, String function);
void initRGBLED();
void setRGBColor(int r, int g, int b);
void controlLEDBasedOnRFIDStatus();
void handleLED();
void startBlink(int color);
void stopBlink();

// ========== WIFI FUNCTIONS ==========
bool connectToWiFi(const char* ssid, const char* password) {
  Serial.println("\n📶 Attempting to connect to WiFi...");
  
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(1000);
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  bool connectionSuccess = false;
  
  while (attempts < 30) {
    delay(1000);
    int status = WiFi.status();
    
    if (status == WL_CONNECTED) {
      connectionSuccess = true;
      Serial.println(" - CONNECTED!");
      break;
    } else if (status == WL_CONNECT_FAILED || status == WL_NO_SSID_AVAIL) {
      Serial.printf(" -  Connection failed (status: %d)\n", status);
      break;
    }
    
    Serial.print(".");
    attempts++;
  }
  
  if (connectionSuccess) {
    Serial.println("\nWiFi connected successfully!");
    Serial.println("📡 IP Address: " + WiFi.localIP().toString());
    
    deviceProvisioned = true;
    saveWiFiCredentials(ssid, password);
    
    return true;
  } else {
    Serial.println("\n WiFi connection failed after 30 attempts");
    
    WiFi.disconnect();
    delay(1000);
    
    return false;
  }
}

void saveWiFiCredentials(const char* ssid, const char* password) {
  preferences.begin("wifi-config", false);
  preferences.putString("ssid", ssid);
  preferences.putString("password", password);
  preferences.putBool("provisioned", true);
  preferences.end();
}

WiFiCredentials loadWiFiCredentials() {
  WiFiCredentials creds;
  preferences.begin("wifi-config", true);
  String ssid = preferences.getString("ssid", "");
  String password = preferences.getString("password", "");
  deviceProvisioned = preferences.getBool("provisioned", false);
  preferences.end();
  
  strncpy(creds.ssid, ssid.c_str(), sizeof(creds.ssid) - 1);
  strncpy(creds.password, password.c_str(), sizeof(creds.password) - 1);
  creds.valid = (ssid.length() > 0);
  
  return creds;
}

void clearWiFiCredentials() {
  preferences.begin("wifi-config", false);
  preferences.remove("ssid");
  preferences.remove("password");
  preferences.remove("provisioned");
  preferences.end();
  deviceProvisioned = false;
}

// ========== HC-SR04 FUNCTIONS ==========
float getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  float distance = duration * 0.034 / 2;
  
  if (duration == 0 || distance > 300) {
    return -1;
  }
  
  return distance;
}

// ========== THÙNG RÁC FUNCTIONS ==========
int calculateTrashFillLevel(float distance) {
  const float EMPTY_DISTANCE = 40.0;
  const float FULL_DISTANCE = 5.0;
  
  if (distance < 0) return 0;
  
  if (distance > EMPTY_DISTANCE) distance = EMPTY_DISTANCE;
  if (distance < FULL_DISTANCE) distance = FULL_DISTANCE;
  
  float fillPercent = ((EMPTY_DISTANCE - distance) / (EMPTY_DISTANCE - FULL_DISTANCE)) * 100;
  
  if (fillPercent < 0) fillPercent = 0;
  if (fillPercent > 100) fillPercent = 100;
  
  return (int)fillPercent;
}

void controlTrash(bool open) {
  if (open) {
    myServo.write(90);
    trashStatus = true;
    Serial.println("🗑️ Thùng rác: MỞ (90°)");
  } else {
    myServo.write(0);
    trashStatus = false;
    Serial.println("🗑️ Thùng rác: ĐÓNG (0°)");
  }
  
  publishTrashStatus();
}

void controlGate(bool open) {
  if (open) {
    myServo.write(90);
    Serial.println("Cửa mở");
  } else {
    myServo.write(180);
    Serial.println("Cửa đóng");
  }
}


void publishTrashStatus() {
  if (trashStatusTopic == "") return;
  
  StaticJsonDocument<256> doc;
  doc["status"] = trashStatus;
  doc["mode"] = trashControlMode ? "manual" : "auto";
  doc["distance"] = lastDistance;
  doc["fillLevel"] = trashFillLevel;
  doc["deviceType"] = "Trash";
  doc["deviceName"] = "Smart Trash Bin";
  
  char buffer[256];
  serializeJson(doc, buffer);
  
  if (client.publish(trashStatusTopic.c_str(), buffer, true)) {
    Serial.printf(" Trash status sent: %s => %s\n", trashStatusTopic.c_str(), buffer);
  }
}

void checkDistanceAndControlTrash() {
  static unsigned long objectGoneTime = 0;
  unsigned long now = millis();

  if (now - lastDistanceCheck > DISTANCE_CHECK_INTERVAL) {
    float distance = getDistance();

    if (distance > 0) {
      lastDistance = distance;

      int newFillLevel = calculateTrashFillLevel(distance);
      if (newFillLevel != trashFillLevel) {
        trashFillLevel = newFillLevel;

        if (trashFillLevel >= 95) {
          if (client.connected() && homeIdTrash != "" &&
              deviceIdTrash != "" && owerHomeIdTrash != "") {
            StaticJsonDocument<256> doc;
            doc["type"] = "alert";
            doc["deviceType"] = "Trash";
            doc["deviceName"] = "Smart Trash Bin";
            doc["localDevice"] = "Thùng rác thông minh";
            doc["userId"] = owerHomeIdTrash;
            doc["message"] = "Thùng rác đã đầy! Vui lòng dọn dẹp.";
            doc["fillLevel"] = trashFillLevel;

            char buffer[256];
            serializeJson(doc, buffer);
            String topic = "alert/" + homeIdTrash + "/" + roomIdTrash + "/" + deviceIdTrash;
            client.publish(topic.c_str(), buffer, true);
          }
        }
      }

      if (!trashControlMode) {
        if (distance <= MIN_DISTANCE && !trashStatus) {
          Serial.println(" Phát hiện người - Mở thùng rác");
          controlTrash(true);
          objectGoneTime = 0;
        }
        else if (distance > MIN_DISTANCE && trashStatus) {
          if (objectGoneTime == 0) {
            objectGoneTime = now;
          }
          else if (now - objectGoneTime > 5000) {
            Serial.println(" 3 giây đã trôi qua - Đóng thùng rác");
            controlTrash(false);
            objectGoneTime = 0;
          }
        }
        else {
          objectGoneTime = 0;
        }
      }
    }
    
    lastDistanceCheck = now;
  }
}

// ========== RFID FUNCTIONS ==========
void initRFID() {
  SPI.begin();
  mfrc522.PCD_Init();
  delay(4);
  Serial.println(" RFID module initialized");
}

String readRFID() {
  if (!mfrc522.PICC_IsNewCardPresent() || !mfrc522.PICC_ReadCardSerial()) {
    return "";
  }
  
  String uidString = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    uidString.concat(String(mfrc522.uid.uidByte[i] < 0x10 ? " 0" : " "));
    uidString.concat(String(mfrc522.uid.uidByte[i], HEX));
  }
  uidString.toUpperCase();
  uidString.trim();
  
  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
  
  return uidString;
}

bool checkRFIDAccess(String uid) {
  for (int i = 0; i < authorizedCardsCount; i++) {
    if (uid.equals(authorizedCards[i])) {
      return true;
    }
  }
  return false;
}

// Hàm xác định chức năng của thẻ RFID
int getRFIDCardFunction(String uid) {
  if (uid.equals(OPEN_CARD)) {
    return 1; // Thẻ mở
  } else if (uid.equals(CLOSE_CARD)) {
    return 2; // Thẻ đóng
  }
  return 0; // Không phải thẻ hợp lệ
}

void handleRFID() {
  unsigned long now = millis();
  
  if (rfidLocked) {
    if (now - rfidLockTime > RFID_LOCK_DURATION) {
      rfidLocked = false;
      failedAttempts = 0;
      Serial.println(" RFID unlocked after timeout");
    }
    return;
  }
  
  if (now - lastRFIDCheck > RFID_CHECK_INTERVAL) {
    String cardUID = readRFID();
    
    if (cardUID != "" && cardUID != lastCardUID) {
      lastCardUID = cardUID;
      bool authorized = checkRFIDAccess(cardUID);
      
      if (authorized) {
        int cardFunction = getRFIDCardFunction(cardUID);
        String functionStr = "";
        
        if (cardFunction == 1) { // Thẻ mở
          // Chuyển sang chế độ manual và mở thùng rác        
           controlGate(true);
          functionStr = "OPEN";
          Serial.println(" RFID Card: " + cardUID + " - MỞ Cửa");
          publishRFIDStatus(true, cardUID, functionStr);
          startBlink(1); // Xanh lá cây
        } else if (cardFunction == 2) { // Thẻ đóng
          // Chuyển sang chế độ manual và đóng thùng rác
          controlGate(false);
          functionStr = "CLOSE";
          publishRFIDStatus(false, cardUID, functionStr);
          Serial.println("RFID Card: " + cardUID + " -  ĐÓNG Cửa");
          startBlink(3); // Xanh dương
        }
        
        failedAttempts = 0;
        
        // Gửi alert thành công
        sendRFIDAlert(cardUID, true, functionStr);
        
      } else {
        // Thẻ sai: nháy cam
        startBlink(4); 
        failedAttempts++;
        
        // Gửi alert thất bại
        sendRFIDAlert(cardUID, false, "INVALID");
        
        // Gửi trạng thái RFID
        publishRFIDStatus(false, cardUID, "INVALID");
        
        // Kiểm tra khóa RFID
        if (failedAttempts >= MAX_FAILED_ATTEMPTS) {
          rfidLocked = true;
          rfidLockTime = now;
          Serial.println(" RFID locked due to too many failed attempts");
          
          // Gửi alert khóa
          if (client.connected() && homeIdRfid != "" && deviceIdRfid != "" && owerHomeIdRfid != "") {
            StaticJsonDocument<256> doc;
            doc["type"] = "alert";
            doc["deviceType"] = "RFID";
            doc["deviceName"] = "RFID Reader";
            doc["localDevice"] = "Cửa ra vào";
            doc["userId"] = owerHomeIdRfid;
            doc["message"] = "RFID bị khóa do quá nhiều lần thử sai!";
            doc["cardUID"] = cardUID;
            
            char buffer[256];
            serializeJson(doc, buffer);
            String topic = "alert/" + homeIdRfid + "/" + roomIdRfid + "/" + deviceIdRfid;
            client.publish(topic.c_str(), buffer, true);
          }
        }
      }
    }
    
    lastRFIDCheck = now;
  }
}

void publishRFIDStatus(bool success, String cardUID, String function) {
  if (rfidStatusTopic == "") return;
  
  StaticJsonDocument<256> doc;
  doc["status"] = success;
  doc["cardUID"] = cardUID;
  doc["function"] = function;
  doc["deviceType"] = "RFID";
  doc["deviceName"] = "RFID Reader";
  doc["locked"] = rfidLocked;
  doc["failedAttempts"] = failedAttempts;
  
  char buffer[256];
  serializeJson(doc, buffer);
  
  if (client.publish(rfidStatusTopic.c_str(), buffer, true)) {
    Serial.printf("📤 RFID status sent: %s => %s\n", rfidStatusTopic.c_str(), buffer);
  }
}

void sendRFIDAlert(String cardUID, bool authorized, String function) {
  if (client.connected() && homeIdRfid != "" && deviceIdRfid != "" && owerHomeIdRfid != "") {
    StaticJsonDocument<256> doc;
    doc["type"] = "alert";
    doc["deviceType"] = "RFID";
    doc["deviceName"] = "RFID";
    doc["localDevice"] = "Cửa ra vào";
    doc["userId"] = owerHomeIdRfid;
    // doc["cardUID"] = cardUID;
    // doc["authorized"] = authorized;
    // doc["function"] = function;
    
    if (authorized) {
      if (function == "OPEN") {
        doc["message"] = "Thẻ RFID mở cửa được quét";
      } else if (function == "CLOSE") {
        doc["message"] = "Thẻ RFID đóng cửa được quét";
      } else {
        doc["message"] = "Thẻ RFID hợp lệ được quét";
      }
    } else {
      doc["message"] = "Thẻ RFID không hợp lệ!";
    }
    
    char buffer[256];
    serializeJson(doc, buffer);
    String topic = "alert/" + homeIdRfid + "/" + roomIdRfid + "/" + deviceIdRfid;
    client.publish(topic.c_str(), buffer, true);
  }
}

// ========== LED RGB FUNCTIONS ==========
void initRGBLED() {
  pinMode(LED_R_PIN, OUTPUT);
  pinMode(LED_G_PIN, OUTPUT);
  pinMode(LED_B_PIN, OUTPUT);
  setRGBColor(0, 0, 0);
  Serial.println(" RGB LED initialized");
}

void setRGBColor(int r, int g, int b) {
  analogWrite(LED_R_PIN, r);
  analogWrite(LED_G_PIN, g);
  analogWrite(LED_B_PIN, b);
}

void controlLEDBasedOnRFIDStatus() {
  // LED hiển thị trạng thái từ Firebase
  if (rfidFirebaseStatus) {
    // Status = true: LED xanh nước biển (0, 0, 255)
    setRGBColor(0, 0, 255);
    Serial.println(" LED: Xanh nước biển (RFID Status = TRUE)");
  } else {
    // Status = false: LED đỏ (255, 0, 0)
    setRGBColor(255, 0, 0);
    Serial.println(" LED: Đỏ (RFID Status = FALSE)");
  }
}

int blinkCount = 0;
const int MAX_BLINKS = 6; // 3 lần nháy = 6 trạng thái (on/off)

void startBlink(int color) {
  ledBlinking = true;
  currentColor = color;
  ledBlinkState = true;
  blinkCount = 0;
  lastLedBlink = millis();
}

void stopBlink() {
  ledBlinking = false;
  currentColor = 0;
  controlLEDBasedOnRFIDStatus();
}

void handleLED() {
  unsigned long now = millis();
  
  if (ledBlinking) {
    if (now - lastLedBlink > LED_BLINK_INTERVAL) {
      ledBlinkState = !ledBlinkState;
      
      if (ledBlinkState) {
        blinkCount++;
        if (blinkCount >= MAX_BLINKS) {
          stopBlink();
          return;
        }
      }
      
      // Hiển thị màu tương ứng
      if (currentColor == 1) { // Green (Đúng)
        if (ledBlinkState) {
          setRGBColor(0, 255, 0); // Green on
        } else {
          setRGBColor(0, 0, 0);   // Off
        }
      } else if (currentColor == 2) { // Red (Đóng)
        if (ledBlinkState) {
          setRGBColor(255, 0, 0); // Red on
        } else {
          setRGBColor(0, 0, 0);   // Off
        }
      } else if (currentColor == 3) { // Blue (Mở)
        if (ledBlinkState) {
          setRGBColor(0, 0, 255); // Blue on
        } else {
          setRGBColor(0, 0, 0);   // Off
        }
      } else if (currentColor == 4) { // Cam (Sai)
        if (ledBlinkState) {
          setRGBColor(255, 183, 77); // Blue on
        } else {
          setRGBColor(0, 0, 0);   // Off
        }
      }
      
      lastLedBlink = now;
    }
  }
}

// ========== AP MODE FUNCTIONS ==========
void setupAPMode() {
  Serial.println("\n Setting up AP Mode...");
  
  WiFi.mode(WIFI_AP);
  delay(100);
  
  bool apStarted = WiFi.softAP(apSSID, apPassword);
  if (apStarted) {
    Serial.println(" Access Point started successfully!");
    
    dnsServer.start(53, "*", WiFi.softAPIP());
    
    server.on("/", HTTP_GET, handleRoot);
    server.on("/scan", HTTP_GET, handleScan);
    server.on("/connect", HTTP_POST, handleConnect);
    server.on("/success", HTTP_GET, handleSuccess);
    server.onNotFound(handleNotFound);
    
    server.begin();
    Serial.println(" HTTP server started");
    
    apModeActive = true;
  }
}

void handleRoot() { server.send(200, "text/html", index_html); }

void handleScan() {
  int n = WiFi.scanNetworks();
  DynamicJsonDocument doc(4096);
  JsonArray networks = doc.createNestedArray("networks");
  
  for (int i = 0; i < n; i++) {
    JsonObject network = networks.createNestedObject();
    network["ssid"] = WiFi.SSID(i);
    network["rssi"] = WiFi.RSSI(i);
    network["channel"] = WiFi.channel(i);
    network["encryption"] = (WiFi.encryptionType(i) == WIFI_AUTH_OPEN) ? "OPEN" : "SECURED";
  }
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

void handleConnect() {
  if (server.hasArg("ssid")) {
    String ssid = server.arg("ssid");
    String password = server.arg("password");
    
    DynamicJsonDocument doc(256);
    
    if (connectToWiFi(ssid.c_str(), password.c_str())) {
      doc["success"] = true;
      doc["message"] = "Connected successfully";
      doc["ip"] = WiFi.localIP().toString();
      doc["rssi"] = WiFi.RSSI();
    } else {
      doc["success"] = false;
      doc["message"] = "Connection failed. Please check credentials.";
    }
    
    String response;
    serializeJson(doc, response);
    server.send(200, "application/json", response);
  } else {
    server.send(400, "application/json", "{\"success\":false,\"message\":\"SSID required\"}");
  }
}

void handleSuccess() {
  String html = String(success_html);
  html.replace("%SSID%", preferences.getString("ssid", "").c_str());
  html.replace("%IP%", WiFi.localIP().toString().c_str());
  html.replace("%DEVICEID%", "ESP32-" + String((uint32_t)ESP.getEfuseMac(), HEX));
  
  server.send(200, "text/html", html);
}

void handleNotFound() {
  server.send(404, "text/plain", "404: Not found");
}

void stopAPMode() {
  if (apModeActive) {
    server.stop();
    dnsServer.stop();
    WiFi.softAPdisconnect(true);
    apModeActive = false;
    Serial.println(" AP Mode stopped");
  }
}

// ========== MQTT FUNCTIONS ==========
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.println("\n========== MQTT CALLBACK TRIGGERED! ==========");
  
  String msg;
  for (int i = 0; i < length; i++) {
    msg += (char)payload[i];
  }
  
  Serial.printf(" MQTT Received [%s]: %s\n", topic, msg.c_str());

  StaticJsonDocument<1024> doc;
  DeserializationError error = deserializeJson(doc, msg);
  
  if (!error) {
    String topicStr = String(topic);
    
    if (topicStr.startsWith("getDevice/")) {
      String ownerHomeId = doc["ownerHomeId"] | "";
      String homeId = doc["homeId"] | "";
      String roomId = doc["roomId"] | "";
      String deviceId = doc["deviceId"] | "";
      String localDeviceRecv = doc["localDevice"];
      String fullTopic = homeId + "/" + roomId + "/" + deviceId;

      Serial.printf(" DEVICE CONFIGURATION:\n");
      Serial.printf("   User: %s\n", ownerHomeId.c_str());
      Serial.printf("   Home: %s, Room: %s, Device: %s\n", homeId.c_str(), roomId.c_str(), deviceId.c_str());

      if (topicStr.startsWith("getDevice/Light")) {
        mainLedTopic = fullTopic;
        client.subscribe(mainLedTopic.c_str());
        Serial.println(" LED configured!");
        digitalWrite(LED_PIN, HIGH);
        delay(500);
        digitalWrite(LED_PIN, LOW);
      }
      else if (topicStr.startsWith("getDevice/Security")) {
        mainPirTopic = fullTopic;
        owerHomeIdPir = ownerHomeId;
        homeIdPir = homeId;
        roomIdPir = roomId;
        deviceIdPir = deviceId;
        localDevice = localDeviceRecv;
        Serial.println(" PIR configured!");
      }
      else if (topicStr.startsWith("getDevice/Temperature")) {
        mainDhtTopic = fullTopic; 
        Serial.println(" DHT configured!");
        client.subscribe(mainDhtTopic.c_str());
        statusDht = true;
        Serial.println("   Status: AUTO ON");
        delay(100);
        publishDhtData();
      }
      else if (topicStr.startsWith("getDevice/Trash")) {
        mainTrashTopic = fullTopic;
        owerHomeIdTrash = ownerHomeId;
        homeIdTrash = homeId;
        roomIdTrash = roomId;
        deviceIdTrash = deviceId;
        trashStatusTopic = "Status/" + mainTrashTopic;
        client.subscribe(mainTrashTopic.c_str());
        Serial.println(" Thùng rác thông minh configured!");
        delay(100);
        publishTrashStatus();
      }
      else if (topicStr.startsWith("getDevice/RFID")) {
        mainRfidTopic = fullTopic;
        owerHomeIdRfid = ownerHomeId;
        homeIdRfid = homeId;
        roomIdRfid = roomId;
        deviceIdRfid = deviceId;
        rfidStatusTopic = "Status/" + mainRfidTopic;
        client.subscribe(mainRfidTopic.c_str());
        Serial.println(" RFID configured!");
        
        // Gửi trạng thái ban đầu
        delay(100);
        publishRFIDStatus(false, "", "NONE");
      }
    }
    
    // Control topics
    else if (topicStr == mainDhtTopic) {
      bool newStatus = doc["status"] | false;
      statusDht = newStatus;
      
      Serial.printf(" CONTROL SIGNAL RECEIVED - DHT Status: %s\n", statusDht ? "ON" : "OFF");
      
      if (statusDht) {
        publishDhtData();
      }
    } 
    
    else if (topicStr == mainLedTopic) {
      bool status = doc["status"] | false;
      digitalWrite(LED_PIN, status ? HIGH : LOW);
      Serial.printf(" LED %s\n", status ? "ON" : "OFF");
    }
    
    else if (topicStr == mainTrashTopic) {
      bool controlStatus = doc["status"] | false;
      String mode = doc["mode"] | "auto";
      
      Serial.printf(" THÙNG RÁC CONTROL RECEIVED - Status: %s, Mode: %s\n", 
                    controlStatus ? "MỞ" : "ĐÓNG", mode.c_str());
      trashStatus = controlStatus;
      if (mode == "manual") {
        trashControlMode = true;
        controlTrash(controlStatus);
      } else if (mode == "auto") {
        trashControlMode = false;
        Serial.println(" Chuyển sang chế độ TỰ ĐỘNG");
      }
    }
    
    else if (topicStr == mainRfidTopic) {
      // Nhận trạng thái RFID từ Firebase (do Flutter app sửa)
      bool newStatus = doc["status"] | false;
      rfidFirebaseStatus = newStatus;
      
      Serial.printf(" RFID STATUS UPDATE FROM FIREBASE: %s\n", 
                    rfidFirebaseStatus ? "TRUE (Blue)" : "FALSE (Red)");
      
      // Cập nhật LED ngay lập tức
      controlLEDBasedOnRFIDStatus();
      
      // Có thể reset lock từ server
      String command = doc["command"] | "";
      if (command == "reset_lock") {
        rfidLocked = false;
        failedAttempts = 0;
        Serial.println(" RFID lock reset from server");
      }
    }
    
  } else {
    Serial.printf("JSON Parse error: %s\n", error.c_str());
  }

  Serial.println("===========================================\n");
}

void switchToNextAuthMethod() {
  currentAuthMethod = (currentAuthMethod + 1) % totalAuthMethods;
  mqtt_user = mqtt_users[currentAuthMethod];
  mqtt_pass = mqtt_passwords[currentAuthMethod];
  
  Serial.printf("\n Switching to auth method %d\n", currentAuthMethod + 1);
}

void reconnectMQTT() {
  int attempts = 0;
  while (!client.connected() && attempts < 3) {
    attempts++;
    Serial.printf("\n MQTT Connection attempt %d/3 (Auth method %d)...\n", attempts, currentAuthMethod + 1);
    
    String clientId = "ESP32-" + String(millis()) + "-" + String(random(0xffff), HEX);
    
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println(" WiFi not connected");
      delay(5000);
      continue;
    }

    wifiClient.setInsecure();
    
    bool connectResult;
    if (strlen(mqtt_user) > 0 && strlen(mqtt_pass) > 0) {
      connectResult = client.connect(clientId.c_str(), mqtt_user, mqtt_pass);
    } else if (strlen(mqtt_user) > 0) {
      connectResult = client.connect(clientId.c_str(), mqtt_user, NULL);
    } else {
      connectResult = client.connect(clientId.c_str());
    }
    
    if (connectResult) {
      Serial.println("MQTT CONNECTED SUCCESSFULLY!");
      mqttConnected = true;
      
      Serial.println(" Subscribing to discovery topics:");
      
      client.subscribe(ledTopic.c_str());
      Serial.printf("    %s\n", ledTopic.c_str());
      
      client.subscribe(dhtTopic.c_str());
      Serial.printf("    %s\n", dhtTopic.c_str());
      
      client.subscribe(pirTopic.c_str());
      Serial.printf("    %s\n", pirTopic.c_str());
      
      client.subscribe(trashTopic.c_str());
      Serial.printf("    %s\n", trashTopic.c_str());
      
      client.subscribe(rfidTopic.c_str());
      Serial.printf("    %s\n", rfidTopic.c_str());
      
      break;
    } else {
      int errorCode = client.state();
      Serial.printf(" MQTT connection failed, rc=%d\n", errorCode);
      
      if (attempts >= 2) {
        switchToNextAuthMethod();
        attempts = 0;
      }
      
      delay(3000);
    }
  }
  
  if (!client.connected()) {
    Serial.println("\n CRITICAL: All MQTT authentication methods failed");
  }
}

void checkMQTTStatus() {
  static unsigned long lastCheck = 0;
  if (millis() - lastCheck > 20000) {
    if (client.connected()) {
      Serial.printf("\nMQTT STATUS:  CONNECTED (Auth method %d)\n", currentAuthMethod + 1);
      Serial.printf("   Thùng rác: %s, Đầy: %d%%\n", 
                    trashStatus ? "MỞ" : "ĐÓNG",
                    trashFillLevel);
      Serial.printf("   RFID: %s, Firebase Status: %s\n",
                    rfidLocked ? " LOCKED" : " UNLOCKED",
                    rfidFirebaseStatus ? "TRUE (Blue)" : "FALSE (Red)");
      Serial.printf("   Thẻ hợp lệ: Thẻ mở = %s, Thẻ đóng = %s\n",
                    OPEN_CARD.c_str(), CLOSE_CARD.c_str());
    } else {
      Serial.printf("\n📊 MQTT STATUS:  DISCONNECTED\n");
    }
    Serial.printf("   WiFi: %s\n", 
                  WiFi.status() == WL_CONNECTED ? "" : "");
    lastCheck = millis();
  }
}

// ========== PIR QUEUE FUNCTIONS ==========
void enqueuePir(String owerHomeId, String homeId, String roomId, String deviceId, String localDevice) {
  if (pirQueueCount < PIR_QUEUE_SIZE) {
    pirQueue[pirQueueCount++] = {millis(), homeId, roomId, deviceId, owerHomeId, localDevice};
  }
}

void processPirQueue() {
  for (int i = 0; i < pirQueueCount; i++) {
    if (client.connected()) {
      PirQueueItem item = pirQueue[i];
      
      if (item.owerHomeId == "") continue;
      
      StaticJsonDocument<256> doc;
      doc["type"] = "alert";
      doc["deviceType"] = "Security";
      doc["deviceName"] = "pir";
      doc["userId"] = item.owerHomeId;
      doc["localDevice"] = item.localDevice;

      char buffer[256];
      serializeJson(doc, buffer);
      String topic = "alert/" + item.homeId + "/" + item.roomId + "/" + item.deviceId;
      
      if (client.publish(topic.c_str(), buffer, true)) {
        for (int j = i; j < pirQueueCount - 1; j++) pirQueue[j] = pirQueue[j + 1];
        pirQueueCount--;
        i--;
      }
    }
  }
}

void publishPirAlert(String owerHomeId, String homeId, String roomId, String deviceId, String localDevice) {
  if (owerHomeId == "") {
    enqueuePir(owerHomeId, homeId, roomId, deviceId, localDevice);
    return;
  }
  
  if (!client.connected() || homeId == "" || deviceId == "") {
    enqueuePir(owerHomeId, homeId, roomId, deviceId,localDevice);
    return;
  }

  StaticJsonDocument<256> doc;
  doc["type"] = "alert";
  doc["deviceType"] = "Security";
  doc["deviceName"] = "pir";
  doc["localDevice"] = localDevice;
  doc["userId"] = owerHomeId;

  char buffer[256];
  serializeJson(doc, buffer);

  String topic = "alert/" + homeId + "/" + roomId + "/" + deviceId;
  if (client.publish(topic.c_str(), buffer, true)) {
    Serial.printf("PIR phát hiện người — Gửi MQTT: %s => %s\n", topic.c_str(), buffer);
  } else {
    enqueuePir(owerHomeId, homeId, roomId, deviceId, localDevice);
  }
}

void publishDhtData() {
  if (mainDhtTopic == "") return;

  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) return;
  
  if (!statusDht) return;

  StaticJsonDocument<128> doc;
  doc["temperature"] = t;
  doc["humidity"] = h;
  doc["status"] = true;

  char buffer[128];
  serializeJson(doc, buffer);
  String statusTopic = "Status/" + mainDhtTopic;
  
  if (client.publish(statusTopic.c_str(), buffer, true)) {
    Serial.printf(" Gửi DHT data thành công: %.1f°C, %.1f%%\n", t, h);
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n ESP32 SmartHome - HỆ THỐNG ĐA CHỨC NĂNG");
  Serial.println("=============================================");
  
  // Setup pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(PIR_PIN, INPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  
  // Setup sensors
  dht.begin();
  
  // Setup servo cho thùng rác
  myServo.attach(SERVO_PIN);
  controlTrash(false);
  
  // Setup RFID
  initRFID();
  
  // Setup RGB LED
  initRGBLED();
  
  bootTime = millis();

  preferences.begin("wifi-config", false);
  preferences.end();

  WiFiCredentials savedCreds = loadWiFiCredentials();
  
  if (savedCreds.valid && deviceProvisioned) {
    Serial.println(" Found saved WiFi credentials - Attempting auto-connect");
    
    if (connectToWiFi(savedCreds.ssid, savedCreds.password)) {
      Serial.println("Auto-connect successful!");
    } else {
      clearWiFiCredentials();
      setupAPMode();
    }
  } else {
    setupAPMode();
  }

  wifiClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  client.setKeepAlive(60);
  client.setBufferSize(1024);
  
  if (deviceProvisioned && WiFi.status() == WL_CONNECTED) {
    reconnectMQTT();
  }

  config.database_url = "https://iotsmarthome-187be-default-rtdb.asia-southeast1.firebasedatabase.app";
  config.signer.tokens.legacy_token = "aBF2aZ32nJ5qeAtxANlZ51OeVKYbMfcpzGgAnZmR";
  Firebase.begin(&config, &auth);
  
  Serial.println(" Setup completed");
  
  // Hiển thị thông tin thẻ RFID hợp lệ
  Serial.println("\n RFID Cards Configured:");
  Serial.println("   Thẻ 1 (Mở): " + OPEN_CARD);
  Serial.println("   Thẻ 2 (Đóng): " + CLOSE_CARD);
  
  // LED hiển thị trạng thái ban đầu
  controlLEDBasedOnRFIDStatus();
}

void loop() {
  if (apModeActive) {
    dnsServer.processNextRequest();
    server.handleClient();
    
    static unsigned long lastBlink = 0;
    if (millis() - lastBlink > 1000) {
      digitalWrite(LED_PIN, !digitalRead(LED_PIN));
      lastBlink = millis();
    }
    
    if (deviceProvisioned && WiFi.status() == WL_CONNECTED) {
      delay(3000);
      stopAPMode();
      Serial.println("Restarting for normal operation...");
      ESP.restart();
    }
    
    return;
  }

  if (!deviceProvisioned) {
    if (!apModeActive) {
      setupAPMode();
    }
    delay(1000);
    return;
  }

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println(" WiFi disconnected! Attempting reconnect...");
    WiFiCredentials savedCreds = loadWiFiCredentials();
    if (savedCreds.valid) {
      connectToWiFi(savedCreds.ssid, savedCreds.password);
    } else {
      setupAPMode();
    }
    return;
  }

  if (!client.connected()) {
    Serial.println(" MQTT disconnected - Reconnecting...");
    mqttConnected = false;
    reconnectMQTT();
  }
  
  client.loop();
  checkMQTTStatus();

  unsigned long now = millis();
  if (now - bootTime < warmUpMs) return;

  // ========== PIR HANDLING ==========
  bool reading = digitalRead(PIR_PIN);
  if (reading == HIGH) {
    if (firstHighAt == 0) firstHighAt = now;
    consecHigh++;
    if (!pirStateConfirmed && consecHigh >= REQ_COUNT && (now - firstHighAt >= REQ_MS)) {
      pirStateConfirmed = true;
      
      if (now - lastPirTrigger > 6000 && homeIdPir != "" && deviceIdPir != "" && owerHomeIdPir != "") {
        publishPirAlert(owerHomeIdPir, homeIdPir, roomIdPir, deviceIdPir,localDevice);
        lastPirTrigger = now;
      }
    }
  } else {
    consecHigh = 0;
    firstHighAt = 0;
    pirStateConfirmed = false;
  }
  if (Serial.available()) {
  String command = Serial.readStringUntil('\n');
  command.trim();
  
  if (command == "RESET_WIFI") {
    Serial.println(" Xác nhận reset WiFi? Gõ 'YES' để xác nhận");
    
    unsigned long startTime = millis();
    while (millis() - startTime < 5000) {
      if (Serial.available()) {
        String confirm = Serial.readStringUntil('\n');
        confirm.trim();
        
        if (confirm == "YES") {
          Serial.println(" Đang xóa thông tin WiFi...");
          clearWiFiCredentials();
          
          // Nhấp nháy LED
          for(int i = 0; i < 5; i++) {
            digitalWrite(LED_PIN, HIGH);
            delay(200);
            digitalWrite(LED_PIN, LOW);
            delay(200);
          }
          
          Serial.println(" WiFi đã được reset!");
          Serial.println(" Khởi động lại ESP32...");
          delay(1000);
          ESP.restart();
        } else {
          Serial.println(" Hủy bỏ reset WiFi");
        }
        break;
      }
    }
  }
  else if (command == "STATUS") {
    Serial.println("\n === THÔNG TIN HỆ THỐNG ===");
    Serial.printf("WiFi SSID: %s\n", preferences.getString("ssid", "").c_str());
    Serial.printf("WiFi Status: %s\n", WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected");
    Serial.printf("IP Address: %s\n", WiFi.localIP().toString().c_str());
    Serial.printf("MQTT Status: %s\n", client.connected() ? "Connected" : "Disconnected");
    Serial.println("===========================\n");
  }
}
  // ========== THÙNG RÁC HANDLING ==========
  checkDistanceAndControlTrash();
  
  // ========== RFID HANDLING ==========
  handleRFID();
  
  // ========== LED HANDLING ==========
  handleLED();
  
  // ========== PROCESS QUEUES ==========
  processPirQueue();

  // ========== DHT PUBLISH ==========
  if (now - lastSend > 60000) {
    publishDhtData();
    lastSend = now;
  }
  
  delay(100);
}
