import 'dotenv/config';
import { InfluxDBClient, Point } from '@influxdata/influxdb3-client';

class InfluxData {
  constructor() {
    this.token = process.env.INFLUXDB_TOKEN;
    this.host = 'https://us-east-1-1.aws.cloud2.influxdata.com';
    this.bucket = 'SensorData';
    this.client = new InfluxDBClient({
      host: this.host,
      token: this.token,
    });
  }

  async writeSensorData(sensorName, temperature, humidity) {
    const point = Point.measurement("environment")
      .setTag("sensor_name", sensorName)
      .setFloatField("temperature", temperature)
      .setFloatField("humidity", humidity)  // sửa từ boolean thành float
      .setTimestamp(new Date());

    try {
      await this.client.write(point, this.bucket);
      await new Promise(resolve => setTimeout(resolve, 1000));
    } catch (err) {
      console.error(" Write to InfluxDB failed:", err);
    }
  }

  close() {
    this.client.close();
    console.log(' Đã đóng kết nối InfluxDB');
  }
}

export default InfluxData;
