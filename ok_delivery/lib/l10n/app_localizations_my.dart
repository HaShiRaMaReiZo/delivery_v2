// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get appTitle => 'OK Delivery - ကုန်သည်ဆိုင်ရာ';

  @override
  String get home => 'ပင်မစာမျက်နှာ';

  @override
  String get draft => 'မူကြမ်း';

  @override
  String get track => 'ခြေရာခံ';

  @override
  String get profile => 'ကိုယ်ရေးအချက်အလက်';

  @override
  String get login => 'ဝင်ရောက်ရန်';

  @override
  String get email => 'အီးမေးလ်';

  @override
  String get password => 'စကားဝှက်';

  @override
  String get enterEmail => 'သင့်အီးမေးလ်ကို ထည့်သွင်းပါ';

  @override
  String get enterPassword => 'သင့်စကားဝှက်ကို ထည့်သွင်းပါ';

  @override
  String get loginError =>
      'ဝင်ရောက်မှု မအောင်မြင်ပါ။ သင့်အထောက်အထားများကို စစ်ဆေးပါ။';

  @override
  String get registered => 'မှတ်ပုံတင်ထား';

  @override
  String get pending => 'စောင့်ဆိုင်းနေသည်';

  @override
  String get delivered => 'ပို့ဆောင်ပြီး';

  @override
  String get registerPackage => 'ပက်ကေ့ချ်မှတ်ပုံတင်ရန်';

  @override
  String get createNewDeliveryPackage => 'ပို့ဆောင်မှုပက်ကေ့ချ်အသစ် ဖန်တီးရန်';

  @override
  String get draftPackages => 'မူကြမ်းပက်ကေ့ချ်များ';

  @override
  String get noDraftPackages => 'မူကြမ်းပက်ကေ့ချ်မရှိပါ';

  @override
  String get errorLoadingDrafts => 'မူကြမ်းများ ဖွင့်ရာတွင် အမှားအယွင်းရှိသည်';

  @override
  String get retry => 'ပြန်လည်ကြိုးစားရန်';

  @override
  String packages(int count) {
    return 'ပက်ကေ့ချ်';
  }

  @override
  String packages_plural(Object count) {
    return '$count ပက်ကေ့ချ်များ';
  }

  @override
  String get today => 'ယနေ့';

  @override
  String get yesterday => 'မနေ့က';

  @override
  String get trackPackages => 'ပက်ကေ့ချ်များ ခြေရာခံရန်';

  @override
  String get noPackagesFound => 'ပက်ကေ့ချ်များ မတွေ့ရှိပါ';

  @override
  String get errorLoadingPackages =>
      'ပက်ကေ့ချ်များ ဖွင့်ရာတွင် အမှားအယွင်းရှိသည်';

  @override
  String get trackLive => 'တိုက်ရိုက်ခြေရာခံ';

  @override
  String get trackingAvailableWhenOnTheWay =>
      'ပက်ကေ့ချ်သည် လမ်းတွင်ရှိသောအခါ ခြေရာခံနိုင်သည်';

  @override
  String get customerName => 'ဖောက်သည်အမည်';

  @override
  String get customerPhone => 'ဖောက်သည်ဖုန်းနံပါတ်';

  @override
  String get deliveryAddress => 'ပို့ဆောင်ရမည့်လိပ်စာ';

  @override
  String get paymentType => 'ငွေပေးချေမှုအမျိုးအစား';

  @override
  String get amount => 'ပမာဏ';

  @override
  String get packageDescription => 'ပက်ကေ့ချ်ဖော်ပြချက် (ရွေးချယ်ရန်)';

  @override
  String get takePackagePhoto => 'ပက်ကေ့ချ်ဓာတ်ပုံရိုက်ရန် (ရွေးချယ်ရန်)';

  @override
  String get addToList => 'စာရင်းထည့်ရန်';

  @override
  String get submitAll => 'အားလုံးတင်သွင်းရန်';

  @override
  String get packageList => 'ပက်ကေ့ချ်စာရင်း';

  @override
  String get manageYourAccount => 'သင့်အကောင့်ကို စီမံခန့်ခွဲရန်';

  @override
  String get shopOwner => 'ဆိုင်ပိုင်ရှင်';

  @override
  String get edit => 'တည်းဖြတ်ရန်';

  @override
  String get total => 'စုစုပေါင်း';

  @override
  String get completed => 'ပြီးစီးပြီး';

  @override
  String get shopInformation => 'ဆိုင်အချက်အလက်';

  @override
  String get shopName => 'ဆိုင်အမည်';

  @override
  String get phoneNumber => 'ဖုန်းနံပါတ်';

  @override
  String get location => 'တည်နေရာ';

  @override
  String get settings => 'ဆက်တင်များ';

  @override
  String get notifications => 'အကြောင်းကြားချက်များ';

  @override
  String get refresh => 'ပြန်လည်စတင်ရန်';

  @override
  String get errorLoadingProfile =>
      'ကိုယ်ရေးအချက်အလက် ဖွင့်ရာတွင် အမှားအယွင်းရှိသည်';

  @override
  String get pleaseEnterCustomerName => 'ဖောက်သည်အမည်ကို ထည့်သွင်းပါ';

  @override
  String get pleaseEnterPhoneNumber => 'ဖုန်းနံပါတ်ကို ထည့်သွင်းပါ';

  @override
  String get pleaseEnterDeliveryAddress =>
      'ပို့ဆောင်ရမည့်လိပ်စာကို ထည့်သွင်းပါ';

  @override
  String get pleaseEnterValidAmount => 'တရားဝင်ပမာဏကို ထည့်သွင်းပါ';

  @override
  String get prepaid => 'ကြိုတင်ပေးချေ';

  @override
  String get cod => 'ပို့ဆောင်ရာတွင် ငွေပေးချေ';

  @override
  String get packageSavedToDraft =>
      'ပက်ကေ့ချ်ကို မူကြမ်းသို့ သိမ်းဆည်းပြီးပါပြီ';

  @override
  String get failedToSavePackage =>
      'ပက်ကေ့ချ်ကို မူကြမ်းသို့ သိမ်းဆည်းရာတွင် မအောင်မြင်ပါ';

  @override
  String get pleaseAddAtLeastOnePackage =>
      'အနည်းဆုံး ပက်ကေ့ချ်တစ်ခု ထည့်သွင်းပါ';

  @override
  String get noValidDraftPackages =>
      'တင်သွင်းရန် တရားဝင်မူကြမ်းပက်ကေ့ချ်များ မရှိပါ';

  @override
  String packagesSubmittedSuccessfully(int count) {
    return 'ပက်ကေ့ချ် $count ခု အောင်မြင်စွာ တင်သွင်းပြီးပါပြီ';
  }

  @override
  String packagesFailed(int count) {
    return 'ပက်ကေ့ချ် $count ခု မအောင်မြင်ပါ';
  }

  @override
  String get errors => 'အမှားအယွင်းများ';

  @override
  String get packageRemovedFromList => 'ပက်ကေ့ချ်ကို စာရင်းမှ ဖယ်ရှားပြီးပါပြီ';

  @override
  String get cameraPermissionRequired =>
      'ဓာတ်ပုံရိုက်ရန် ကင်မရာခွင့်ပြုချက် လိုအပ်ပါသည်။ ဆက်တင်များတွင် ခွင့်ပြုချက်ပေးပါ။';

  @override
  String get errorTakingPhoto => 'ဓာတ်ပုံရိုက်ရာတွင် အမှားအယွင်းရှိသည်';

  @override
  String get registeredDate => 'မှတ်ပုံတင်ထား';

  @override
  String get updated => 'အပ်ဒိတ်လုပ်ထား';

  @override
  String get tracking => 'ခြေရာခံ';

  @override
  String get delete => 'ဖျက်ရန်';

  @override
  String get registerAllPackages => 'ပက်ကေ့ချ်အားလုံး မှတ်ပုံတင်ရန်';

  @override
  String get noValidDraftPackagesFound =>
      'တရားဝင်မူကြမ်းပက်ကေ့ချ်များ မတွေ့ရှိပါ';

  @override
  String get draftPackageUpdated =>
      'မူကြမ်းပက်ကေ့ချ် အောင်မြင်စွာ အပ်ဒိတ်လုပ်ပြီးပါပြီ';

  @override
  String get draftPackageDeleted =>
      'မူကြမ်းပက်ကေ့ချ် အောင်မြင်စွာ ဖျက်လိုက်ပါပြီ';

  @override
  String get editDraft => 'မူကြမ်းတည်းဖြတ်ရန်';

  @override
  String get save => 'သိမ်းဆည်းရန်';

  @override
  String get removeImage => 'ပုံကို ဖယ်ရှားရန်';

  @override
  String get packagesRegisteredDate => 'ပက်ကေ့ချ်များ';

  @override
  String get noRegisteredPackagesFound =>
      'မှတ်ပုံတင်ထားသော ပက်ကေ့ချ်များ မတွေ့ရှိပါ';

  @override
  String get packageImagePreview => 'ပက်ကေ့ချ်ပုံ အစမ်းကြည့်ရန်';

  @override
  String get failedToLoadImage => 'ပုံကို ဖွင့်ရာတွင် အမှားအယွင်းရှိသည်';

  @override
  String get extractCustomerInfo => 'ဖောက်သည်အချက်အလက် ထုတ်ယူရန်';

  @override
  String get enterCustomerInfo =>
      'ဖောက်သည်အချက်အလက် (အမည်၊ ဖုန်း၊ လိပ်စာ) ထည့်သွင်းပါ...';

  @override
  String get extractedCustomerInfo =>
      'ထုတ်ယူထားသော ဖောက်သည်အချက်အလက် (ပြန်လည်စစ်ဆေးပြီး တည်းဖြတ်ရန်)';

  @override
  String get confirmFillForm => 'အတည်ပြုပြီး ဖောင်ကို ဖြည့်ရန်';

  @override
  String get cancel => 'ပယ်ဖျက်ရန်';

  @override
  String get extracting => 'ထုတ်ယူနေသည်...';

  @override
  String get editProfileFeatureComingSoon =>
      'ကိုယ်ရေးအချက်အလက် တည်းဖြတ်ရန် အင်္ဂါရပ် မကြာမီ ရရှိပါမည်';

  @override
  String get settingsFeatureComingSoon =>
      'ဆက်တင်များ အင်္ဂါရပ် မကြာမီ ရရှိပါမည်';

  @override
  String get notificationsFeatureComingSoon =>
      'အကြောင်းကြားချက်များ အင်္ဂါရပ် မကြာမီ ရရှိပါမည်';

  @override
  String get submissionResult => 'တင်သွင်းမှု ရလဒ်';

  @override
  String get ok => 'အိုကေ';

  @override
  String get pleaseEnterYourEmail => 'သင့်အီးမေးလ်ကို ထည့်သွင်းပါ';

  @override
  String get pleaseEnterValidEmail => 'တရားဝင်အီးမေးလ်ကို ထည့်သွင်းပါ';

  @override
  String get pleaseEnterYourPassword => 'သင့်စကားဝှက်ကို ထည့်သွင်းပါ';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'စကားဝှက်သည် အနည်းဆုံး စာလုံး ၆ လုံး ရှိရမည်';

  @override
  String get contactSupportHelp =>
      'သင့်အကောင့်ကို ဝင်ရောက်ရာတွင် အကူအညီလိုအပ်ပါက ထောက်ပံ့မှုကို ဆက်သွယ်ပါ';

  @override
  String get okDelivery => 'OK Delivery';

  @override
  String get merchantPortal => 'ကုန်သည်ပေါ်တယ်';

  @override
  String packageSavedToDraftCount(int count) {
    return 'ပက်ကေ့ချ်ကို မူကြမ်းသို့ သိမ်းဆည်းပြီးပါပြီ (စုစုပေါင်း $count)';
  }

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get systemDefault => 'စနစ်ပုံမှန်';

  @override
  String get languageChangedRestart =>
      'ဘာသာစကား ပြောင်းလဲပြီးပါပြီ။ ပြောင်းလဲမှုများကို အသုံးပြုရန် အက်ပ်ကို ပြန်လည်စတင်ပါ။';

  @override
  String get languageChanged => 'ဘာသာစကား အောင်မြင်စွာ ပြောင်းလဲပြီးပါပြီ';

  @override
  String get logout => 'ထွက်ရန်';

  @override
  String get logoutConfirmation => 'သင်ထွက်ရန် သေချာပါသလား?';

  @override
  String get yes => 'ဟုတ်ကဲ့';
}
