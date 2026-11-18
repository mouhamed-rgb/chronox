import 'package:flutter_secure_storage/flutter_secure_storage.dart'; import 'package:shared_preferences/shared_preferences.dart';
class SettingsService {
 static const _secure=FlutterSecureStorage(); static SharedPreferences? _prefs; static String? _pin;
 static Future<void> init() async {_prefs=await SharedPreferences.getInstance();_pin=await _secure.read(key:'chronox_pin');}
 static bool get pinEnabled=>_prefs?.getBool('pin_enabled')??false;
 static Future<void> setPin(String pin) async {await _secure.write(key:'chronox_pin',value:pin);_pin=pin;await _prefs?.setBool('pin_enabled',true);}
 static Future<bool> verify(String pin) async=>_pin!=null&&_pin==pin;
 static Future<void> removePin() async {await _secure.delete(key:'chronox_pin');_pin=null;await _prefs?.setBool('pin_enabled',false);}
}