
import 'package:iot_smarthome/Pages/Home/HomePage.dart';


typedef Constructor<T> = T Function();

final Map<String, Constructor<Object>> _constructors = <String, Constructor<Object>>{};

void register<T>(Constructor<T> constructor) {
  _constructors[T.toString()] = constructor as Constructor<Object>;
}

class ClassBuilder {
  static void registerClasses() {
    register<HomePageContent>(() => HomePageContent());
    // register<Profile>(() => Profile());
    // register<Notifications>(() => Notifications());
    // register<Stats>(() => Stats());
    // register<Schedules>(() => Schedules());
    // register<Settings>(() => Settings());
  }

  static dynamic fromString(String type) {
    return _constructors[type]?.call();
  }
}