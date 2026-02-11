import 'package:cloud_functions/cloud_functions.dart';

class DemoDataService {
  static Future<Map<String, dynamic>> seed() async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'seedDemoData',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    final result = await callable.call();
    final data = result.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const {'ok': true};
  }
}
