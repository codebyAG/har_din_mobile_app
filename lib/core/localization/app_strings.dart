/// APP-CHANGES-01 §2 — every visible label comes from the server's
/// `strings` map now, keyed the same across `hi`/`en`/`mr`. This bundled
/// copy (today's Hindi) is the fallback, never the source of truth: it
/// covers a first launch with no network, or a key the server has that
/// an old build doesn't yet know to ask for.
class AppStrings {
  AppStrings._();

  static const Map<String, String> bundled = {
    'home.upcoming_festivals': 'आने वाले त्योहार',
    'home.today': 'आज',
    'home.band.morning': 'सुप्रभात के लिए',
    'home.band.afternoon': 'दोपहर के लिए',
    'home.band.evening': 'शाम के लिए',
    'home.band.night': 'शुभ रात्रि के लिए',
    'home.band.default': 'अभी के लिए',
    'home.no_categories': 'अभी कोई श्रेणी उपलब्ध नहीं है',
    'home.load_failed': 'कंटेंट लोड नहीं हो पाया। कृपया इंटरनेट जाँचें।',
    'nav.home': 'होम',
    'nav.festivals': 'त्योहार',
    'nav.creations': 'मेरी क्रिएशन्स',
    'nav.profile': 'प्रोफाइल',
    'festival.days_left': '{n} दिन बाकी',
    'festival.today': 'आज है',
    'common.coming_soon': 'जल्द आ रहा है',
    'common.retry': 'फिर से कोशिश करें',
    'common.loading': 'लोड हो रहा है...',
    'settings.account_soon': 'अकाउंट सेटिंग जल्द आ रही है',
    'settings.privacy_soon': 'प्राइवेसी सेटिंग जल्द आ रही है',
    'settings.notifications_soon': 'नोटिफिकेशन सेटिंग जल्द आ रही है',
    'settings.help_soon': 'सहायता जल्द आ रही है',
  };

  /// Looks a key up in the server's strings first, then the bundled
  /// fallback, then the key itself (so a typo is visible, not blank).
  /// `{n}`-style placeholders in [args] are substituted after lookup.
  static String resolve(
    Map<String, String>? serverStrings,
    String key, [
    Map<String, String>? args,
  ]) {
    var value = serverStrings?[key] ?? bundled[key] ?? key;
    args?.forEach((k, v) => value = value.replaceAll('{$k}', v));
    return value;
  }
}
