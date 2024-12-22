
import 'dart:math' as math;
class MapsService {
  static Future<Duration?> getEstimatedTravelTime(String origin, String destination) async {
    // Use actual coordinates from your nablusCoordinates map
    final Map<String, Map<String, double>> coordinates = {
      'راس العين': {'latitude': 32.2230, 'longitude': 35.2590},
      'شركة الكهرباء': {'latitude': 32.2220, 'longitude': 35.2544},
      'التعاون الاوسط': {'latitude': 32.2238, 'longitude': 35.2631},
      'شارع 24': {'latitude': 32.2230, 'longitude': 35.2570},
      'العامرية': {'latitude': 32.2235, 'longitude': 35.2585},
      'حي طيبة': {'latitude': 32.2240, 'longitude': 35.2595},
      'التعاون العلوي': {'latitude': 32.2242, 'longitude': 35.2625},
      'كروم عاشور': {'latitude': 32.2228, 'longitude': 35.2575},
      'شارع 10': {'latitude': 32.2233, 'longitude': 35.2580},
      'حات العامود': {'latitude': 32.2227, 'longitude': 35.2595},
      'مستشفى الهلال الاحمر': {'latitude': 32.2225, 'longitude': 35.2565},
      'نابلس الجديدة': {'latitude': 32.2245, 'longitude': 35.2600},
      'شارع الطور': {'latitude': 32.2250, 'longitude': 35.2610},
      'شارع الحرش': {'latitude': 32.2255, 'longitude': 35.2620},
      'اسكان الكهرباء': {'latitude': 32.2218, 'longitude': 35.2542},
      'شارع كشيكة': {'latitude': 32.2235, 'longitude': 35.2605},
      'شارع المعري': {'latitude': 32.2240, 'longitude': 35.2615},
      'مستشفى الامل': {'latitude': 32.2230, 'longitude': 35.2550},
      'الطور': {'latitude': 32.2248, 'longitude': 35.2608},
      'جبل الطور': {'latitude': 32.2252, 'longitude': 35.2612},
      'عراق بورين': {'latitude': 32.1965, 'longitude': 35.2030},
      'شارع تل': {'latitude': 32.2225, 'longitude': 35.2575},
      'شارع ابو عبيدة': {'latitude': 32.2235, 'longitude': 35.2585},
      'حي النور': {'latitude': 32.2245, 'longitude': 35.2595},
      'شارع المأمون': {'latitude': 32.2230, 'longitude': 35.2580},
      'طلعة علاء الدين': {'latitude': 32.2240, 'longitude': 35.2590},
      'شارع الجرف': {'latitude': 32.2235, 'longitude': 35.2600},
      'نقابة الاتصالات': {'latitude': 32.2225, 'longitude': 35.2570},
      'مفرق البدوي': {'latitude': 32.2215, 'longitude': 35.2560},
      'شارع تونس': {'latitude': 32.2230, 'longitude': 35.2585},
      'طلعة بليبلة': {'latitude': 32.2245, 'longitude': 35.2605},
      'مستشفى رفيديا': {'latitude': 32.2236, 'longitude': 35.2335},
      'الجامعة القديمة': {'latitude': 32.2230, 'longitude': 35.2413},
      'المخفية': {'latitude': 32.2245, 'longitude': 35.2420},
      'المستشفى التخصصي': {'latitude': 32.2238, 'longitude': 35.2340},
      'اسكان المهندسين-رفيديا': {'latitude': 32.2242, 'longitude': 35.2338},
      'شارع النجاح': {'latitude': 32.2235, 'longitude': 35.2375},
      'ضاحية النخيل': {'latitude': 32.2250, 'longitude': 35.2380},
      'اسكان البيدر': {'latitude': 32.2240, 'longitude': 35.2385},
      'عين الصبيان': {'latitude': 32.2230, 'longitude': 35.2390},
      'دخلة ملحيس': {'latitude': 32.2235, 'longitude': 35.2395},
      'شارع كمال جنبلاط': {'latitude': 32.2240, 'longitude': 35.2400},
      'شارع المريج': {'latitude': 32.2245, 'longitude': 35.2405},
      'شارع يافا': {'latitude': 32.2220, 'longitude': 35.2610},
      'شارع 16': {'latitude': 32.2225, 'longitude': 35.2615},
      'شارع 17': {'latitude': 32.2230, 'longitude': 35.2620},
      'شارع 15': {'latitude': 32.2235, 'longitude': 35.2625},
      'شارع عمان': {'latitude': 32.21547, 'longitude': 35.27505},
      'عبد الرحيم محمود': {'latitude': 32.2245, 'longitude': 35.2635},
      'اسعاد الطفولة': {'latitude': 32.2250, 'longitude': 35.2640},
      'شارع جمال عبد الناصر': {'latitude': 32.2215, 'longitude': 35.2645},
      'المقاطعة': {'latitude': 32.2220, 'longitude': 35.2650},
      'عراق التايه': {'latitude': 32.2225, 'longitude': 35.2655},
      'كلية الروضة': {'latitude': 32.2230, 'longitude': 35.2660},
      'طلعة الماطورات': {'latitude': 32.2235, 'longitude': 35.2665},
      'بلاطة البلد': {'latitude': 32.2205, 'longitude': 35.2855},
      'عسكر البلد': {'latitude': 32.2195, 'longitude': 35.2890},
      'مخيم عسكر القديم': {'latitude': 32.2190, 'longitude': 35.2885},
      'المسلخ': {'latitude': 32.2200, 'longitude': 35.2880},
      'عسكر الجديد': {'latitude': 32.2185, 'longitude': 35.2895},
      'دوار الفارس': {'latitude': 32.2210, 'longitude': 35.2640},
      'دوار الحسبة': {'latitude': 32.2215, 'longitude': 35.2645},
      'شارع القدس': {'latitude': 32.2210, 'longitude': 35.2585},
      'اسكان روجيب': {'latitude': 32.2280, 'longitude': 35.2950},
      'المنطقة الصناعية روجيب': {'latitude': 32.2285, 'longitude': 35.2955},
      'السوق الشرقي': {'latitude': 32.2220, 'longitude': 35.2620},
      'كفر قليل': {'latitude': 32.2150, 'longitude': 35.2870},
      'شارع حلاوة': {'latitude': 32.2225, 'longitude': 35.2625},
      'المساكن': {'latitude': 32.2230, 'longitude': 35.2630},
      'طلعة الزينبيه': {'latitude': 32.2235, 'longitude': 35.2635},
      'شارع سعد صايل': {'latitude': 32.2240, 'longitude': 35.2640},
      'جسر التيتي': {'latitude': 32.2245, 'longitude': 35.2645},
      'الاسكان النمساوي': {'latitude': 32.2250, 'longitude': 35.2650},
      'مستشفى الاتحاد': {'latitude': 32.2234, 'longitude': 35.2338},
      'مستشفى النجاح': {'latitude': 32.2232, 'longitude': 35.2440},
      'خلة الايمان': {'latitude': 32.2260, 'longitude': 35.2660},
      'شارع ابن رشد': {'latitude': 32.2265, 'longitude': 35.2665},
      'شارع عصيرة': {'latitude': 32.2270, 'longitude': 35.2670},
      'شارع مؤته': {'latitude': 32.2275, 'longitude': 35.2675},
      'شارع الحجة عفيفة': {'latitude': 32.2280, 'longitude': 35.2680},
      'طلعة اسو': {'latitude': 32.2285, 'longitude': 35.2685},
      'شارع الرشيد': {'latitude': 32.2290, 'longitude': 35.2690},
      'فطاير جبل فطاير': {'latitude': 32.2295, 'longitude': 35.2695},
      'شارع بيجر': {'latitude': 32.2300, 'longitude': 35.2700},
      'شارع ابو بكر': {'latitude': 32.2305, 'longitude': 35.2705},
      'شارع المنجرة': {'latitude': 32.2310, 'longitude': 35.2710},
      'سما نابلس': {'latitude': 32.2315, 'longitude': 35.2715},
      'طلعة عماد الدين': {'latitude': 32.2320, 'longitude': 35.2720},
      'عصيرة الشمالية': {'latitude': 32.2505, 'longitude': 35.2870},
      'طلعة زبلح': {'latitude': 32.2330, 'longitude': 35.2730},
      'واد التفاح': {'latitude': 32.2335, 'longitude': 35.2735},
      'مفرق زواتا': {'latitude': 32.2392, 'longitude': 35.2292},
      'بيت ايبا': {'latitude': 32.2290, 'longitude': 35.2145},
      'زواتا': {'latitude': 32.2397, 'longitude': 35.2297},
      'مخيم العين': {'latitude': 32.2345, 'longitude': 35.2745},
      'الجنيد': {'latitude': 32.2290, 'longitude': 35.2150},
      'بيت وزن': {'latitude': 32.2286, 'longitude': 35.2139},
      'صرة': {'latitude': 32.2355, 'longitude': 35.2755},
      'حي المسك': {'latitude': 32.2360, 'longitude': 35.2760},
      'دير شرف': {'latitude': 32.2365, 'longitude': 35.2765},
      'منتجع مارينا': {'latitude': 32.2370, 'longitude': 35.2770},
      'منتزه البلدية': {'latitude': 32.2375, 'longitude': 35.2775},
      'وسط البلد': {'latitude': 32.2225, 'longitude': 35.2605},
      'منتزه العائلات': {'latitude': 32.2385, 'longitude': 35.2785},
      'شارع المدارس': {'latitude': 32.2390, 'longitude': 35.2790},
      'شارع البساتين': {'latitude': 32.2395, 'longitude': 35.2795},
      'شارع فيصل': {'latitude': 32.2225, 'longitude': 35.2615},
      'شارع شويتره': {'latitude': 32.2405, 'longitude': 35.2805},
      'حواره': {'latitude': 32.1525, 'longitude': 35.2561},
      'النصاريه': {'latitude': 32.2415, 'longitude': 35.2815},
      'عقربا': {'latitude': 32.1245, 'longitude': 35.3445},
      'بورين': {'latitude': 32.1961, 'longitude': 35.2026},
      'تياسير': {'latitude': 32.3228, 'longitude': 35.3870},
      'جيوس': {'latitude': 32.1922, 'longitude': 35.0875}
    };
    if (!coordinates.containsKey(origin.trim()) || !coordinates.containsKey(destination.trim())) {
      return null;
    }

    var originCoords = coordinates[origin.trim()]!;
    var destCoords = coordinates[destination.trim()]!;

    // Calculate using actual distance and average speed
    double distance = calculateDistance(
        originCoords['latitude']!,
        originCoords['longitude']!,
        destCoords['latitude']!,
        destCoords['longitude']!
    );

    // Assuming average speed of 40 km/h in city
    int minutes = (distance / 40 * 60).round();
    return Duration(minutes: minutes);
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * math.pi / 180;
  }
}
