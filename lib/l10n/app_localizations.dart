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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Mahfazati'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Mahfazati'**
  String get welcome;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Your personal app for managing expenses and savings easily and flexibly'**
  String get welcomeDescription;

  /// No description provided for @trackEveryMove.
  ///
  /// In en, this message translates to:
  /// **'Track Every Move'**
  String get trackEveryMove;

  /// No description provided for @trackDescription.
  ///
  /// In en, this message translates to:
  /// **'Record all your expenses and income in one place with full details'**
  String get trackDescription;

  /// No description provided for @planYourFuture.
  ///
  /// In en, this message translates to:
  /// **'Plan Your Future'**
  String get planYourFuture;

  /// No description provided for @planDescription.
  ///
  /// In en, this message translates to:
  /// **'Set your budget and track your progress towards your financial goals'**
  String get planDescription;

  /// No description provided for @keepYourSavings.
  ///
  /// In en, this message translates to:
  /// **'Keep Your Savings'**
  String get keepYourSavings;

  /// No description provided for @keepDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow your daily savings and watch them grow over time'**
  String get keepDescription;

  /// No description provided for @controlYourExpenses.
  ///
  /// In en, this message translates to:
  /// **'Control Your Expenses'**
  String get controlYourExpenses;

  /// No description provided for @controlDescription.
  ///
  /// In en, this message translates to:
  /// **'Get accurate reports of your expenses and save smartly'**
  String get controlDescription;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @manageYourMoneyEasily.
  ///
  /// In en, this message translates to:
  /// **'Manage your money easily'**
  String get manageYourMoneyEasily;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @monthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Income'**
  String get monthlyIncome;

  /// No description provided for @monthlyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Monthly Expenses'**
  String get monthlyExpenses;

  /// No description provided for @remainingBudget.
  ///
  /// In en, this message translates to:
  /// **'Remaining Budget'**
  String get remainingBudget;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @addYourFirstTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction'**
  String get addYourFirstTransaction;

  /// No description provided for @budgetOverview.
  ///
  /// In en, this message translates to:
  /// **'Budget Overview'**
  String get budgetOverview;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @overBudget.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get overBudget;

  /// No description provided for @underBudget.
  ///
  /// In en, this message translates to:
  /// **'Under Budget'**
  String get underBudget;

  /// No description provided for @whatIsYourEmail.
  ///
  /// In en, this message translates to:
  /// **'What is your email?'**
  String get whatIsYourEmail;

  /// No description provided for @enterYourEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to create an account or log in again'**
  String get enterYourEmailDescription;

  /// No description provided for @lostAccessToEmail.
  ///
  /// In en, this message translates to:
  /// **'Lost access to your email?'**
  String get lostAccessToEmail;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterVerificationCode;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @enterCodeSentSms.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent in an SMS to'**
  String get enterCodeSentSms;

  /// No description provided for @enterCodeSentEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent in an email to'**
  String get enterCodeSentEmail;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in'**
  String get resendCodeIn;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code again'**
  String get resendCode;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @enterYourPasscode.
  ///
  /// In en, this message translates to:
  /// **'Enter your passcode'**
  String get enterYourPasscode;

  /// No description provided for @setPasscodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a passcode'**
  String get setPasscodeTitle;

  /// No description provided for @setPasscodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a passcode for your account. You will be able to log in with this passcode.'**
  String get setPasscodeDescription;

  /// No description provided for @forgotPasscode.
  ///
  /// In en, this message translates to:
  /// **'Forget?'**
  String get forgotPasscode;

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistration;

  /// No description provided for @enterYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to complete your account'**
  String get enterYourDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get userName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidVerificationCode;

  /// No description provided for @verifyCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to verify the code'**
  String get verifyCodeFailed;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @appIcon.
  ///
  /// In en, this message translates to:
  /// **'App Icon'**
  String get appIcon;

  /// No description provided for @changeAppIcon.
  ///
  /// In en, this message translates to:
  /// **'Change App Icon'**
  String get changeAppIcon;

  /// No description provided for @displayMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get displayMode;

  /// No description provided for @selectDisplayTheme.
  ///
  /// In en, this message translates to:
  /// **'Select display theme'**
  String get selectDisplayTheme;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @updateYourPersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updateYourPersonalInformation;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @changeAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get changeAppLanguage;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePasscode.
  ///
  /// In en, this message translates to:
  /// **'Change Passcode'**
  String get changePasscode;

  /// No description provided for @updateYour6DigitPasscode.
  ///
  /// In en, this message translates to:
  /// **'Update your 6-digit passcode'**
  String get updateYour6DigitPasscode;

  /// No description provided for @signWithFaceIDFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Sign with Face ID/Fingerprint'**
  String get signWithFaceIDFingerprint;

  /// No description provided for @useBiometricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Use biometric authentication'**
  String get useBiometricAuthentication;

  /// No description provided for @hideBalances.
  ///
  /// In en, this message translates to:
  /// **'Hide Balances'**
  String get hideBalances;

  /// No description provided for @hideYourBalancesForPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Hide your balances for privacy'**
  String get hideYourBalancesForPrivacy;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @rateUsOnAppStorePlayStore.
  ///
  /// In en, this message translates to:
  /// **'Rate us on App Store/Play Store'**
  String get rateUsOnAppStorePlayStore;

  /// No description provided for @likeUsOnFacebook.
  ///
  /// In en, this message translates to:
  /// **'Like us on Facebook'**
  String get likeUsOnFacebook;

  /// No description provided for @followUsOnTwitter.
  ///
  /// In en, this message translates to:
  /// **'Follow us on Twitter'**
  String get followUsOnTwitter;

  /// No description provided for @followUsOnInstagram.
  ///
  /// In en, this message translates to:
  /// **'Follow us on Instagram'**
  String get followUsOnInstagram;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @closeAccount.
  ///
  /// In en, this message translates to:
  /// **'Close Account'**
  String get closeAccount;

  /// No description provided for @permanentlyDeleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get permanentlyDeleteYourAccount;

  /// No description provided for @closeAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close your account? This action cannot be undone.'**
  String get closeAccountConfirmation;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon!'**
  String get featureComingSoon;

  /// No description provided for @cannotOpenStore.
  ///
  /// In en, this message translates to:
  /// **'Cannot open store'**
  String get cannotOpenStore;

  /// No description provided for @cannotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Cannot open URL'**
  String get cannotOpenUrl;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data: {error}'**
  String errorLoadingData(Object error);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @addDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add Deposit'**
  String get addDeposit;

  /// No description provided for @addWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Add Withdrawal'**
  String get addWithdrawal;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get enterTitle;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get enterAmount;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @amountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get amountGreaterThanZero;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @depositAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deposit added successfully!'**
  String get depositAddedSuccess;

  /// No description provided for @withdrawalAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal added successfully!'**
  String get withdrawalAddedSuccess;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get deleteTransaction;

  /// No description provided for @confirmDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String confirmDeleteTransaction(Object title);

  /// No description provided for @transactionDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted successfully!'**
  String get transactionDeletedSuccess;

  /// No description provided for @failedToDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete transaction'**
  String get failedToDeleteTransaction;

  /// No description provided for @errorDeletingTransaction.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorDeletingTransaction(Object error);

  /// No description provided for @failedToAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Failed to add transaction: {error}'**
  String failedToAddTransaction(Object error);

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'m ago'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get hoursAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'d ago'**
  String get daysAgo;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @trackSpendingHabits.
  ///
  /// In en, this message translates to:
  /// **'Track your spending habits'**
  String get trackSpendingHabits;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @spendingOverview.
  ///
  /// In en, this message translates to:
  /// **'Spending Overview'**
  String get spendingOverview;

  /// No description provided for @chartVisualization.
  ///
  /// In en, this message translates to:
  /// **'Chart Visualization'**
  String get chartVisualization;

  /// No description provided for @topCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get topCategories;

  /// No description provided for @categoryFoodDining.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get categoryFoodDining;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryTransportation;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @allTransactionsInOnePlace.
  ///
  /// In en, this message translates to:
  /// **'All your transactions in one place'**
  String get allTransactionsInOnePlace;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get searchTransactions;

  /// No description provided for @salaryDeposit.
  ///
  /// In en, this message translates to:
  /// **'Salary Deposit'**
  String get salaryDeposit;

  /// No description provided for @groceryShopping.
  ///
  /// In en, this message translates to:
  /// **'Grocery Shopping'**
  String get groceryShopping;

  /// No description provided for @netflixSubscription.
  ///
  /// In en, this message translates to:
  /// **'Netflix Subscription'**
  String get netflixSubscription;

  /// No description provided for @freelancePayment.
  ///
  /// In en, this message translates to:
  /// **'Freelance Payment'**
  String get freelancePayment;

  /// No description provided for @electricityBill.
  ///
  /// In en, this message translates to:
  /// **'Electricity Bill'**
  String get electricityBill;

  /// No description provided for @onlinePurchase.
  ///
  /// In en, this message translates to:
  /// **'Online Purchase'**
  String get onlinePurchase;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @categoryFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get categoryFreelance;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'john.doe@email.com'**
  String get userEmail;

  /// No description provided for @logoutConfirmationDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmationDescription;

  /// No description provided for @monthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudget;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get categoryBills;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @setMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Set Monthly Budget'**
  String get setMonthlyBudget;

  /// No description provided for @monthlyBudgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget Amount'**
  String get monthlyBudgetAmount;

  /// No description provided for @budgetUpdated.
  ///
  /// In en, this message translates to:
  /// **'Budget updated to {amount}'**
  String budgetUpdated(Object amount);

  /// No description provided for @budgetTip.
  ///
  /// In en, this message translates to:
  /// **'Budget Tip'**
  String get budgetTip;

  /// No description provided for @tryReducingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Try reducing entertainment and dining expenses.'**
  String get tryReducingExpenses;

  /// No description provided for @considerSaving.
  ///
  /// In en, this message translates to:
  /// **'Consider saving 20% of your income.'**
  String get considerSaving;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get failed;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get forgotPin;

  /// No description provided for @forgotPinDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a new verification code to your email to reset your PIN.'**
  String get forgotPinDescription;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @enterPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your 6-digit PIN to access your wallet'**
  String get enterPinDescription;

  /// No description provided for @codeVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verified successfully! Redirecting...'**
  String get codeVerifiedSuccess;

  /// No description provided for @pasteCode.
  ///
  /// In en, this message translates to:
  /// **'Paste code'**
  String get pasteCode;

  /// No description provided for @invalidCodePasted.
  ///
  /// In en, this message translates to:
  /// **'Invalid pasted code, please enter 6 digits'**
  String get invalidCodePasted;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'Code resent'**
  String get codeResent;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// No description provided for @forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get forgot;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// No description provided for @enterUserName.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get enterUserName;

  /// No description provided for @pleaseEnterUserName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get pleaseEnterUserName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @currentIcon.
  ///
  /// In en, this message translates to:
  /// **'Current Icon'**
  String get currentIcon;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @recurringTransaction.
  ///
  /// In en, this message translates to:
  /// **'Recurring Transaction'**
  String get recurringTransaction;

  /// No description provided for @recurringTransactionDescription.
  ///
  /// In en, this message translates to:
  /// **'Repeat this transaction automatically'**
  String get recurringTransactionDescription;

  /// No description provided for @recurringInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get recurringInterval;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;
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
