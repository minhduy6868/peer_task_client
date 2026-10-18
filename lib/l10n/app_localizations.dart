import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('vi'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'PeerTask'**
  String get appTitle;

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

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

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

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

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

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get signInTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get signUpTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue'**
  String get signInSubtitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to get started'**
  String get signUpSubtitle;

  /// No description provided for @signInToAdventure.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN TO YOUR\nADVENTURE!'**
  String get signInToAdventure;

  /// No description provided for @startYourAdventure.
  ///
  /// In en, this message translates to:
  /// **'START YOUR\nADVENTURE!'**
  String get startYourAdventure;

  /// No description provided for @collaborativeDescription.
  ///
  /// In en, this message translates to:
  /// **'Collaborate seamlessly with your team\non P2P whiteboards and task boards'**
  String get collaborativeDescription;

  /// No description provided for @realTimeCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Real-time collaboration'**
  String get realTimeCollaboration;

  /// No description provided for @secureP2P.
  ///
  /// In en, this message translates to:
  /// **'Secure P2P connection'**
  String get secureP2P;

  /// No description provided for @crossPlatform.
  ///
  /// In en, this message translates to:
  /// **'Cross-platform support'**
  String get crossPlatform;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your email address'**
  String get emailPlaceholder;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordPlaceholder;

  /// No description provided for @namePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your Name (optional)'**
  String get namePlaceholder;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get termsAgreement;

  /// No description provided for @termsAgreementRequired.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the Terms of Service and Privacy Policy to continue'**
  String get termsAgreementRequired;

  /// No description provided for @byRegistering.
  ///
  /// In en, this message translates to:
  /// **'By registering you with our Terms and Conditions'**
  String get byRegistering;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordMinLength8.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength8;

  /// No description provided for @passwordRequireUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 1 uppercase letter'**
  String get passwordRequireUppercase;

  /// No description provided for @passwordRequireLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 1 lowercase letter'**
  String get passwordRequireLowercase;

  /// No description provided for @passwordRequireDigit.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 1 digit'**
  String get passwordRequireDigit;

  /// No description provided for @passwordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get passwordConfirmRequired;

  /// No description provided for @passwordNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordNotMatch;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinLength;

  /// No description provided for @nameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Name cannot exceed 50 characters'**
  String get nameMaxLength;

  /// No description provided for @nameLettersOnly.
  ///
  /// In en, this message translates to:
  /// **'Name can only contain letters'**
  String get nameLettersOnly;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @fieldMinLength.
  ///
  /// In en, this message translates to:
  /// **'{field} must be at least {min} characters'**
  String fieldMinLength(String field, int min);

  /// No description provided for @fieldMaxLength.
  ///
  /// In en, this message translates to:
  /// **'{field} cannot exceed {max} characters'**
  String fieldMaxLength(String field, int max);

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberRequired;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get phoneNumberInvalid;

  /// No description provided for @urlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required'**
  String get urlRequired;

  /// No description provided for @urlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get urlInvalid;

  /// No description provided for @numberRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get numberRequired;

  /// No description provided for @numberInvalid.
  ///
  /// In en, this message translates to:
  /// **'This field must be a number'**
  String get numberInvalid;

  /// No description provided for @integerInvalid.
  ///
  /// In en, this message translates to:
  /// **'This field must be an integer'**
  String get integerInvalid;

  /// No description provided for @valueMin.
  ///
  /// In en, this message translates to:
  /// **'{field} must be greater than or equal to {min}'**
  String valueMin(String field, num min);

  /// No description provided for @valueMax.
  ///
  /// In en, this message translates to:
  /// **'{field} must be less than or equal to {max}'**
  String valueMax(String field, num max);

  /// No description provided for @valueRange.
  ///
  /// In en, this message translates to:
  /// **'{field} must be between {min} and {max}'**
  String valueRange(String field, num min, num max);

  /// No description provided for @workspaceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Workspace name is required'**
  String get workspaceNameRequired;

  /// No description provided for @workspaceNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Workspace name must be at least 3 characters'**
  String get workspaceNameMinLength;

  /// No description provided for @workspaceNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Workspace name cannot exceed 50 characters'**
  String get workspaceNameMaxLength;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Task title is required'**
  String get taskTitleRequired;

  /// No description provided for @taskTitleMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Task title cannot exceed 200 characters'**
  String get taskTitleMaxLength;

  /// No description provided for @workspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaces;

  /// No description provided for @createWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create Workspace'**
  String get createWorkspace;

  /// No description provided for @workspaceName.
  ///
  /// In en, this message translates to:
  /// **'Workspace Name'**
  String get workspaceName;

  /// No description provided for @boards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get boards;

  /// No description provided for @createBoard.
  ///
  /// In en, this message translates to:
  /// **'Create Board'**
  String get createBoard;

  /// No description provided for @boardName.
  ///
  /// In en, this message translates to:
  /// **'Board Name'**
  String get boardName;

  /// No description provided for @boardDescription.
  ///
  /// In en, this message translates to:
  /// **'Board Description'**
  String get boardDescription;

  /// No description provided for @myBoards.
  ///
  /// In en, this message translates to:
  /// **'My Boards'**
  String get myBoards;

  /// No description provided for @searchBoards.
  ///
  /// In en, this message translates to:
  /// **'Search boards'**
  String get searchBoards;

  /// No description provided for @newBoard.
  ///
  /// In en, this message translates to:
  /// **'New Board'**
  String get newBoard;

  /// No description provided for @createNewBoard.
  ///
  /// In en, this message translates to:
  /// **'Create New Board'**
  String get createNewBoard;

  /// No description provided for @enterBoardName.
  ///
  /// In en, this message translates to:
  /// **'Enter a creative name...'**
  String get enterBoardName;

  /// No description provided for @boardDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'What is this board about?'**
  String get boardDescriptionOptional;

  /// No description provided for @boardCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Board \"{name}\" created successfully!'**
  String boardCreatedSuccess(Object name);

  /// No description provided for @noBoardsYet.
  ///
  /// In en, this message translates to:
  /// **'No boards yet'**
  String get noBoardsYet;

  /// No description provided for @createFirstBoard.
  ///
  /// In en, this message translates to:
  /// **'Create your first board to start collaborating'**
  String get createFirstBoard;

  /// No description provided for @inviteMembers.
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get inviteMembers;

  /// No description provided for @inviteLink.
  ///
  /// In en, this message translates to:
  /// **'Invite Link'**
  String get inviteLink;

  /// No description provided for @inviteByEmail.
  ///
  /// In en, this message translates to:
  /// **'Invite by email'**
  String get inviteByEmail;

  /// No description provided for @joinWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Join Workspace'**
  String get joinWorkspace;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// No description provided for @generateInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Generate Invite Link'**
  String get generateInviteLink;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard!'**
  String get linkCopied;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in'**
  String get expiresIn;

  /// No description provided for @maxUses.
  ///
  /// In en, this message translates to:
  /// **'Max uses'**
  String get maxUses;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String hours(Object count);

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String days(Object count);

  /// No description provided for @uses.
  ///
  /// In en, this message translates to:
  /// **'{count} uses'**
  String uses(Object count);

  /// No description provided for @scanQRToJoin.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code to join'**
  String get scanQRToJoin;

  /// No description provided for @enterInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Enter Invite Link'**
  String get enterInviteLink;

  /// No description provided for @joinedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined workspace!'**
  String get joinedSuccessfully;

  /// No description provided for @whiteboard.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard'**
  String get whiteboard;

  /// No description provided for @drawingTools.
  ///
  /// In en, this message translates to:
  /// **'Drawing Tools'**
  String get drawingTools;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @pen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get pen;

  /// No description provided for @eraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get eraser;

  /// No description provided for @rectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get rectangle;

  /// No description provided for @circle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get circle;

  /// No description provided for @line.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get line;

  /// No description provided for @arrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow'**
  String get arrow;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @stickyNote.
  ///
  /// In en, this message translates to:
  /// **'Sticky Note'**
  String get stickyNote;

  /// No description provided for @taskNode.
  ///
  /// In en, this message translates to:
  /// **'Task Node'**
  String get taskNode;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @strokeWidth.
  ///
  /// In en, this message translates to:
  /// **'Stroke Width'**
  String get strokeWidth;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @noObjectSelected.
  ///
  /// In en, this message translates to:
  /// **'No object selected'**
  String get noObjectSelected;

  /// No description provided for @selectObjectToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select an object to edit properties'**
  String get selectObjectToEdit;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @taskStatus.
  ///
  /// In en, this message translates to:
  /// **'Task Status'**
  String get taskStatus;

  /// No description provided for @todo.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get todo;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @taskPriority.
  ///
  /// In en, this message translates to:
  /// **'Task Priority'**
  String get taskPriority;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @peers.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get peers;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @hybridBoard.
  ///
  /// In en, this message translates to:
  /// **'Hybrid Board'**
  String get hybridBoard;

  /// No description provided for @canvas.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get canvas;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @pan.
  ///
  /// In en, this message translates to:
  /// **'Pan'**
  String get pan;

  /// No description provided for @clearCanvas.
  ///
  /// In en, this message translates to:
  /// **'Clear Canvas'**
  String get clearCanvas;

  /// No description provided for @hideTasks.
  ///
  /// In en, this message translates to:
  /// **'Hide Tasks'**
  String get hideTasks;

  /// No description provided for @showTasks.
  ///
  /// In en, this message translates to:
  /// **'Show Tasks'**
  String get showTasks;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Task title...'**
  String get taskTitle;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assignee;

  /// No description provided for @assigneeName.
  ///
  /// In en, this message translates to:
  /// **'Assignee name...'**
  String get assigneeName;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @doing.
  ///
  /// In en, this message translates to:
  /// **'Doing'**
  String get doing;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get removeMember;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @changePermission.
  ///
  /// In en, this message translates to:
  /// **'Change Permission'**
  String get changePermission;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @viewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewer;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @workspaceRole.
  ///
  /// In en, this message translates to:
  /// **'Workspace Role'**
  String get workspaceRole;

  /// No description provided for @boardPermission.
  ///
  /// In en, this message translates to:
  /// **'Board Permission'**
  String get boardPermission;

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

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Please try again.'**
  String get connectionError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timeout. Please try again.'**
  String get timeoutError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unknownError;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Invalid input. Please check your data.'**
  String get validationError;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action'**
  String get permissionDenied;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found'**
  String get notFound;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @taskSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task saved successfully'**
  String get taskSavedSuccess;

  /// No description provided for @taskUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task updated successfully'**
  String get taskUpdatedSuccess;

  /// No description provided for @taskDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task deleted successfully'**
  String get taskDeletedSuccess;

  /// No description provided for @taskSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save task'**
  String get taskSaveError;

  /// No description provided for @taskUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update task'**
  String get taskUpdateError;

  /// No description provided for @taskDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete task'**
  String get taskDeleteError;

  /// No description provided for @boardUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Board updated successfully'**
  String get boardUpdatedSuccess;

  /// No description provided for @boardDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Board deleted successfully'**
  String get boardDeletedSuccess;

  /// No description provided for @boardUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update board'**
  String get boardUpdateError;

  /// No description provided for @boardDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete board'**
  String get boardDeleteError;

  /// No description provided for @boardDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this board?'**
  String get boardDeleteConfirm;

  /// No description provided for @boardNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Board name is required'**
  String get boardNameRequired;

  /// No description provided for @operationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get operationSuccess;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @workspaceInfo.
  ///
  /// In en, this message translates to:
  /// **'Workspace Info'**
  String get workspaceInfo;

  /// No description provided for @workspaceSettings.
  ///
  /// In en, this message translates to:
  /// **'Workspace Settings'**
  String get workspaceSettings;

  /// No description provided for @changeWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Change Workspace'**
  String get changeWorkspace;

  /// No description provided for @leaveWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Leave Workspace'**
  String get leaveWorkspace;

  /// No description provided for @deleteWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Delete Workspace'**
  String get deleteWorkspace;

  /// No description provided for @leaveWorkspaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this workspace?'**
  String get leaveWorkspaceConfirm;

  /// No description provided for @deleteWorkspaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this workspace? This action cannot be undone.'**
  String get deleteWorkspaceConfirm;

  /// No description provided for @workspaceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Workspace updated'**
  String get workspaceUpdated;

  /// No description provided for @workspaceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Workspace deleted'**
  String get workspaceDeleted;

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get memberRemoved;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get roleUpdated;

  /// No description provided for @inviteRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invite revoked'**
  String get inviteRevoked;

  /// No description provided for @inviteCodeCreated.
  ///
  /// In en, this message translates to:
  /// **'Invite Code Created'**
  String get inviteCodeCreated;

  /// No description provided for @shareCodeToInvite.
  ///
  /// In en, this message translates to:
  /// **'Share this code to invite members:'**
  String get shareCodeToInvite;

  /// No description provided for @scanQROrCopy.
  ///
  /// In en, this message translates to:
  /// **'• Scan QR code\n• Or copy and paste the code'**
  String get scanQROrCopy;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'✅ Code copied to clipboard'**
  String get codeCopied;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @invites.
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get invites;

  /// No description provided for @createInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Create Invite Link'**
  String get createInviteLink;

  /// No description provided for @noActiveInvites.
  ///
  /// In en, this message translates to:
  /// **'No active invites'**
  String get noActiveInvites;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will delete all boards, tasks, and data. This action cannot be undone.'**
  String get deleteAllData;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get makeAdmin;

  /// No description provided for @makeMember.
  ///
  /// In en, this message translates to:
  /// **'Make Member'**
  String get makeMember;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @useInviteLinkToAdd.
  ///
  /// In en, this message translates to:
  /// **'Use invite link to add members'**
  String get useInviteLinkToAdd;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @errorLoadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Error loading members: {error}'**
  String errorLoadingMembers(Object error);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @noWorkspaceYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any workspace yet'**
  String get noWorkspaceYet;

  /// No description provided for @createOrJoinWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create a new workspace or join an existing one to get started'**
  String get createOrJoinWorkspace;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @yourWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Your Workspaces'**
  String get yourWorkspaces;

  /// No description provided for @selectWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Select a workspace to continue'**
  String get selectWorkspace;

  /// No description provided for @enterWorkspaceName.
  ///
  /// In en, this message translates to:
  /// **'Enter workspace name'**
  String get enterWorkspaceName;

  /// No description provided for @taskCard.
  ///
  /// In en, this message translates to:
  /// **'Task Card'**
  String get taskCard;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @yourWork.
  ///
  /// In en, this message translates to:
  /// **'Your work'**
  String get yourWork;

  /// No description provided for @nothingAssigned.
  ///
  /// In en, this message translates to:
  /// **'Nothing is assigned to you in this workspace.'**
  String get nothingAssigned;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @assignees.
  ///
  /// In en, this message translates to:
  /// **'Assignees'**
  String get assignees;

  /// No description provided for @moreAssignees.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String moreAssignees(int count);

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @moveTask.
  ///
  /// In en, this message translates to:
  /// **'Move Task'**
  String get moveTask;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @labels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labels;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @estimatedHours.
  ///
  /// In en, this message translates to:
  /// **'Estimated Hours'**
  String get estimatedHours;

  /// No description provided for @actualHours.
  ///
  /// In en, this message translates to:
  /// **'Actual Hours'**
  String get actualHours;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdBy;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updatedAt;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTask;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this task?'**
  String get deleteTaskConfirm;

  /// No description provided for @todoColumn.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get todoColumn;

  /// No description provided for @doingColumn.
  ///
  /// In en, this message translates to:
  /// **'Doing'**
  String get doingColumn;

  /// No description provided for @doneColumn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneColumn;

  /// No description provided for @taskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks'**
  String taskCount(int count);

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get noTasks;

  /// No description provided for @addFirstTask.
  ///
  /// In en, this message translates to:
  /// **'Add your first task to get started'**
  String get addFirstTask;

  /// No description provided for @aiBrainstorm.
  ///
  /// In en, this message translates to:
  /// **'AI Brainstorm'**
  String get aiBrainstorm;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get aiThinking;

  /// No description provided for @aiConnected.
  ///
  /// In en, this message translates to:
  /// **'AI Connected'**
  String get aiConnected;

  /// No description provided for @aiDisconnected.
  ///
  /// In en, this message translates to:
  /// **'AI Disconnected'**
  String get aiDisconnected;

  /// No description provided for @aiConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to Ollama'**
  String get aiConnectionError;

  /// No description provided for @aiConnectionErrorHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure Ollama is running (ollama serve)'**
  String get aiConnectionErrorHint;

  /// No description provided for @aiRetryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get aiRetryConnection;

  /// No description provided for @brainstormMode.
  ///
  /// In en, this message translates to:
  /// **'Brainstorm'**
  String get brainstormMode;

  /// No description provided for @brainstormHint.
  ///
  /// In en, this message translates to:
  /// **'Expand ideas'**
  String get brainstormHint;

  /// No description provided for @tasksMode.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksMode;

  /// No description provided for @tasksHint.
  ///
  /// In en, this message translates to:
  /// **'Generate task list'**
  String get tasksHint;

  /// No description provided for @improveMode.
  ///
  /// In en, this message translates to:
  /// **'Improve'**
  String get improveMode;

  /// No description provided for @improveHint.
  ///
  /// In en, this message translates to:
  /// **'Improve text'**
  String get improveHint;

  /// No description provided for @enterIdeaToBrainstorm.
  ///
  /// In en, this message translates to:
  /// **'Enter idea to brainstorm...'**
  String get enterIdeaToBrainstorm;

  /// No description provided for @describeProjectForTasks.
  ///
  /// In en, this message translates to:
  /// **'Describe project to generate tasks...'**
  String get describeProjectForTasks;

  /// No description provided for @enterTextToImprove.
  ///
  /// In en, this message translates to:
  /// **'Enter text to improve...'**
  String get enterTextToImprove;

  /// No description provided for @addToBoard.
  ///
  /// In en, this message translates to:
  /// **'Add to Board'**
  String get addToBoard;

  /// No description provided for @addedToCanvas.
  ///
  /// In en, this message translates to:
  /// **'Added to canvas!'**
  String get addedToCanvas;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @mainIdea.
  ///
  /// In en, this message translates to:
  /// **'Main Idea'**
  String get mainIdea;

  /// No description provided for @relatedIdeas.
  ///
  /// In en, this message translates to:
  /// **'Related Ideas'**
  String get relatedIdeas;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @nextActions.
  ///
  /// In en, this message translates to:
  /// **'Next Actions'**
  String get nextActions;

  /// No description provided for @questionsToConsider.
  ///
  /// In en, this message translates to:
  /// **'Questions to Consider'**
  String get questionsToConsider;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @mediumPriority.
  ///
  /// In en, this message translates to:
  /// **'Medium Priority'**
  String get mediumPriority;

  /// No description provided for @lowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get lowPriority;

  /// No description provided for @taskList.
  ///
  /// In en, this message translates to:
  /// **'Task List'**
  String get taskList;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @totalTasks.
  ///
  /// In en, this message translates to:
  /// **'Total Tasks'**
  String get totalTasks;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// No description provided for @improvedText.
  ///
  /// In en, this message translates to:
  /// **'Improved Text'**
  String get improvedText;

  /// No description provided for @changes.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get changes;

  /// No description provided for @dragToMove.
  ///
  /// In en, this message translates to:
  /// **'Drag to move'**
  String get dragToMove;

  /// No description provided for @clickToSelect.
  ///
  /// In en, this message translates to:
  /// **'Click to select'**
  String get clickToSelect;

  /// No description provided for @textAddedToBoard.
  ///
  /// In en, this message translates to:
  /// **'Text added to board'**
  String get textAddedToBoard;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall;

  /// No description provided for @startVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Start Voice Call'**
  String get startVoiceCall;

  /// No description provided for @endVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'End Voice Call'**
  String get endVoiceCall;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get microphonePermissionDenied;

  /// No description provided for @screenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get screenshot;

  /// No description provided for @screenshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved!'**
  String get screenshotSaved;

  /// No description provided for @screenshotFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture screenshot'**
  String get screenshotFailed;

  /// No description provided for @canvasAndKanban.
  ///
  /// In en, this message translates to:
  /// **'Canvas + Kanban'**
  String get canvasAndKanban;

  /// No description provided for @showKanban.
  ///
  /// In en, this message translates to:
  /// **'Show Kanban'**
  String get showKanban;

  /// No description provided for @hideKanban.
  ///
  /// In en, this message translates to:
  /// **'Hide Kanban'**
  String get hideKanban;

  /// No description provided for @backToBoards.
  ///
  /// In en, this message translates to:
  /// **'Back to boards'**
  String get backToBoards;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft to server'**
  String get saveDraft;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved to server'**
  String get draftSaved;

  /// No description provided for @draftRestored.
  ///
  /// In en, this message translates to:
  /// **'Unsaved strokes were recovered and saved to the server'**
  String get draftRestored;

  /// No description provided for @unsavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Not saved to server yet'**
  String get unsavedDraft;

  /// No description provided for @discardDraft.
  ///
  /// In en, this message translates to:
  /// **'Discard local backup'**
  String get discardDraft;

  /// No description provided for @discardDraftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the local backup only? The canvas on the server stays as it is.'**
  String get discardDraftConfirm;

  /// No description provided for @draftSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved · {time}'**
  String draftSavedAt(String time);

  /// No description provided for @addText.
  ///
  /// In en, this message translates to:
  /// **'Add text'**
  String get addText;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter text…'**
  String get enterText;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @addPage.
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get addPage;

  /// No description provided for @pageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pageLabel;

  /// No description provided for @speaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get speaking;

  /// No description provided for @toolHintPen.
  ///
  /// In en, this message translates to:
  /// **'Draw on the canvas'**
  String get toolHintPen;

  /// No description provided for @toolHintEraser.
  ///
  /// In en, this message translates to:
  /// **'Erase strokes'**
  String get toolHintEraser;

  /// No description provided for @toolHintText.
  ///
  /// In en, this message translates to:
  /// **'Tap the canvas to add text'**
  String get toolHintText;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @landingHeadline.
  ///
  /// In en, this message translates to:
  /// **'The board your team actually finishes'**
  String get landingHeadline;

  /// No description provided for @landingSubhead.
  ///
  /// In en, this message translates to:
  /// **'Columns for tasks, pages for drawing, and a live view of who is in the room.'**
  String get landingSubhead;

  /// No description provided for @landingTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Task columns'**
  String get landingTasksTitle;

  /// No description provided for @landingTasksBody.
  ///
  /// In en, this message translates to:
  /// **'Move work from to-do to done without leaving the board.'**
  String get landingTasksBody;

  /// No description provided for @landingCanvasTitle.
  ///
  /// In en, this message translates to:
  /// **'Canvas pages'**
  String get landingCanvasTitle;

  /// No description provided for @landingCanvasBody.
  ///
  /// In en, this message translates to:
  /// **'Sketch beside the tasks, then turn to a new page.'**
  String get landingCanvasBody;

  /// No description provided for @landingPresenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is here'**
  String get landingPresenceTitle;

  /// No description provided for @landingPresenceBody.
  ///
  /// In en, this message translates to:
  /// **'See who is online, whose mic is on, and who is speaking.'**
  String get landingPresenceBody;

  /// No description provided for @landingPreviewCaption.
  ///
  /// In en, this message translates to:
  /// **'A board, not another inbox'**
  String get landingPreviewCaption;

  /// No description provided for @landingCta.
  ///
  /// In en, this message translates to:
  /// **'Open a workspace in a minute.'**
  String get landingCta;

  /// No description provided for @landingFeaturesBadge.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get landingFeaturesBadge;

  /// No description provided for @landingFeaturesHeading.
  ///
  /// In en, this message translates to:
  /// **'One place for the work'**
  String get landingFeaturesHeading;

  /// No description provided for @landingPreviewKickoff.
  ///
  /// In en, this message translates to:
  /// **'Kickoff'**
  String get landingPreviewKickoff;

  /// No description provided for @landingPreviewInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get landingPreviewInvite;

  /// No description provided for @landingPreviewLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get landingPreviewLayout;

  /// No description provided for @landingPreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get landingPreviewVoice;

  /// No description provided for @continueOffline.
  ///
  /// In en, this message translates to:
  /// **'Continue offline'**
  String get continueOffline;

  /// No description provided for @downloadAndroidApp.
  ///
  /// In en, this message translates to:
  /// **'Download Android app'**
  String get downloadAndroidApp;

  /// No description provided for @downloadAndroidAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the Android app download'**
  String get downloadAndroidAppFailed;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'Email sent'**
  String get emailSent;

  /// No description provided for @resetEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send a reset link.'**
  String get resetEmailHint;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that email, a reset link is on the way.'**
  String get resetEmailSent;

  /// No description provided for @createNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get createNewPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get enterNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordResetDone.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordResetDone;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get avatarUpdated;

  /// No description provided for @boardSettings.
  ///
  /// In en, this message translates to:
  /// **'Board settings'**
  String get boardSettings;

  /// No description provided for @deleteBoard.
  ///
  /// In en, this message translates to:
  /// **'Delete board'**
  String get deleteBoard;

  /// No description provided for @deleteBoardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this board and its tasks? This cannot be undone.'**
  String get deleteBoardConfirm;

  /// No description provided for @noMembersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No members available'**
  String get noMembersAvailable;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add a label'**
  String get addLabel;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @workspaceOverview.
  ///
  /// In en, this message translates to:
  /// **'Workspace Overview'**
  String get workspaceOverview;

  /// No description provided for @openBoardHint.
  ///
  /// In en, this message translates to:
  /// **'Click to open board'**
  String get openBoardHint;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get filterOwner;

  /// No description provided for @filterEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get filterEditor;

  /// No description provided for @filterViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get filterViewer;

  /// No description provided for @boardMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get boardMembers;

  /// No description provided for @addCollaborator.
  ///
  /// In en, this message translates to:
  /// **'Add collaborator'**
  String get addCollaborator;

  /// No description provided for @manageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get manageMembers;

  /// No description provided for @noBoardsMatchingFilter.
  ///
  /// In en, this message translates to:
  /// **'No boards match the current filter'**
  String get noBoardsMatchingFilter;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(int count);

  /// No description provided for @oneMember.
  ///
  /// In en, this message translates to:
  /// **'1 member'**
  String get oneMember;

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

  /// No description provided for @boardView.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get boardView;

  /// No description provided for @canvasView.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get canvasView;

  /// No description provided for @filterAllTasks.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAllTasks;

  /// No description provided for @sortByDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get sortByDate;

  /// No description provided for @sortByPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get sortByPriority;

  /// No description provided for @sortByTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortByTitle;

  /// No description provided for @defaultSort.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultSort;

  /// No description provided for @urgentPriority.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgentPriority;

  /// No description provided for @noTasksInColumn.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksInColumn;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @openBoard.
  ///
  /// In en, this message translates to:
  /// **'Open board'**
  String get openBoard;

  /// No description provided for @createBoardCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a new project or workflow'**
  String get createBoardCardDesc;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided'**
  String get noDescription;

  /// No description provided for @activeBoards.
  ///
  /// In en, this message translates to:
  /// **'Active boards'**
  String get activeBoards;

  /// No description provided for @pendingTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending tasks'**
  String get pendingTasks;

  /// No description provided for @completedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTasks;

  /// No description provided for @quickTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick tip'**
  String get quickTipsTitle;

  /// No description provided for @quickTipsBody.
  ///
  /// In en, this message translates to:
  /// **'Click any task card to navigate directly to its board.'**
  String get quickTipsBody;

  /// No description provided for @homeNav.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNav;

  /// No description provided for @taskBoardsNav.
  ///
  /// In en, this message translates to:
  /// **'Task Boards'**
  String get taskBoardsNav;

  /// No description provided for @projectBoardsNav.
  ///
  /// In en, this message translates to:
  /// **'Project Boards'**
  String get projectBoardsNav;

  /// No description provided for @teamWhiteboardNav.
  ///
  /// In en, this message translates to:
  /// **'Team Whiteboard'**
  String get teamWhiteboardNav;

  /// No description provided for @voiceRoomNav.
  ///
  /// In en, this message translates to:
  /// **'Voice Room'**
  String get voiceRoomNav;

  /// No description provided for @projectsAndTeams.
  ///
  /// In en, this message translates to:
  /// **'PROJECTS & TEAMS'**
  String get projectsAndTeams;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}!'**
  String greetingMorning(String name);

  /// No description provided for @greetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Have a productive day! Complete your pending tasks!'**
  String get greetingSubtitle;

  /// No description provided for @totalTasksMetric.
  ///
  /// In en, this message translates to:
  /// **'Total Tasks'**
  String get totalTasksMetric;

  /// No description provided for @inProgressMetric.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressMetric;

  /// No description provided for @completedMetric.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedMetric;

  /// No description provided for @overdueMetric.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueMetric;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get todayLabel;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @viewKanban.
  ///
  /// In en, this message translates to:
  /// **'Kanban view'**
  String get viewKanban;

  /// No description provided for @filterAction.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterAction;

  /// No description provided for @todaySchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule'**
  String get todaySchedule;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @projectMembers.
  ///
  /// In en, this message translates to:
  /// **'Project Members'**
  String get projectMembers;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Tasks'**
  String get upcomingTasks;

  /// No description provided for @overdueBadge.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueBadge;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Work together effectively'**
  String get tagline;

  /// No description provided for @todayStatsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Today you have'**
  String get todayStatsPrefix;

  /// No description provided for @tasksInProgressText.
  ///
  /// In en, this message translates to:
  /// **'tasks in progress'**
  String get tasksInProgressText;

  /// No description provided for @boardsText.
  ///
  /// In en, this message translates to:
  /// **'boards'**
  String get boardsText;

  /// No description provided for @getStartedNow.
  ///
  /// In en, this message translates to:
  /// **'Get started now'**
  String get getStartedNow;

  /// No description provided for @resourceManagement.
  ///
  /// In en, this message translates to:
  /// **'Resource management'**
  String get resourceManagement;

  /// No description provided for @resourceManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Efficient, flexible'**
  String get resourceManagementDesc;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securityDesc.
  ///
  /// In en, this message translates to:
  /// **'Safe, reliable'**
  String get securityDesc;

  /// No description provided for @highPerformance.
  ///
  /// In en, this message translates to:
  /// **'High performance'**
  String get highPerformance;

  /// No description provided for @highPerformanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Cost optimized'**
  String get highPerformanceDesc;

  /// No description provided for @easyToUse.
  ///
  /// In en, this message translates to:
  /// **'Easy to use'**
  String get easyToUse;

  /// No description provided for @easyToUseDesc.
  ///
  /// In en, this message translates to:
  /// **'Intuitive UI'**
  String get easyToUseDesc;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @dashboardTaskTip.
  ///
  /// In en, this message translates to:
  /// **'Click a task to view details and update status quickly.'**
  String get dashboardTaskTip;

  /// No description provided for @cloudWorkspaceDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your cloud resources, servers, and services easily and effectively.'**
  String get cloudWorkspaceDefaultDesc;

  /// No description provided for @searchMembersPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchMembersPlaceholder;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @columnMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get columnMember;

  /// No description provided for @columnRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get columnRole;

  /// No description provided for @columnTasks.
  ///
  /// In en, this message translates to:
  /// **'Assigned tasks'**
  String get columnTasks;

  /// No description provided for @columnStatus.
  ///
  /// In en, this message translates to:
  /// **'Activity status'**
  String get columnStatus;

  /// No description provided for @columnActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get columnActions;

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this member from the workspace?'**
  String get removeMemberConfirm;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No matching members found'**
  String get noMembersFound;

  /// No description provided for @inviteSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully!'**
  String get inviteSentSuccess;

  /// No description provided for @memberRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Member role updated successfully!'**
  String get memberRoleUpdated;

  /// No description provided for @memberRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Member removed from workspace'**
  String get memberRemovedSuccess;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @projectSettings.
  ///
  /// In en, this message translates to:
  /// **'Project Settings'**
  String get projectSettings;

  /// No description provided for @projectInfoTab.
  ///
  /// In en, this message translates to:
  /// **'Project Information'**
  String get projectInfoTab;

  /// No description provided for @membersPermissionsTab.
  ///
  /// In en, this message translates to:
  /// **'Members & Permissions'**
  String get membersPermissionsTab;

  /// No description provided for @workflowTab.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get workflowTab;

  /// No description provided for @timelineProgressTab.
  ///
  /// In en, this message translates to:
  /// **'Timeline & Progress'**
  String get timelineProgressTab;

  /// No description provided for @accessControlTab.
  ///
  /// In en, this message translates to:
  /// **'Access Control'**
  String get accessControlTab;

  /// No description provided for @archiveDeleteTab.
  ///
  /// In en, this message translates to:
  /// **'Archive & Delete'**
  String get archiveDeleteTab;

  /// No description provided for @ownerOnlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Owner Access Only'**
  String get ownerOnlyAccess;

  /// No description provided for @ownerOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Only the project owner has permission to view and modify these settings.'**
  String get ownerOnlyDesc;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @projectDescription.
  ///
  /// In en, this message translates to:
  /// **'Project Description'**
  String get projectDescription;

  /// No description provided for @projectOwner.
  ///
  /// In en, this message translates to:
  /// **'Project Owner'**
  String get projectOwner;

  /// No description provided for @archiveProject.
  ///
  /// In en, this message translates to:
  /// **'Archive Project'**
  String get archiveProject;

  /// No description provided for @archiveProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Archive this completed project. It will become read-only.'**
  String get archiveProjectDesc;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// No description provided for @deleteProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this project and all associated boards, tasks, and data.'**
  String get deleteProjectDesc;

  /// No description provided for @deleteConfirmPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type project name to confirm'**
  String get deleteConfirmPrompt;

  /// No description provided for @workBoards.
  ///
  /// In en, this message translates to:
  /// **'Work Boards'**
  String get workBoards;

  /// No description provided for @workBoardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage and track your projects.'**
  String get workBoardsDesc;

  /// No description provided for @renameBoard.
  ///
  /// In en, this message translates to:
  /// **'Rename board'**
  String get renameBoard;

  /// No description provided for @editDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit description'**
  String get editDescription;

  /// No description provided for @archiveBoard.
  ///
  /// In en, this message translates to:
  /// **'Archive board'**
  String get archiveBoard;

  /// No description provided for @archiveBoardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive this board?'**
  String get archiveBoardConfirm;

  /// No description provided for @sortByRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get sortByRecent;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortByName;

  /// No description provided for @filterAllStatus.
  ///
  /// In en, this message translates to:
  /// **'All status'**
  String get filterAllStatus;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get filterActive;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @yourTasks.
  ///
  /// In en, this message translates to:
  /// **'Your Tasks'**
  String get yourTasks;

  /// No description provided for @yourTasksDesc.
  ///
  /// In en, this message translates to:
  /// **'View and manage all tasks assigned to you.'**
  String get yourTasksDesc;

  /// No description provided for @noTasksMatchingFilter.
  ///
  /// In en, this message translates to:
  /// **'No tasks match your filter'**
  String get noTasksMatchingFilter;

  /// No description provided for @allBoards.
  ///
  /// In en, this message translates to:
  /// **'All boards'**
  String get allBoards;

  /// No description provided for @filterDoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get filterDoing;

  /// No description provided for @filterTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get filterTodo;

  /// No description provided for @filterDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterDone;

  /// No description provided for @filterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get filterOverdue;

  /// No description provided for @taskDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get taskDeadline;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @roomMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'ROOM MEMBERS ({count})'**
  String roomMembersTitle(int count);

  /// No description provided for @quickDiscussionNotes.
  ///
  /// In en, this message translates to:
  /// **'Quick discussion notes'**
  String get quickDiscussionNotes;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUser;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @renamePage.
  ///
  /// In en, this message translates to:
  /// **'Rename page'**
  String get renamePage;

  /// No description provided for @deletePage.
  ///
  /// In en, this message translates to:
  /// **'Delete page'**
  String get deletePage;

  /// No description provided for @deletePageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this page?'**
  String get deletePageConfirm;

  /// No description provided for @cannotDeleteLastPage.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the last page'**
  String get cannotDeleteLastPage;

  /// No description provided for @pageNameExists.
  ///
  /// In en, this message translates to:
  /// **'Page name already exists'**
  String get pageNameExists;

  /// No description provided for @pageNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Page name cannot be empty'**
  String get pageNameEmpty;

  /// No description provided for @pageTitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pageTitlePrefix;

  /// No description provided for @autoSyncP2P.
  ///
  /// In en, this message translates to:
  /// **'Auto-sync P2P 0.1s'**
  String get autoSyncP2P;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave room'**
  String get leaveRoom;

  /// No description provided for @leaveRoomConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect and leave the voice room?'**
  String get leaveRoomConfirm;

  /// No description provided for @clearCanvasConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all drawings and shapes on this page?'**
  String get clearCanvasConfirm;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @undoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo (Ctrl+Z)'**
  String get undoTooltip;

  /// No description provided for @redoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Redo (Ctrl+Shift+Z)'**
  String get redoTooltip;

  /// No description provided for @toolSelect.
  ///
  /// In en, this message translates to:
  /// **'Select (V)'**
  String get toolSelect;

  /// No description provided for @toolHand.
  ///
  /// In en, this message translates to:
  /// **'Pan (H)'**
  String get toolHand;

  /// No description provided for @toolPen.
  ///
  /// In en, this message translates to:
  /// **'Pen (P)'**
  String get toolPen;

  /// No description provided for @toolEraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser (E)'**
  String get toolEraser;

  /// No description provided for @toolRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle (R)'**
  String get toolRectangle;

  /// No description provided for @toolCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle (O)'**
  String get toolCircle;

  /// No description provided for @toolArrow.
  ///
  /// In en, this message translates to:
  /// **'Arrow (A)'**
  String get toolArrow;

  /// No description provided for @toolStickyNote.
  ///
  /// In en, this message translates to:
  /// **'Sticky note (N)'**
  String get toolStickyNote;

  /// No description provided for @toolText.
  ///
  /// In en, this message translates to:
  /// **'Text (T)'**
  String get toolText;

  /// No description provided for @toolKanban.
  ///
  /// In en, this message translates to:
  /// **'Add Kanban card (K)'**
  String get toolKanban;

  /// No description provided for @filterAssignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee:'**
  String get filterAssignee;

  /// No description provided for @filterPriorityAll.
  ///
  /// In en, this message translates to:
  /// **'Priority: All'**
  String get filterPriorityAll;

  /// No description provided for @filterPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get filterPriorityUrgent;

  /// No description provided for @filterPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get filterPriorityHigh;

  /// No description provided for @filterPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get filterPriorityMedium;

  /// No description provided for @filterPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get filterPriorityLow;

  /// No description provided for @addColumn.
  ///
  /// In en, this message translates to:
  /// **'Add column'**
  String get addColumn;

  /// No description provided for @addNewCard.
  ///
  /// In en, this message translates to:
  /// **'Add new card'**
  String get addNewCard;

  /// No description provided for @onlinePeople.
  ///
  /// In en, this message translates to:
  /// **'{count} online'**
  String onlinePeople(int count);

  /// No description provided for @voiceLive.
  ///
  /// In en, this message translates to:
  /// **'Voice live'**
  String get voiceLive;

  /// No description provided for @quickMeetP2P.
  ///
  /// In en, this message translates to:
  /// **'P2P Quick Meet'**
  String get quickMeetP2P;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search tasks, meeting notes, drawings...'**
  String get searchPlaceholder;

  /// No description provided for @searchFilterPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Filter project cards...'**
  String get searchFilterPlaceholder;

  /// No description provided for @exportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportAction;

  /// No description provided for @createNewAction.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get createNewAction;

  /// No description provided for @createTaskCTA.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTaskCTA;

  /// No description provided for @enterPageName.
  ///
  /// In en, this message translates to:
  /// **'Enter page name...'**
  String get enterPageName;

  /// No description provided for @createNewTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new task'**
  String get createNewTaskTitle;

  /// No description provided for @editTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTaskTitle;

  /// No description provided for @taskDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a task to track the progress of your work and your team.'**
  String get taskDialogSubtitle;

  /// No description provided for @taskNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskNameLabel;

  /// No description provided for @taskNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter task name...'**
  String get taskNamePlaceholder;

  /// No description provided for @taskNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter task name'**
  String get taskNameRequired;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a detailed description of the task...'**
  String get descriptionPlaceholder;

  /// No description provided for @listLabel.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listLabel;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get statusTodo;

  /// No description provided for @statusDoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusDoing;

  /// No description provided for @statusReview.
  ///
  /// In en, this message translates to:
  /// **'Review / Testing'**
  String get statusReview;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @assigneeLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assigneeLabel;

  /// No description provided for @selectMemberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select member...'**
  String get selectMemberPlaceholder;

  /// No description provided for @labelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDateLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDateLabel;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @setReminder.
  ///
  /// In en, this message translates to:
  /// **'Set reminder'**
  String get setReminder;

  /// No description provided for @repeatIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatIntervalLabel;

  /// No description provided for @doesNotRepeat.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get doesNotRepeat;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @attachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsLabel;

  /// No description provided for @dragAndDropFiles.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop files here or choose a file'**
  String get dragAndDropFiles;

  /// No description provided for @fileSupportHint.
  ///
  /// In en, this message translates to:
  /// **'Supports JPG, PNG, PDF, DOC... (max 10MB)'**
  String get fileSupportHint;

  /// No description provided for @quickCreationTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick task creation'**
  String get quickCreationTitle;

  /// No description provided for @quickCreationBody.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details and press \"Create task\" to save and get started.'**
  String get quickCreationBody;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @previewDescriptionDefault.
  ///
  /// In en, this message translates to:
  /// **'Task description...'**
  String get previewDescriptionDefault;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @notifyMembers.
  ///
  /// In en, this message translates to:
  /// **'Notify members'**
  String get notifyMembers;

  /// No description provided for @addToSprintPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to sprint plan'**
  String get addToSprintPlan;

  /// No description provided for @formatBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get formatItalic;

  /// No description provided for @formatUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get formatUnderline;

  /// No description provided for @formatBulletList.
  ///
  /// In en, this message translates to:
  /// **'Bullet list'**
  String get formatBulletList;

  /// No description provided for @formatNumberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get formatNumberedList;

  /// No description provided for @formatLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get formatLink;

  /// No description provided for @formatImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get formatImage;

  /// No description provided for @formatCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get formatCode;

  /// No description provided for @dueDateMustBeAfterStartDate.
  ///
  /// In en, this message translates to:
  /// **'Due date must be after or on start date'**
  String get dueDateMustBeAfterStartDate;

  /// No description provided for @closeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close (ESC)'**
  String get closeTooltip;

  /// No description provided for @columnTodo.
  ///
  /// In en, this message translates to:
  /// **'TO DO'**
  String get columnTodo;

  /// No description provided for @columnDoing.
  ///
  /// In en, this message translates to:
  /// **'IN PROGRESS'**
  String get columnDoing;

  /// No description provided for @columnReview.
  ///
  /// In en, this message translates to:
  /// **'REVIEW / TESTING'**
  String get columnReview;

  /// No description provided for @columnDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get columnDone;

  /// No description provided for @priorityBadgeUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityBadgeUrgent;

  /// No description provided for @priorityBadgeHigh.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get priorityBadgeHigh;

  /// No description provided for @priorityBadgeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium priority'**
  String get priorityBadgeMedium;

  /// No description provided for @priorityBadgeLow.
  ///
  /// In en, this message translates to:
  /// **'Low priority'**
  String get priorityBadgeLow;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String dateFrom(String date);

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'To {date}'**
  String dateTo(String date);

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @typeDiscussionNote.
  ///
  /// In en, this message translates to:
  /// **'Type a note (Enter)...'**
  String get typeDiscussionNote;

  /// No description provided for @noDiscussionNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet. Type and press Post.'**
  String get noDiscussionNotes;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance (Theme)'**
  String get themeModeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @canvasRestored.
  ///
  /// In en, this message translates to:
  /// **'Canvas restored'**
  String get canvasRestored;

  /// No description provided for @taskCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get taskCreatedToast;

  /// No description provided for @taskUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdatedToast;

  /// No description provided for @taskDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeletedToast;

  /// No description provided for @addTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Add text'**
  String get addTextTitle;

  /// No description provided for @enterTextHint.
  ///
  /// In en, this message translates to:
  /// **'Type your text...'**
  String get enterTextHint;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @addStickyNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Add sticky note'**
  String get addStickyNoteTitle;

  /// No description provided for @enterNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Type a note...'**
  String get enterNoteHint;

  /// No description provided for @pasteNote.
  ///
  /// In en, this message translates to:
  /// **'Paste note'**
  String get pasteNote;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Cannot access the microphone. Please allow microphone permission.'**
  String get micPermissionDenied;

  /// No description provided for @micError.
  ///
  /// In en, this message translates to:
  /// **'Microphone error: {error}'**
  String micError(String error);

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// No description provided for @accountAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Account & settings'**
  String get accountAndSettings;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @pageListRename.
  ///
  /// In en, this message translates to:
  /// **'Pages / rename'**
  String get pageListRename;

  /// No description provided for @addKanbanCard.
  ///
  /// In en, this message translates to:
  /// **'Add Kanban card'**
  String get addKanbanCard;

  /// No description provided for @closePanel.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get closePanel;

  /// No description provided for @collapsePanel.
  ///
  /// In en, this message translates to:
  /// **'Collapse panel'**
  String get collapsePanel;

  /// No description provided for @hostBadge.
  ///
  /// In en, this message translates to:
  /// **'HOST'**
  String get hostBadge;

  /// No description provided for @peerBadge.
  ///
  /// In en, this message translates to:
  /// **'PEER'**
  String get peerBadge;

  /// No description provided for @micOn.
  ///
  /// In en, this message translates to:
  /// **'Mic on'**
  String get micOn;

  /// No description provided for @micOff.
  ///
  /// In en, this message translates to:
  /// **'Mic off'**
  String get micOff;

  /// No description provided for @muteMic.
  ///
  /// In en, this message translates to:
  /// **'Mute mic'**
  String get muteMic;

  /// No description provided for @unmuteMic.
  ///
  /// In en, this message translates to:
  /// **'Unmute mic'**
  String get unmuteMic;

  /// No description provided for @muteAudio.
  ///
  /// In en, this message translates to:
  /// **'Mute audio'**
  String get muteAudio;

  /// No description provided for @unmuteAudio.
  ///
  /// In en, this message translates to:
  /// **'Unmute audio'**
  String get unmuteAudio;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get listening;

  /// No description provided for @newTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTaskTitle;

  /// No description provided for @deadlineBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The due date must be on or after the start date'**
  String get deadlineBeforeStart;

  /// No description provided for @sprintHint.
  ///
  /// In en, this message translates to:
  /// **'Attach the task directly to the sprint cycle.'**
  String get sprintHint;

  /// No description provided for @checklistLabel.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklistLabel;

  /// No description provided for @checklistHint.
  ///
  /// In en, this message translates to:
  /// **'Add steps to complete this task. Mark them done as you go.'**
  String get checklistHint;

  /// No description provided for @addChecklistStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addChecklistStep;

  /// No description provided for @removeChecklistStep.
  ///
  /// In en, this message translates to:
  /// **'Remove step'**
  String get removeChecklistStep;

  /// No description provided for @taskNotesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Notes for this task (optional)...'**
  String get taskNotesPlaceholder;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Click to upload images'**
  String get uploadImages;

  /// No description provided for @imageSupportHint.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG, WEBP, GIF - max 10MB each'**
  String get imageSupportHint;

  /// No description provided for @imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{name} is larger than 10MB'**
  String imageTooLarge(String name);

  /// No description provided for @uploadingImages.
  ///
  /// In en, this message translates to:
  /// **'Uploading images...'**
  String get uploadingImages;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeAttachment;

  /// No description provided for @helpNav.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpNav;

  /// No description provided for @searchWorkspacesHint.
  ///
  /// In en, this message translates to:
  /// **'Search workspaces...'**
  String get searchWorkspacesHint;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
