import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('my'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'OK Delivery - Merchant'**
  String get appTitle;

  /// Home navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Draft navigation label
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// Track navigation label
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Email field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Login error message
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginError;

  /// Registered packages stat label
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// Pending packages stat label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Delivered packages stat label
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Register package button text
  ///
  /// In en, this message translates to:
  /// **'Register Package'**
  String get registerPackage;

  /// Register package description
  ///
  /// In en, this message translates to:
  /// **'Create a new delivery package'**
  String get createNewDeliveryPackage;

  /// Draft packages screen title
  ///
  /// In en, this message translates to:
  /// **'Draft Packages'**
  String get draftPackages;

  /// Empty draft list message
  ///
  /// In en, this message translates to:
  /// **'No draft packages'**
  String get noDraftPackages;

  /// Error loading drafts message
  ///
  /// In en, this message translates to:
  /// **'Error loading drafts'**
  String get errorLoadingDrafts;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Package count text
  ///
  /// In en, this message translates to:
  /// **'package'**
  String packages(int count);

  /// No description provided for @packages_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} packages'**
  String packages_plural(Object count);

  /// Today date label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Yesterday date label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Track packages screen title
  ///
  /// In en, this message translates to:
  /// **'Track Packages'**
  String get trackPackages;

  /// Empty packages list message
  ///
  /// In en, this message translates to:
  /// **'No packages found'**
  String get noPackagesFound;

  /// Error loading packages message
  ///
  /// In en, this message translates to:
  /// **'Error loading packages'**
  String get errorLoadingPackages;

  /// Track live button text
  ///
  /// In en, this message translates to:
  /// **'Track Live'**
  String get trackLive;

  /// Track live button disabled message
  ///
  /// In en, this message translates to:
  /// **'Tracking available when package is on the way'**
  String get trackingAvailableWhenOnTheWay;

  /// Customer name field label
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// Customer phone field label
  ///
  /// In en, this message translates to:
  /// **'Customer Phone'**
  String get customerPhone;

  /// Delivery address field label
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// Payment type field label
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// Amount field label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Package description field label
  ///
  /// In en, this message translates to:
  /// **'Package Description (Optional)'**
  String get packageDescription;

  /// Take photo button text
  ///
  /// In en, this message translates to:
  /// **'Take Package Photo (Optional)'**
  String get takePackagePhoto;

  /// Add to list button text
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToList;

  /// Submit all button text
  ///
  /// In en, this message translates to:
  /// **'Submit All'**
  String get submitAll;

  /// Package list title
  ///
  /// In en, this message translates to:
  /// **'Package List'**
  String get packageList;

  /// Profile screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your account'**
  String get manageYourAccount;

  /// Shop owner role label
  ///
  /// In en, this message translates to:
  /// **'Shop Owner'**
  String get shopOwner;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Total stat label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Completed stat label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Shop information card title
  ///
  /// In en, this message translates to:
  /// **'Shop Information'**
  String get shopInformation;

  /// Shop name label
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// Phone number label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Location label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Notifications menu item
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Error loading profile message
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// Customer name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter customer name'**
  String get pleaseEnterCustomerName;

  /// Phone number validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// Delivery address validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter delivery address'**
  String get pleaseEnterDeliveryAddress;

  /// Amount validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// Prepaid payment type
  ///
  /// In en, this message translates to:
  /// **'Prepaid'**
  String get prepaid;

  /// COD payment type
  ///
  /// In en, this message translates to:
  /// **'COD'**
  String get cod;

  /// Package saved to draft success message
  ///
  /// In en, this message translates to:
  /// **'Package saved to draft'**
  String get packageSavedToDraft;

  /// Failed to save package error
  ///
  /// In en, this message translates to:
  /// **'Failed to save package to draft'**
  String get failedToSavePackage;

  /// Submit packages validation error
  ///
  /// In en, this message translates to:
  /// **'Please add at least one package'**
  String get pleaseAddAtLeastOnePackage;

  /// No valid draft packages error
  ///
  /// In en, this message translates to:
  /// **'No valid draft packages to submit'**
  String get noValidDraftPackages;

  /// Packages submitted success message
  ///
  /// In en, this message translates to:
  /// **'{count} package(s) submitted successfully'**
  String packagesSubmittedSuccessfully(int count);

  /// Packages failed message
  ///
  /// In en, this message translates to:
  /// **'{count} package(s) failed'**
  String packagesFailed(int count);

  /// Errors label
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// Package removed success message
  ///
  /// In en, this message translates to:
  /// **'Package removed from list'**
  String get packageRemovedFromList;

  /// Camera permission required message
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to take photos. Please grant permission in settings.'**
  String get cameraPermissionRequired;

  /// Error taking photo message
  ///
  /// In en, this message translates to:
  /// **'Error taking photo'**
  String get errorTakingPhoto;

  /// Registered date label
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registeredDate;

  /// Updated date label
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// Tracking code label
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Register all packages button text
  ///
  /// In en, this message translates to:
  /// **'Register All Packages'**
  String get registerAllPackages;

  /// No valid draft packages found error
  ///
  /// In en, this message translates to:
  /// **'No valid draft packages found'**
  String get noValidDraftPackagesFound;

  /// Draft package updated success message
  ///
  /// In en, this message translates to:
  /// **'Draft package updated successfully'**
  String get draftPackageUpdated;

  /// Draft package deleted success message
  ///
  /// In en, this message translates to:
  /// **'Draft package deleted successfully'**
  String get draftPackageDeleted;

  /// Edit draft screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Draft'**
  String get editDraft;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Remove image button text
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// Packages by registered date title
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get packagesRegisteredDate;

  /// No registered packages found message
  ///
  /// In en, this message translates to:
  /// **'No registered packages found'**
  String get noRegisteredPackagesFound;

  /// Package image preview title
  ///
  /// In en, this message translates to:
  /// **'Package Image Preview'**
  String get packageImagePreview;

  /// Failed to load image error
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// Extract customer info button text
  ///
  /// In en, this message translates to:
  /// **'Extract Customer Info'**
  String get extractCustomerInfo;

  /// AI extraction input hint
  ///
  /// In en, this message translates to:
  /// **'Enter customer information (name, phone, address)...'**
  String get enterCustomerInfo;

  /// Extracted customer info preview title
  ///
  /// In en, this message translates to:
  /// **'Extracted Customer Info (Review & Edit)'**
  String get extractedCustomerInfo;

  /// Confirm and fill form button text
  ///
  /// In en, this message translates to:
  /// **'Confirm & Fill Form'**
  String get confirmFillForm;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Extracting loading message
  ///
  /// In en, this message translates to:
  /// **'Extracting...'**
  String get extracting;

  /// Edit profile coming soon message
  ///
  /// In en, this message translates to:
  /// **'Edit profile feature coming soon'**
  String get editProfileFeatureComingSoon;

  /// Settings coming soon message
  ///
  /// In en, this message translates to:
  /// **'Settings feature coming soon'**
  String get settingsFeatureComingSoon;

  /// Notifications coming soon message
  ///
  /// In en, this message translates to:
  /// **'Notifications feature coming soon'**
  String get notificationsFeatureComingSoon;

  /// Submission result dialog title
  ///
  /// In en, this message translates to:
  /// **'Submission Result'**
  String get submissionResult;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// Valid email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// Contact support help text
  ///
  /// In en, this message translates to:
  /// **'Contact support if you need help accessing your account'**
  String get contactSupportHelp;

  /// App name
  ///
  /// In en, this message translates to:
  /// **'OK Delivery'**
  String get okDelivery;

  /// Merchant portal subtitle
  ///
  /// In en, this message translates to:
  /// **'Merchant Portal'**
  String get merchantPortal;

  /// Package saved to draft with count
  ///
  /// In en, this message translates to:
  /// **'Package saved to draft ({count} total)'**
  String packageSavedToDraftCount(int count);

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// System default language option
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// Language changed message
  ///
  /// In en, this message translates to:
  /// **'Language changed. Please restart the app to apply changes.'**
  String get languageChangedRestart;

  /// Language changed success message
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
