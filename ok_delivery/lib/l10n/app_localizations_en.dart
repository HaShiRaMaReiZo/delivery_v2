// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OK Delivery - Merchant';

  @override
  String get home => 'Home';

  @override
  String get draft => 'Draft';

  @override
  String get track => 'Track';

  @override
  String get profile => 'Profile';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get loginError => 'Login failed. Please check your credentials.';

  @override
  String get registered => 'Registered';

  @override
  String get pending => 'Pending';

  @override
  String get delivered => 'Delivered';

  @override
  String get registerPackage => 'Register Package';

  @override
  String get createNewDeliveryPackage => 'Create a new delivery package';

  @override
  String get draftPackages => 'Draft Packages';

  @override
  String get noDraftPackages => 'No draft packages';

  @override
  String get errorLoadingDrafts => 'Error loading drafts';

  @override
  String get retry => 'Retry';

  @override
  String packages(int count) {
    return 'package';
  }

  @override
  String packages_plural(Object count) {
    return '$count packages';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get trackPackages => 'Track Packages';

  @override
  String get noPackagesFound => 'No packages found';

  @override
  String get errorLoadingPackages => 'Error loading packages';

  @override
  String get trackLive => 'Track Live';

  @override
  String get trackingAvailableWhenOnTheWay =>
      'Tracking available when package is on the way';

  @override
  String get customerName => 'Customer Name';

  @override
  String get customerPhone => 'Customer Phone';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get paymentType => 'Payment Type';

  @override
  String get amount => 'Amount';

  @override
  String get packageDescription => 'Package Description (Optional)';

  @override
  String get takePackagePhoto => 'Take Package Photo (Optional)';

  @override
  String get addToList => 'Add to List';

  @override
  String get submitAll => 'Submit All';

  @override
  String get packageList => 'Package List';

  @override
  String get manageYourAccount => 'Manage your account';

  @override
  String get shopOwner => 'Shop Owner';

  @override
  String get edit => 'Edit';

  @override
  String get total => 'Total';

  @override
  String get completed => 'Completed';

  @override
  String get shopInformation => 'Shop Information';

  @override
  String get shopName => 'Shop Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get location => 'Location';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get refresh => 'Refresh';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get pleaseEnterCustomerName => 'Please enter customer name';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter phone number';

  @override
  String get pleaseEnterDeliveryAddress => 'Please enter delivery address';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';

  @override
  String get prepaid => 'Prepaid';

  @override
  String get cod => 'COD';

  @override
  String get packageSavedToDraft => 'Package saved to draft';

  @override
  String get failedToSavePackage => 'Failed to save package to draft';

  @override
  String get pleaseAddAtLeastOnePackage => 'Please add at least one package';

  @override
  String get noValidDraftPackages => 'No valid draft packages to submit';

  @override
  String packagesSubmittedSuccessfully(int count) {
    return '$count package(s) submitted successfully';
  }

  @override
  String packagesFailed(int count) {
    return '$count package(s) failed';
  }

  @override
  String get errors => 'Errors';

  @override
  String get packageRemovedFromList => 'Package removed from list';

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required to take photos. Please grant permission in settings.';

  @override
  String get errorTakingPhoto => 'Error taking photo';

  @override
  String get registeredDate => 'Registered';

  @override
  String get updated => 'Updated';

  @override
  String get tracking => 'Tracking';

  @override
  String get delete => 'Delete';

  @override
  String get registerAllPackages => 'Register All Packages';

  @override
  String get noValidDraftPackagesFound => 'No valid draft packages found';

  @override
  String get draftPackageUpdated => 'Draft package updated successfully';

  @override
  String get draftPackageDeleted => 'Draft package deleted successfully';

  @override
  String get editDraft => 'Edit Draft';

  @override
  String get save => 'Save';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get packagesRegisteredDate => 'Packages';

  @override
  String get noRegisteredPackagesFound => 'No registered packages found';

  @override
  String get packageImagePreview => 'Package Image Preview';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get extractCustomerInfo => 'Extract Customer Info';

  @override
  String get enterCustomerInfo =>
      'Enter customer information (name, phone, address)...';

  @override
  String get extractedCustomerInfo => 'Extracted Customer Info (Review & Edit)';

  @override
  String get confirmFillForm => 'Confirm & Fill Form';

  @override
  String get cancel => 'Cancel';

  @override
  String get extracting => 'Extracting...';

  @override
  String get editProfileFeatureComingSoon => 'Edit profile feature coming soon';

  @override
  String get settingsFeatureComingSoon => 'Settings feature coming soon';

  @override
  String get notificationsFeatureComingSoon =>
      'Notifications feature coming soon';

  @override
  String get submissionResult => 'Submission Result';

  @override
  String get ok => 'OK';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterYourPassword => 'Please enter your password';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Password must be at least 6 characters';

  @override
  String get contactSupportHelp =>
      'Contact support if you need help accessing your account';

  @override
  String get okDelivery => 'OK Delivery';

  @override
  String get merchantPortal => 'Merchant Portal';

  @override
  String packageSavedToDraftCount(int count) {
    return 'Package saved to draft ($count total)';
  }

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get languageChangedRestart =>
      'Language changed. Please restart the app to apply changes.';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get yes => 'Yes';
}
