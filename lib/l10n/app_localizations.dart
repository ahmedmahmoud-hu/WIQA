import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to '**
  String get welcomeTo;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'WIQA'**
  String get appName;

  /// No description provided for @detect.
  ///
  /// In en, this message translates to:
  /// **'Detect.'**
  String get detect;

  /// No description provided for @protect.
  ///
  /// In en, this message translates to:
  /// **'Protect.'**
  String get protect;

  /// No description provided for @prevent.
  ///
  /// In en, this message translates to:
  /// **'Prevent.'**
  String get prevent;

  /// No description provided for @getStartedBtn.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedBtn;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'WIQA'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Description.
  ///
  /// In en, this message translates to:
  /// **'AI-powered PPE detection for safer workplaces.'**
  String get onboarding1Description;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Description.
  ///
  /// In en, this message translates to:
  /// **'Three simple steps to smarter safety monitoring.'**
  String get onboarding2Description;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Capture or Upload'**
  String get step1Title;

  /// No description provided for @step1Desc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or upload a workplace image.'**
  String get step1Desc;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'AI Detection'**
  String get step2Title;

  /// No description provided for @step2Desc.
  ///
  /// In en, this message translates to:
  /// **'WIQA detects PPE violations automatically.'**
  String get step2Desc;

  /// No description provided for @step3Title.
  ///
  /// In en, this message translates to:
  /// **'Get Safety Results'**
  String get step3Title;

  /// No description provided for @step3Desc.
  ///
  /// In en, this message translates to:
  /// **'See detected violations and safety status instantly.'**
  String get step3Desc;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Safer Workplaces,\nSmarter Protection'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Description.
  ///
  /// In en, this message translates to:
  /// **'Monitor PPE compliance and identify safety risks before they become accidents.'**
  String get onboarding3Description;

  /// No description provided for @ppeHelmet.
  ///
  /// In en, this message translates to:
  /// **'HardHat'**
  String get ppeHelmet;

  /// No description provided for @ppeVest.
  ///
  /// In en, this message translates to:
  /// **'Safety Vest'**
  String get ppeVest;

  /// No description provided for @ppeGloves.
  ///
  /// In en, this message translates to:
  /// **'Gloves'**
  String get ppeGloves;

  /// No description provided for @ppeGoggles.
  ///
  /// In en, this message translates to:
  /// **'Goggles'**
  String get ppeGoggles;

  /// No description provided for @ppeMask.
  ///
  /// In en, this message translates to:
  /// **'Mask'**
  String get ppeMask;

  /// No description provided for @ppeFall.
  ///
  /// In en, this message translates to:
  /// **'Detected Fall'**
  String get ppeFall;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @signupSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Created'**
  String get signupSuccessTitle;

  /// No description provided for @signupSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Please sign in.'**
  String get signupSuccessMsg;

  /// No description provided for @signupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Creation Failed'**
  String get signupFailedTitle;

  /// No description provided for @loginSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get loginSuccessTitle;

  /// No description provided for @loginSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'You have signed in successfully.'**
  String get loginSuccessMsg;

  /// No description provided for @loginFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailedTitle;

  /// No description provided for @authFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your email or password is incorrect.'**
  String get authFailedMsg;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @btnTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get btnTryAgain;

  /// No description provided for @createAccountPart1.
  ///
  /// In en, this message translates to:
  /// **'Create Your\n'**
  String get createAccountPart1;

  /// No description provided for @createAccountPart2.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get createAccountPart2;

  /// No description provided for @welcomePart1.
  ///
  /// In en, this message translates to:
  /// **'Welcome\n'**
  String get welcomePart1;

  /// No description provided for @welcomePart2.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get welcomePart2;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationNotMatched.
  ///
  /// In en, this message translates to:
  /// **'Not matched'**
  String get validationNotMatched;

  /// No description provided for @btnSignUp.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get btnSignUp;

  /// No description provided for @btnSignIn.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get btnSignIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInLink;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get navMyReports;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your workplace safe'**
  String get homeSubtitle;

  /// No description provided for @reportPollutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Start PPE Detection'**
  String get reportPollutionTitle;

  /// No description provided for @reportPollutionSub.
  ///
  /// In en, this message translates to:
  /// **'Detect PPE violations using a photo or video'**
  String get reportPollutionSub;

  /// No description provided for @reportsSummary.
  ///
  /// In en, this message translates to:
  /// **'Safety Summary'**
  String get reportsSummary;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @recentReports.
  ///
  /// In en, this message translates to:
  /// **'Recent Reports'**
  String get recentReports;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No detections found'**
  String get noReports;

  /// No description provided for @selectElementsToDetect.
  ///
  /// In en, this message translates to:
  /// **'Select Elements to Detect'**
  String get selectElementsToDetect;

  /// No description provided for @chooseSafetyElements.
  ///
  /// In en, this message translates to:
  /// **'Choose which types of safety elements to detect in your images and videos'**
  String get chooseSafetyElements;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @applySelection.
  ///
  /// In en, this message translates to:
  /// **'Apply Selection'**
  String get applySelection;

  /// No description provided for @createTicket.
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get createTicket;

  /// No description provided for @originalVideo.
  ///
  /// In en, this message translates to:
  /// **'Original Video'**
  String get originalVideo;

  /// No description provided for @originalImage.
  ///
  /// In en, this message translates to:
  /// **'Original Image'**
  String get originalImage;

  /// No description provided for @selectedSafetyElements.
  ///
  /// In en, this message translates to:
  /// **'Selected safety elements'**
  String get selectedSafetyElements;

  /// No description provided for @noElementsSelected.
  ///
  /// In en, this message translates to:
  /// **'No elements selected yet'**
  String get noElementsSelected;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @aiAnalysisResults.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis Results'**
  String get aiAnalysisResults;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @processedVideo.
  ///
  /// In en, this message translates to:
  /// **'Processed Video'**
  String get processedVideo;

  /// No description provided for @processedImage.
  ///
  /// In en, this message translates to:
  /// **'Processed Image'**
  String get processedImage;

  /// No description provided for @detectedViolations.
  ///
  /// In en, this message translates to:
  /// **'Detected Violations'**
  String get detectedViolations;

  /// No description provided for @overallConfidence.
  ///
  /// In en, this message translates to:
  /// **'Overall\nConfidence'**
  String get overallConfidence;

  /// No description provided for @noPpeViolations.
  ///
  /// In en, this message translates to:
  /// **'No PPE violations detected'**
  String get noPpeViolations;

  /// No description provided for @detectionSingular.
  ///
  /// In en, this message translates to:
  /// **'detection'**
  String get detectionSingular;

  /// No description provided for @detectionPlural.
  ///
  /// In en, this message translates to:
  /// **'detections'**
  String get detectionPlural;

  /// No description provided for @reAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Re-analyze'**
  String get reAnalyze;

  /// No description provided for @detectPpe.
  ///
  /// In en, this message translates to:
  /// **'Detect PPE'**
  String get detectPpe;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @openTicket.
  ///
  /// In en, this message translates to:
  /// **'Open Ticket'**
  String get openTicket;

  /// No description provided for @selectOneElementError.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one element before starting detection'**
  String get selectOneElementError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'A connection error occurred'**
  String get connectionError;

  /// No description provided for @analyzingVideoStatus.
  ///
  /// In en, this message translates to:
  /// **'Analyzing video...'**
  String get analyzingVideoStatus;

  /// No description provided for @analyzingStatus.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzingStatus;

  /// No description provided for @analyzingVideoDialog.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Video'**
  String get analyzingVideoDialog;

  /// No description provided for @analyzingImageDialog.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Image'**
  String get analyzingImageDialog;

  /// No description provided for @detectingVideoDialog.
  ///
  /// In en, this message translates to:
  /// **'Detecting safety elements in the video...'**
  String get detectingVideoDialog;

  /// No description provided for @detectingImageDialog.
  ///
  /// In en, this message translates to:
  /// **'Detecting safety elements...'**
  String get detectingImageDialog;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
