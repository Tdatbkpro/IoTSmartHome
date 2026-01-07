export default class DeviceStatus {
  constructor({
    status,
    temperature = 0,
    humidity = 0,
    speed = 0,
    mode = "",
    CO2 = 0,
  }) {
    this.status = this.parseStatus(status);
    this.temperature = temperature;
    this.humidity = humidity;
    this.speed = speed;
    this.mode = mode;
    this.CO2 = CO2;
  }

  parseStatus(value) {
    if (typeof value === "boolean") return value;
    if (typeof value === "number") return value === 1;
    if (typeof value === "string") return value.toLowerCase() === "true";
    return false;
  }

  static fromObject(obj = {}) {
    return new DeviceStatus({
      status: obj.status,
      temperature: parseFloat(obj.temperature) || 0,
      humidity: parseFloat(obj.humidity) || 0,
      speed: parseFloat(obj.speed) || 0,
      mode: obj.mode || "",
      CO2: parseFloat(obj.CO2) || 0,
    });
  }

  toJSON() {
    return {
      status: this.status,
      temperature: this.temperature,
      humidity: this.humidity,
      speed: this.speed,
      mode: this.mode,
      CO2: this.CO2,
    };
  }
}
