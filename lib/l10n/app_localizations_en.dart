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
  String get signInSubtitle => 'Welcome back! Please sign in to continue';

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
  String get emailPlaceholder => 'Your email address';

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
  String get rememberMe => 'Remember me';

  @override
  String get termsAgreement =>
      'I agree to the Terms of Service and Privacy Policy';

  @override
  String get termsAgreementRequired =>
      'Please agree to the Terms of Service and Privacy Policy to continue';

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
  String get searchBoards => 'Search boards';

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
  String get inviteByEmail => 'Invite by email';

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
  String get removeMember => 'Remove member';

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
  String get saveChanges => 'Save changes';

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
  String get yourWork => 'Your work';

  @override
  String get nothingAssigned => 'Nothing is assigned to you in this workspace.';

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
  String get createTask => 'Create task';

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
  String get noTasks => 'No tasks';

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

  @override
  String get saveDraft => 'Save draft to server';

  @override
  String get draftSaved => 'Draft saved to server';

  @override
  String get draftRestored =>
      'Unsaved strokes were recovered and saved to the server';

  @override
  String get unsavedDraft => 'Not saved to server yet';

  @override
  String get discardDraft => 'Discard local backup';

  @override
  String get discardDraftConfirm =>
      'Delete the local backup only? The canvas on the server stays as it is.';

  @override
  String draftSavedAt(String time) {
    return 'Saved · $time';
  }

  @override
  String get addText => 'Add text';

  @override
  String get enterText => 'Enter text…';

  @override
  String get textSize => 'Text size';

  @override
  String get width => 'Width';

  @override
  String get you => 'You';

  @override
  String get addPage => 'Add page';

  @override
  String get pageLabel => 'Page';

  @override
  String get speaking => 'Speaking';

  @override
  String get toolHintPen => 'Draw on the canvas';

  @override
  String get toolHintEraser => 'Erase strokes';

  @override
  String get toolHintText => 'Tap the canvas to add text';

  @override
  String get getStarted => 'Get started';

  @override
  String get landingHeadline => 'The board your team actually finishes';

  @override
  String get landingSubhead =>
      'Columns for tasks, pages for drawing, and a live view of who is in the room.';

  @override
  String get landingTasksTitle => 'Task columns';

  @override
  String get landingTasksBody =>
      'Move work from to-do to done without leaving the board.';

  @override
  String get landingCanvasTitle => 'Canvas pages';

  @override
  String get landingCanvasBody =>
      'Sketch beside the tasks, then turn to a new page.';

  @override
  String get landingPresenceTitle => 'Who is here';

  @override
  String get landingPresenceBody =>
      'See who is online, whose mic is on, and who is speaking.';

  @override
  String get landingPreviewCaption => 'A board, not another inbox';

  @override
  String get landingCta => 'Open a workspace in a minute.';

  @override
  String get landingFeaturesBadge => 'Features';

  @override
  String get landingFeaturesHeading => 'One place for the work';

  @override
  String get landingPreviewKickoff => 'Kickoff';

  @override
  String get landingPreviewInvite => 'Invite';

  @override
  String get landingPreviewLayout => 'Layout';

  @override
  String get landingPreviewVoice => 'Voice';

  @override
  String get continueOffline => 'Continue offline';

  @override
  String get downloadAndroidApp => 'Download Android app';

  @override
  String get downloadAndroidAppFailed =>
      'Could not start the Android app download';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get emailSent => 'Email sent';

  @override
  String get resetEmailHint =>
      'Enter your email and we will send a reset link.';

  @override
  String get resetEmailSent =>
      'If an account exists for that email, a reset link is on the way.';

  @override
  String get createNewPassword => 'Create a new password';

  @override
  String get enterNewPassword => 'Enter your new password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordResetDone => 'Password updated';

  @override
  String get changePassword => 'Change password';

  @override
  String get avatarUpdated => 'Avatar updated';

  @override
  String get boardSettings => 'Board settings';

  @override
  String get deleteBoard => 'Delete board';

  @override
  String get deleteBoardConfirm =>
      'Delete this board and its tasks? This cannot be undone.';

  @override
  String get noMembersAvailable => 'No members available';

  @override
  String get addLabel => 'Add a label';

  @override
  String get selectDate => 'Select date';

  @override
  String get workspaceOverview => 'Workspace Overview';

  @override
  String get openBoardHint => 'Click to open board';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get all => 'All';

  @override
  String get filterAll => 'All';

  @override
  String get filterOwner => 'Owner';

  @override
  String get filterEditor => 'Editor';

  @override
  String get filterViewer => 'Viewer';

  @override
  String get boardMembers => 'Members';

  @override
  String get addCollaborator => 'Add collaborator';

  @override
  String get manageMembers => 'Manage members';

  @override
  String get noBoardsMatchingFilter => 'No boards match the current filter';

  @override
  String get clearFilter => 'Clear filter';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get oneMember => '1 member';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get boardView => 'Board';

  @override
  String get canvasView => 'Canvas';

  @override
  String get filterAllTasks => 'All';

  @override
  String get sortByDate => 'Due date';

  @override
  String get sortByPriority => 'Priority';

  @override
  String get sortByTitle => 'Title';

  @override
  String get defaultSort => 'Default';

  @override
  String get urgentPriority => 'Urgent';

  @override
  String get noTasksInColumn => 'No tasks yet';

  @override
  String get search => 'Search';

  @override
  String get openBoard => 'Open board';

  @override
  String get createBoardCardDesc => 'Start a new project or workflow';

  @override
  String get noDescription => 'No description provided';

  @override
  String get activeBoards => 'Active boards';

  @override
  String get pendingTasks => 'Pending tasks';

  @override
  String get completedTasks => 'Completed';

  @override
  String get quickTipsTitle => 'Quick tip';

  @override
  String get quickTipsBody =>
      'Click any task card to navigate directly to its board.';

  @override
  String get homeNav => 'Home';

  @override
  String get taskBoardsNav => 'Task Boards';

  @override
  String get projectBoardsNav => 'Project Boards';

  @override
  String get teamWhiteboardNav => 'Team Whiteboard';

  @override
  String get voiceRoomNav => 'Voice Room';

  @override
  String get projectsAndTeams => 'PROJECTS & TEAMS';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name!';
  }

  @override
  String get greetingSubtitle =>
      'Have a productive day! Complete your pending tasks!';

  @override
  String get totalTasksMetric => 'Total Tasks';

  @override
  String get inProgressMetric => 'In Progress';

  @override
  String get completedMetric => 'Completed';

  @override
  String get overdueMetric => 'Overdue';

  @override
  String get todayLabel => 'today';

  @override
  String get viewAll => 'View all';

  @override
  String get viewKanban => 'Kanban view';

  @override
  String get filterAction => 'Filter';

  @override
  String get todaySchedule => 'Today\'s Schedule';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get projectMembers => 'Project Members';

  @override
  String get upcomingTasks => 'Upcoming Tasks';

  @override
  String get overdueBadge => 'Overdue';

  @override
  String get tagline => 'Work together effectively';

  @override
  String get todayStatsPrefix => 'Today you have';

  @override
  String get tasksInProgressText => 'tasks in progress';

  @override
  String get boardsText => 'boards';

  @override
  String get getStartedNow => 'Get started now';

  @override
  String get resourceManagement => 'Resource management';

  @override
  String get resourceManagementDesc => 'Efficient, flexible';

  @override
  String get security => 'Security';

  @override
  String get securityDesc => 'Safe, reliable';

  @override
  String get highPerformance => 'High performance';

  @override
  String get highPerformanceDesc => 'Cost optimized';

  @override
  String get easyToUse => 'Easy to use';

  @override
  String get easyToUseDesc => 'Intuitive UI';

  @override
  String get activeStatus => 'Active';

  @override
  String get dashboardTaskTip =>
      'Click a task to view details and update status quickly.';

  @override
  String get cloudWorkspaceDefaultDesc =>
      'Manage your cloud resources, servers, and services easily and effectively.';

  @override
  String get searchMembersPlaceholder => 'Search by name or email...';

  @override
  String get statusActive => 'Active';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusPending => 'Pending';

  @override
  String get columnMember => 'Member';

  @override
  String get columnRole => 'Role';

  @override
  String get columnTasks => 'Assigned tasks';

  @override
  String get columnStatus => 'Activity status';

  @override
  String get columnActions => 'Actions';

  @override
  String get removeMemberConfirm =>
      'Are you sure you want to remove this member from the workspace?';

  @override
  String get noMembersFound => 'No matching members found';

  @override
  String get inviteSentSuccess => 'Invitation sent successfully!';

  @override
  String get memberRoleUpdated => 'Member role updated successfully!';

  @override
  String get memberRemovedSuccess => 'Member removed from workspace';

  @override
  String get send => 'Send';

  @override
  String get projectSettings => 'Project Settings';

  @override
  String get projectInfoTab => 'Project Information';

  @override
  String get membersPermissionsTab => 'Members & Permissions';

  @override
  String get workflowTab => 'Workflow';

  @override
  String get timelineProgressTab => 'Timeline & Progress';

  @override
  String get accessControlTab => 'Access Control';

  @override
  String get archiveDeleteTab => 'Archive & Delete';

  @override
  String get ownerOnlyAccess => 'Owner Access Only';

  @override
  String get ownerOnlyDesc =>
      'Only the project owner has permission to view and modify these settings.';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get projectName => 'Project Name';

  @override
  String get projectDescription => 'Project Description';

  @override
  String get projectOwner => 'Project Owner';

  @override
  String get archiveProject => 'Archive Project';

  @override
  String get archiveProjectDesc =>
      'Archive this completed project. It will become read-only.';

  @override
  String get deleteProject => 'Delete Project';

  @override
  String get deleteProjectDesc =>
      'Permanently delete this project and all associated boards, tasks, and data.';

  @override
  String get deleteConfirmPrompt => 'Type project name to confirm';

  @override
  String get workBoards => 'Work Boards';

  @override
  String get workBoardsDesc => 'Manage and track your projects.';

  @override
  String get renameBoard => 'Rename board';

  @override
  String get editDescription => 'Edit description';

  @override
  String get archiveBoard => 'Archive board';

  @override
  String get archiveBoardConfirm =>
      'Are you sure you want to archive this board?';

  @override
  String get sortByRecent => 'Recently updated';

  @override
  String get sortByName => 'Name (A-Z)';

  @override
  String get filterAllStatus => 'All status';

  @override
  String get filterActive => 'In progress';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get yourTasks => 'Your Tasks';

  @override
  String get yourTasksDesc => 'View and manage all tasks assigned to you.';

  @override
  String get noTasksMatchingFilter => 'No tasks match your filter';

  @override
  String get allBoards => 'All boards';

  @override
  String get filterDoing => 'In progress';

  @override
  String get filterTodo => 'To do';

  @override
  String get filterDone => 'Completed';

  @override
  String get filterOverdue => 'Overdue';

  @override
  String get taskDeadline => 'Deadline';

  @override
  String get dueToday => 'Due today';

  @override
  String roomMembersTitle(int count) {
    return 'ROOM MEMBERS ($count)';
  }

  @override
  String get quickDiscussionNotes => 'Quick discussion notes';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get unknownUser => 'Unknown';

  @override
  String get post => 'Post';

  @override
  String get renamePage => 'Rename page';

  @override
  String get deletePage => 'Delete page';

  @override
  String get deletePageConfirm => 'Are you sure you want to delete this page?';

  @override
  String get cannotDeleteLastPage => 'Cannot delete the last page';

  @override
  String get pageNameExists => 'Page name already exists';

  @override
  String get pageNameEmpty => 'Page name cannot be empty';

  @override
  String get pageTitlePrefix => 'Page';

  @override
  String get autoSyncP2P => 'Auto-sync P2P 0.1s';

  @override
  String get leaveRoom => 'Leave room';

  @override
  String get leaveRoomConfirm =>
      'Are you sure you want to disconnect and leave the voice room?';

  @override
  String get clearCanvasConfirm =>
      'Are you sure you want to clear all drawings and shapes on this page?';

  @override
  String get clearAll => 'Clear all';

  @override
  String get undoTooltip => 'Undo (Ctrl+Z)';

  @override
  String get redoTooltip => 'Redo (Ctrl+Shift+Z)';

  @override
  String get toolSelect => 'Select (V)';

  @override
  String get toolHand => 'Pan (H)';

  @override
  String get toolPen => 'Pen (P)';

  @override
  String get toolEraser => 'Eraser (E)';

  @override
  String get toolRectangle => 'Rectangle (R)';

  @override
  String get toolCircle => 'Circle (O)';

  @override
  String get toolArrow => 'Arrow (A)';

  @override
  String get toolStickyNote => 'Sticky note (N)';

  @override
  String get toolText => 'Text (T)';

  @override
  String get toolKanban => 'Add Kanban card (K)';

  @override
  String get filterAssignee => 'Assignee:';

  @override
  String get filterPriorityAll => 'Priority: All';

  @override
  String get filterPriorityUrgent => 'Urgent';

  @override
  String get filterPriorityHigh => 'High';

  @override
  String get filterPriorityMedium => 'Medium';

  @override
  String get filterPriorityLow => 'Low';

  @override
  String get addColumn => 'Add column';

  @override
  String get addNewCard => 'Add new card';

  @override
  String onlinePeople(int count) {
    return '$count online';
  }

  @override
  String get voiceLive => 'Voice live';

  @override
  String get quickMeetP2P => 'P2P Quick Meet';

  @override
  String get searchPlaceholder => 'Search tasks, meeting notes, drawings...';

  @override
  String get searchFilterPlaceholder => 'Filter project cards...';

  @override
  String get exportAction => 'Export';

  @override
  String get createNewAction => 'New';

  @override
  String get createTaskCTA => 'Create task';

  @override
  String get enterPageName => 'Enter page name...';

  @override
  String get createNewTaskTitle => 'Create new task';

  @override
  String get editTaskTitle => 'Edit task';

  @override
  String get taskDialogSubtitle =>
      'Add a task to track the progress of your work and your team.';

  @override
  String get taskNameLabel => 'Task name';

  @override
  String get taskNamePlaceholder => 'Enter task name...';

  @override
  String get taskNameRequired => 'Please enter task name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionPlaceholder =>
      'Enter a detailed description of the task...';

  @override
  String get listLabel => 'List';

  @override
  String get statusTodo => 'To do';

  @override
  String get statusDoing => 'In progress';

  @override
  String get statusReview => 'Review / Testing';

  @override
  String get statusDone => 'Done';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get assigneeLabel => 'Assignee';

  @override
  String get selectMemberPlaceholder => 'Select member...';

  @override
  String get labelsLabel => 'Labels';

  @override
  String get startDateLabel => 'Start date';

  @override
  String get dueDateLabel => 'Due date';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get setReminder => 'Set reminder';

  @override
  String get repeatIntervalLabel => 'Repeat';

  @override
  String get doesNotRepeat => 'Does not repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get attachmentsLabel => 'Attachments';

  @override
  String get dragAndDropFiles => 'Drag and drop files here or choose a file';

  @override
  String get fileSupportHint => 'Supports JPG, PNG, PDF, DOC... (max 10MB)';

  @override
  String get quickCreationTitle => 'Quick task creation';

  @override
  String get quickCreationBody =>
      'Fill in the details and press \"Create task\" to save and get started.';

  @override
  String get previewLabel => 'Preview';

  @override
  String get previewDescriptionDefault => 'Task description...';

  @override
  String get moreOptions => 'More options';

  @override
  String get notifyMembers => 'Notify members';

  @override
  String get addToSprintPlan => 'Add to sprint plan';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatItalic => 'Italic';

  @override
  String get formatUnderline => 'Underline';

  @override
  String get formatBulletList => 'Bullet list';

  @override
  String get formatNumberedList => 'Numbered list';

  @override
  String get formatLink => 'Link';

  @override
  String get formatImage => 'Image';

  @override
  String get formatCode => 'Code';

  @override
  String get dueDateMustBeAfterStartDate =>
      'Due date must be after or on start date';

  @override
  String get closeTooltip => 'Close (ESC)';

  @override
  String get columnTodo => 'TO DO';

  @override
  String get columnDoing => 'IN PROGRESS';

  @override
  String get columnReview => 'REVIEW / TESTING';

  @override
  String get columnDone => 'DONE';

  @override
  String get priorityBadgeUrgent => 'Urgent';

  @override
  String get priorityBadgeHigh => 'High priority';

  @override
  String get priorityBadgeMedium => 'Medium priority';

  @override
  String get priorityBadgeLow => 'Low priority';

  @override
  String dateFrom(String date) {
    return 'From $date';
  }

  @override
  String dateTo(String date) {
    return 'To $date';
  }

  @override
  String get noDueDate => 'No due date';

  @override
  String get typeDiscussionNote => 'Type a note (Enter)...';

  @override
  String get noDiscussionNotes => 'No notes yet. Type and press Post.';

  @override
  String get themeModeLabel => 'Appearance (Theme)';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsTitle => 'Settings';
}
