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
  /// **'Sign in with email address'**
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
  /// **'Yourname@gmail.com'**
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
  /// **'Invite by Email'**
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
  /// **'Remove Member'**
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

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

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

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Task title is required'**
  String get taskTitleRequired;

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
  /// **'Save Changes'**
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
