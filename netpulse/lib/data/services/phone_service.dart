import 'package:sim_card_info/sim_card_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sim_card_info/sim_info.dart';

class PhoneService {
  SimInfo? _simInfo;

  Future<bool> requestPhonePermission() async {
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }

  Future<SimInfo?> getSimInfo() async {
    try {
      final hasPermission = await requestPhonePermission();
      if (!hasPermission) {
        print('Phone permission denied');
        return null;
      }

      final _simCardInfoPlugin = SimCardInfo();

      final simInfoList = await _simCardInfoPlugin.getSimInfo() ?? []; // Correct static method
      if (simInfoList.isEmpty) {
        print('No SIM cards found');
        return null;
      }

      _simInfo = simInfoList.first; // Use the first SIM card
      await _saveSimInfo(_simInfo);
      return _simInfo;
    } catch (e) {
      print('Error getting SIM info: $e');
      return null;
    }
  }

  Future<SimInfo?> getLastKnownSimInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final carrierName = prefs.getString('last_carrier_name'); // Use carrierName

    if (carrierName != null) {
      // Since we can't instantiate SimCardInfo, fetch fresh data
      return await getSimInfo();
    }
    return await getSimInfo();
  }

  Future<void> _saveSimInfo(SimInfo? simInfo) async {
    if (simInfo == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_carrier_name', simInfo.carrierName);
  }
}