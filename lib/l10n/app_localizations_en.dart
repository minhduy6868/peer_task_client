// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PeerTask';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get name => 'Name';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get logout => 'Logout';

  @override
  String get workspaces => 'Workspaces';

  @override
  String get createWorkspace => 'Create Workspace';

  @override
  String get workspaceName => 'Workspace Name';

  @override
  String get boards => 'Boards';

  @override
  String get createBoard => 'Create Board';

  @override
  String get boardName => 'Board Name';

  @override
  String get boardDescription => 'Board Description';

  @override
  String get inviteMembers => 'Invite Members';

  @override
  String get inviteLink => 'Invite Link';

  @override
  String get inviteByEmail => 'Invite by Email';

  @override
  String get joinWorkspace => 'Join Workspace';

  @override
  String get scanQR => 'Scan QR';

  @override
  String get generateInviteLink => 'Generate Invite Link';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get share => 'Share';

  @override
  String get linkCopied => 'Link copied to clipboard!';

  @override
  String get expiresIn => 'Expires in';

  @override
  String get maxUses => 'Max uses';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get never => 'Never';

  @override
  String hours(Object count) {
    return '$count hours';
  }

  @override
  String days(Object count) {
    return '$count days';
  }

  @override
  String uses(Object count) {
    return '$count uses';
  }

  @override
  String get scanQRToJoin => 'Scan QR code to join';

  @override
  String get enterInviteLink => 'Enter Invite Link';

  @override
  String get joinedSuccessfully => 'Successfully joined workspace!';

  @override
  String get whiteboard => 'Whiteboard';

  @override
  String get drawingTools => 'Drawing Tools';

  @override
  String get select => 'Select';

  @override
  String get pen => 'Pen';

  @override
  String get eraser => 'Eraser';

  @override
  String get rectangle => 'Rectangle';

  @override
  String get circle => 'Circle';

  @override
  String get line => 'Line';

  @override
  String get arrow => 'Arrow';

  @override
  String get text => 'Text';

  @override
  String get stickyNote => 'Sticky Note';

  @override
  String get taskNode => 'Task Node';

  @override
  String get color => 'Color';

  @override
  String get strokeWidth => 'Stroke Width';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get clear => 'Clear';

  @override
  String get properties => 'Properties';

  @override
  String get noObjectSelected => 'No object selected';

  @override
  String get selectObjectToEdit => 'Select an object to edit properties';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get status => 'Status';

  @override
  String get priority => 'Priority';

  @override
  String get position => 'Position';

  @override
  String get delete => 'Delete';

  @override
  String get taskStatus => 'Task Status';

  @override
  String get todo => 'To Do';

  @override
  String get inProgress => 'In Progress';

  @override
  String get done => 'Done';

  @override
  String get blocked => 'Blocked';

  @override
  String get taskPriority => 'Task Priority';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get peers => 'Peers';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get profile => 'Profile';

  @override
  String get about => 'About';

  @override
  String get hybridBoard => 'Hybrid Board';

  @override
  String get canvas => 'Canvas';

  @override
  String get tasks => 'Tasks';

  @override
  String get draw => 'Draw';

  @override
  String get pan => 'Pan';

  @override
  String get clearCanvas => 'Clear Canvas';

  @override
  String get hideTasks => 'Hide Tasks';

  @override
  String get showTasks => 'Show Tasks';

  @override
  String get addTask => 'Add Task';

  @override
  String get taskTitle => 'Task title...';

  @override
  String get assignee => 'Assignee';

  @override
  String get assigneeName => 'Assignee name...';

  @override
  String get start => 'Start';

  @override
  String get complete => 'Complete';

  @override
  String get pending => 'Pending';

  @override
  String get doing => 'Doing';

  @override
  String get empty => 'Empty';

  @override
  String get members => 'Members';

  @override
  String get addMember => 'Add Member';

  @override
  String get removeMember => 'Remove Member';

  @override
  String get changeRole => 'Change Role';

  @override
  String get changePermission => 'Change Permission';

  @override
  String get owner => 'Owner';

  @override
  String get admin => 'Admin';

  @override
  String get member => 'Member';

  @override
  String get editor => 'Editor';

  @override
  String get viewer => 'Viewer';

  @override
  String get edit => 'Edit';

  @override
  String get view => 'View';

  @override
  String get permissions => 'Permissions';

  @override
  String get workspaceRole => 'Workspace Role';

  @override
  String get boardPermission => 'Board Permission';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading...';

  @override
  String get serverError => 'Server error';

  @override
  String get networkError => 'Network error';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get nameRequired => 'Name is required';
}
