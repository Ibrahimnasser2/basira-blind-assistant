class AppConstants {
  static const String appName = 'BASIRA AI';
  static const String defaultGeminiModel = 'gemini-1.5-flash';
  static const String currencyModelAsset = 'assets/models/egp_currency.tflite';
  static const String currencyLabelsAsset = 'assets/labels/egp_labels.txt';

  static const List<String> egpLabels = [
    '5 EGP',
    '10 EGP',
    '20 EGP',
    '50 EGP',
    '100 EGP',
    '200 EGP',
  ];

  static const String scenePromptAr =
      'صف المشهد الحالي بشكل مختصر ومفيد لشخص كفيف، واذكر العوائق والمسارات الآمنة.';
}
