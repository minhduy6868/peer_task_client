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
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordMinLength8 => 'Password must be at least 8 characters';

  @override
  String get passwordRequireUppercase =>
      'Password must contain at least 1 uppercase letter';

  @override
  String get passwordRequireLowercase =>
      'Password must contain at least 1 lowercase letter';

  @override
  String get passwordRequireDigit => 'Password must contain at least 1 digit';

  @override
  String get passwordConfirmRequired => 'Please confirm your password';

  @override
  String get passwordNotMatch => 'Passwords do not match';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get nameMaxLength => 'Name cannot exceed 50 characters';

  @override
  String get nameLettersOnly => 'Name can only contain letters';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String fieldMinLength(String field, int min) {
    return '$field must be at least $min characters';
  }

  @override
  String fieldMaxLength(String field, int max) {
    return '$field cannot exceed $max characters';
  }

  @override
  String get phoneNumberRequired => 'Phone number is required';

  @override
  String get phoneNumberInvalid => 'Invalid phone number';

  @override
  String get urlRequired => 'URL is required';

  @override
  String get urlInvalid => 'Invalid URL';

  @override
  String get numberRequired => 'This field is required';

  @override
  String get numberInvalid => 'This field must be a number';

  @override
  String get integerInvalid => 'This field must be an integer';

  @override
  String valueMin(String field, num min) {
    return '$field must be greater than or equal to $min';
  }

  @override
  String valueMax(String field, num max) {
    return '$field must be less than or equal to $max';
  }

  @override
  String valueRange(String field, num min, num max) {
    return '$field must be between $min and $max';
  }

  @override
  String get workspaceNameRequired => 'Workspace name is required';

  @override
  String get workspaceNameMinLength =>
      'Workspace name must be at least 3 characters';

  @override
  String get workspaceNameMaxLength =>
      'Workspace name cannot exceed 50 characters';

  @override
  String get taskTitleRequired => 'Task title is required';

  @override
  String get taskTitleMaxLength => 'Task title cannot exceed 200 characters';

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

  @override
  String get taskCard => 'Task Card';

  @override
  String get untitled => 'Untitled';

  @override
  String get overdue => 'Overdue';

  @override
  String get dueDate => 'Due date';

  @override
  String get assignees => 'Assignees';

  @override
  String moreAssignees(int count) {
    return '$count more';
  }

  @override
  String get move => 'Move';

  @override
  String get moveTask => 'Move Task';

  @override
  String get urgent => 'Urgent';

  @override
  String get labels => 'Labels';

  @override
  String get deadline => 'Deadline';

  @override
  String get estimatedHours => 'Estimated Hours';

  @override
  String get actualHours => 'Actual Hours';

  @override
  String get createdBy => 'Created by';

  @override
  String get updatedAt => 'Updated at';

  @override
  String get createTask => 'Create Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get deleteTask => 'Delete Task';

  @override
  String get deleteTaskConfirm => 'Are you sure you want to delete this task?';

  @override
  String get todoColumn => 'To Do';

  @override
  String get doingColumn => 'Doing';

  @override
  String get doneColumn => 'Done';

  @override
  String taskCount(int count) {
    return '$count tasks';
  }

  @override
  String get noTasks => 'No tasks yet';

  @override
  String get addFirstTask => 'Add your first task to get started';

  @override
  String get aiBrainstorm => 'AI Brainstorm';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get aiThinking => 'Thinking...';

  @override
  String get aiConnected => 'AI Connected';

  @override
  String get aiDisconnected => 'AI Disconnected';

  @override
  String get aiConnectionError => 'Cannot connect to Ollama';

  @override
  String get aiConnectionErrorHint =>
      'Make sure Ollama is running (ollama serve)';

  @override
  String get aiRetryConnection => 'Retry Connection';

  @override
  String get brainstormMode => 'Brainstorm';

  @override
  String get brainstormHint => 'Expand ideas';

  @override
  String get tasksMode => 'Tasks';

  @override
  String get tasksHint => 'Generate task list';

  @override
  String get improveMode => 'Improve';

  @override
  String get improveHint => 'Improve text';

  @override
  String get enterIdeaToBrainstorm => 'Enter idea to brainstorm...';

  @override
  String get describeProjectForTasks => 'Describe project to generate tasks...';

  @override
  String get enterTextToImprove => 'Enter text to improve...';

  @override
  String get addToBoard => 'Add to Board';

  @override
  String get addedToCanvas => 'Added to canvas!';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied!';

  @override
  String get mainIdea => 'Main Idea';

  @override
  String get relatedIdeas => 'Related Ideas';

  @override
  String get connections => 'Connections';

  @override
  String get nextActions => 'Next Actions';

  @override
  String get questionsToConsider => 'Questions to Consider';

  @override
  String get highPriority => 'High Priority';

  @override
  String get mediumPriority => 'Medium Priority';

  @override
  String get lowPriority => 'Low Priority';

  @override
  String get taskList => 'Task List';

  @override
  String get summary => 'Summary';

  @override
  String get totalTasks => 'Total Tasks';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get improvedText => 'Improved Text';

  @override
  String get changes => 'Changes';

  @override
  String get dragToMove => 'Drag to move';

  @override
  String get clickToSelect => 'Click to select';

  @override
  String get textAddedToBoard => 'Text added to board';

  @override
  String get voiceCall => 'Voice Call';

  @override
  String get startVoiceCall => 'Start Voice Call';

  @override
  String get endVoiceCall => 'End Voice Call';

  @override
  String get microphonePermissionDenied => 'Microphone permission denied';

  @override
  String get screenshot => 'Screenshot';

  @override
  String get screenshotSaved => 'Screenshot saved!';

  @override
  String get screenshotFailed => 'Failed to capture screenshot';

  @override
  String get canvasAndKanban => 'Canvas + Kanban';

  @override
  String get showKanban => 'Show Kanban';

  @override
  String get hideKanban => 'Hide Kanban';

  @override
  String get backToBoards => 'Back to boards';
}
