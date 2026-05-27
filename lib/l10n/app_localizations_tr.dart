// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Explore Index';

  @override
  String get worldExplored => 'Dünya Keşfi';

  @override
  String get continueDiscovery => 'Keşfe Devam Et';

  @override
  String get recentDiscoveries => 'Son Keşifler';

  @override
  String get nextCityWorthRevisiting => 'Tekrar Ziyaret Edilmesi Gereken Şehir';

  @override
  String get yourTravelMap => 'Seyahat Haritanız';

  @override
  String get countriesExplored => 'Keşfedilen Ülkeler';

  @override
  String get citiesVisited => 'Ziyaret Edilen Şehirler';

  @override
  String get placesVerified => 'Doğrulanmış Yerler';

  @override
  String get discoveryProgress => 'Keşif İlerlemesi';

  @override
  String get topCity => 'En İyi Şehir';

  @override
  String exploreCountry(String country) {
    return '$country\'yi Keşfet';
  }

  @override
  String get cityDiscovery => 'Şehir Keşfi';

  @override
  String get worthVisitingAgain => 'Tekrar ziyaret etmeye değer mi?';

  @override
  String get yes => 'EVET';

  @override
  String get no => 'HAYIR';

  @override
  String youStillHave(int percent) {
    return 'Hâlâ %$percent keşfedilmemiş.';
  }

  @override
  String get missingCategories => 'Eksik kategoriler';

  @override
  String get createSecondTripPlan => 'İkinci Gezi Planı Oluştur';

  @override
  String get viewAllEvents => 'Tüm Etkinlikleri Gör';

  @override
  String eventsIn(String city) {
    return '$city\'deki Etkinlikler';
  }

  @override
  String get onlyThisWeek => 'Sadece bu hafta';

  @override
  String get verifyYourVisit => 'Ziyaretinizi Doğrulayın';

  @override
  String get uploadPhoto => 'Fotoğraf yükle';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get giveRating => 'Puan ver';

  @override
  String get optionalNote => 'İsteğe bağlı not';

  @override
  String get leaveNote => 'Deneyiminiz hakkında bir not bırakın...';

  @override
  String get visitDate => 'Ziyaret tarihi';

  @override
  String get completeVisit => 'Ziyareti Tamamla';

  @override
  String visitBoostHint(String city, double boost) {
    return 'Ziyaretiniz $city keşfini +%$boost artıracak';
  }

  @override
  String get verificationFailed => 'Doğrulama başarısız';

  @override
  String get verificationPassed => 'Ziyaret başarıyla doğrulandı!';

  @override
  String get errorNoExif => 'Fotoğrafta EXIF verisi bulunamadı.';

  @override
  String get errorNoGps => 'Fotoğraf GPS konumu içermiyor.';

  @override
  String get errorNoDate => 'Fotoğraf tarih içermiyor.';

  @override
  String errorTooFar(int distance) {
    return 'Fotoğraf bu konumdan çok uzakta çekilmiş (${distance}m).';
  }

  @override
  String get errorOldPhoto => 'Fotoğraf 14 günden eski.';

  @override
  String get yourDiscoveryDna => 'Keşif DNA\'nız';

  @override
  String get travelStyleCategories => 'Kategorilere göre seyahat tarzınız';

  @override
  String get categories => 'Kategoriler';

  @override
  String get historicalPlaces => 'Tarihi Mekanlar';

  @override
  String get foodRestaurants => 'Yemek & Restoranlar';

  @override
  String get cafes => 'Kafeler';

  @override
  String get museumsArt => 'Müzeler & Sanat';

  @override
  String get routes => 'Güzergahlar';

  @override
  String get nature => 'Doğa';

  @override
  String get nightlife => 'Gece Hayatı';

  @override
  String get localMarkets => 'Yerel Pazarlar';

  @override
  String get hiddenGems => 'Gizli Noktalar';

  @override
  String get events => 'Etkinlikler';

  @override
  String get completed => 'Tamamlandı';

  @override
  String get notVerified => 'Doğrulanmadı';

  @override
  String get verified => 'Doğrulandı';

  @override
  String get all => 'Tümü';

  @override
  String get mustVisit => 'Mutlaka Görün';

  @override
  String get hidden => 'Gizli';

  @override
  String get local => 'Yerel';

  @override
  String level(int number) {
    return 'Seviye $number';
  }

  @override
  String xpProgress(int current, int max) {
    return '$current / $max XP';
  }

  @override
  String get badges => 'Rozetler';

  @override
  String get yourStats => 'İstatistikleriniz';

  @override
  String get mostExploredCountry => 'En çok keşfedilen ülke';

  @override
  String get mostCompletedCity => 'En çok tamamlanan şehir';

  @override
  String get favoriteCategory => 'Favori kategori';

  @override
  String get citiesExplored => 'Keşfedilen Şehirler';

  @override
  String get totalActivities => 'Toplam Aktivite';

  @override
  String get verifiedPhotos => 'Doğrulanmış Fotoğraflar';

  @override
  String get averageRating => 'Ortalama Puan';

  @override
  String get seeAllCities => 'Tüm Şehirleri Gör';

  @override
  String get locked => 'Kilitli';

  @override
  String get today => 'Bugün';

  @override
  String shouldVisitAgain(String city) {
    return '$city\'e tekrar gitmeli misiniz?';
  }
}
