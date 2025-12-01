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
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

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
  String get signInTitle => 'SIGN IN';

  @override
  String get signUpTitle => 'SIGN UP';

  @override
  String get signInSubtitle => 'Sign in with email address';

  @override
  String get signUpSubtitle => 'Create your account to get started';

  @override
  String get signInToAdventure => 'SIGN IN TO YOUR\nADVENTURE!';

  @override
  String get startYourAdventure => 'START YOUR\nADVENTURE!';

  @override
  String get collaborativeDescription =>
      'Collaborate seamlessly with your team\non P2P whiteboards and task boards';

  @override
  String get realTimeCollaboration => 'Real-time collaboration';

  @override
  String get secureP2P => 'Secure P2P connection';

  @override
  String get crossPlatform => 'Cross-platform support';

  @override
  String get emailPlaceholder => 'Yourname@gmail.com';

  @override
  String get passwordPlaceholder => 'Password';

  @override
  String get namePlaceholder => 'Your Name (optional)';

  @override
  String get createAccount => 'Create Account';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get google => 'Google';

  @override
  String get facebook => 'Facebook';

  @override
  String get byRegistering =>
      'By registering you with our Terms and Conditions';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

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
  String get myBoards => 'My Boards';

  @override
  String get newBoard => 'New Board';

  @override
  String get createNewBoard => 'Create New Board';

  @override
  String get enterBoardName => 'Enter a creative name...';

  @override
  String get boardDescriptionOptional => 'What is this board about?';

  @override
  String boardCreatedSuccess(Object name) {
    return 'Board \"$name\" created successfully!';
  }

  @override
  String get noBoardsYet => 'No boards yet';

  @override
  String get createFirstBoard =>
      'Create your first board to start collaborating';

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
  String get retry => 'Retry';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get networkError => 'Network error. Please check your connection.';

  @override
  String get connectionError => 'Connection failed. Please try again.';

  @override
  String get timeoutError => 'Request timeout. Please try again.';

  @override
  String get unknownError => 'An unexpected error occurred. Please try again.';

  @override
  String get validationError => 'Invalid input. Please check your data.';

  @override
  String get permissionDenied =>
      'You don\'t have permission to perform this action';

  @override
  String get notFound => 'Resource not found';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get taskSavedSuccess => 'Task saved successfully';

  @override
  String get taskUpdatedSuccess => 'Task updated successfully';

  @override
  String get taskDeletedSuccess => 'Task deleted successfully';

  @override
  String get taskSaveError => 'Failed to save task';

  @override
  String get taskUpdateError => 'Failed to update task';

  @override
  String get taskDeleteError => 'Failed to delete task';

  @override
  String get taskTitleRequired => 'Task title is required';

  @override
  String get boardUpdatedSuccess => 'Board updated successfully';

  @override
  String get boardDeletedSuccess => 'Board deleted successfully';

  @override
  String get boardUpdateError => 'Failed to update board';

  @override
  String get boardDeleteError => 'Failed to delete board';

  @override
  String get boardDeleteConfirm =>
      'Are you sure you want to delete this board?';

  @override
  String get boardNameRequired => 'Board name is required';

  @override
  String get operationSuccess => 'Operation completed successfully';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get processing => 'Processing...';

  @override
  String get workspace => 'Workspace';

  @override
  String get workspaceInfo => 'Workspace Info';

  @override
  String get workspaceSettings => 'Workspace Settings';

  @override
  String get changeWorkspace => 'Change Workspace';

  @override
  String get leaveWorkspace => 'Leave Workspace';

  @override
  String get deleteWorkspace => 'Delete Workspace';

  @override
  String get leaveWorkspaceConfirm =>
      'Are you sure you want to leave this workspace?';

  @override
  String get deleteWorkspaceConfirm =>
      'Are you sure you want to delete this workspace? This action cannot be undone.';

  @override
  String get workspaceUpdated => 'Workspace updated';

  @override
  String get workspaceDeleted => 'Workspace deleted';

  @override
  String get memberRemoved => 'Member removed';

  @override
  String get roleUpdated => 'Role updated';

  @override
  String get inviteRevoked => 'Invite revoked';

  @override
  String get inviteCodeCreated => 'Invite Code Created';

  @override
  String get shareCodeToInvite => 'Share this code to invite members:';

  @override
  String get scanQROrCopy => '• Scan QR code\n• Or copy and paste the code';

  @override
  String get inviteCode => 'Invite Code';

  @override
  String get copyCode => 'Copy Code';

  @override
  String get codeCopied => '✅ Code copied to clipboard';

  @override
  String get close => 'Close';

  @override
  String get general => 'General';

  @override
  String get invites => 'Invites';

  @override
  String get createInviteLink => 'Create Invite Link';

  @override
  String get noActiveInvites => 'No active invites';

  @override
  String get expired => 'Expired';

  @override
  String get expires => 'Expires';

  @override
  String get invite => 'Invite';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAllData =>
      'Are you sure? This will delete all boards, tasks, and data. This action cannot be undone.';

  @override
  String get makeAdmin => 'Make Admin';

  @override
  String get makeMember => 'Make Member';

  @override
  String get remove => 'Remove';

  @override
  String get useInviteLinkToAdd => 'Use invite link to add members';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get role => 'Role';

  @override
  String errorLoadingMembers(Object error) {
    return 'Error loading members: $error';
  }

  @override
  String get welcome => 'Welcome!';

  @override
  String get noWorkspaceYet => 'You don\'t have any workspace yet';

  @override
  String get createOrJoinWorkspace =>
      'Create a new workspace or join an existing one to get started';

  @override
  String get create => 'Create';

  @override
  String get join => 'Join';

  @override
  String get yourWorkspaces => 'Your Workspaces';

  @override
  String get selectWorkspace => 'Select a workspace to continue';

  @override
  String get enterWorkspaceName => 'Enter workspace name';
}
