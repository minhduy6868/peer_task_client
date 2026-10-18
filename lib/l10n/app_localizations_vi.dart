// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'PeerTask';

  @override
  String get login => 'Đăng nhập';

  @override
  String get register => 'Đăng ký';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get signUp => 'Đăng ký';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get confirmPassword => 'Xác nhận mật khẩu';

  @override
  String get name => 'Tên';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get dontHaveAccount => 'Chưa có tài khoản?';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản?';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get signInTitle => 'ĐĂNG NHẬP';

  @override
  String get signUpTitle => 'ĐĂNG KÝ';

  @override
  String get signInSubtitle =>
      'Chào mừng trở lại! Vui lòng đăng nhập để tiếp tục';

  @override
  String get signUpSubtitle => 'Tạo tài khoản để bắt đầu cộng tác';

  @override
  String get signInToAdventure => 'ĐĂNG NHẬP ĐỂ BẮT ĐẦU\nHÀNH TRÌNH!';

  @override
  String get startYourAdventure => 'BẮT ĐẦU HÀNH TRÌNH\nCỦA BẠN!';

  @override
  String get collaborativeDescription =>
      'Cộng tác liền mạch với nhóm của bạn\ntrên bảng trắng và bảng công việc P2P';

  @override
  String get realTimeCollaboration => 'Cộng tác theo thời gian thực';

  @override
  String get secureP2P => 'Kết nối P2P bảo mật';

  @override
  String get crossPlatform => 'Hỗ trợ đa nền tảng';

  @override
  String get emailPlaceholder => 'Địa chỉ email của bạn';

  @override
  String get passwordPlaceholder => 'Mật khẩu';

  @override
  String get namePlaceholder => 'Tên của bạn (không bắt buộc)';

  @override
  String get createAccount => 'Tạo tài khoản';

  @override
  String get orContinueWith => 'Hoặc tiếp tục với';

  @override
  String get google => 'Google';

  @override
  String get facebook => 'Facebook';

  @override
  String get rememberMe => 'Ghi nhớ đăng nhập';

  @override
  String get termsAgreement =>
      'Tôi đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư';

  @override
  String get termsAgreementRequired =>
      'Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư để tiếp tục';

  @override
  String get byRegistering =>
      'Bằng việc đăng ký, bạn đồng ý với Điều khoản và Điều kiện của chúng tôi';

  @override
  String get emailRequired => 'Vui lòng nhập email';

  @override
  String get emailInvalid => 'Vui lòng nhập email hợp lệ';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get passwordMinLength => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get passwordMinLength8 => 'Mật khẩu phải có ít nhất 8 ký tự';

  @override
  String get passwordRequireUppercase => 'Mật khẩu phải có ít nhất 1 chữ hoa';

  @override
  String get passwordRequireLowercase =>
      'Mật khẩu phải có ít nhất 1 chữ thường';

  @override
  String get passwordRequireDigit => 'Mật khẩu phải có ít nhất 1 chữ số';

  @override
  String get passwordConfirmRequired => 'Vui lòng xác nhận mật khẩu';

  @override
  String get passwordNotMatch => 'Mật khẩu không khớp';

  @override
  String get nameRequired => 'Vui lòng nhập tên';

  @override
  String get nameMinLength => 'Tên phải có ít nhất 2 ký tự';

  @override
  String get nameMaxLength => 'Tên không được quá 50 ký tự';

  @override
  String get nameLettersOnly => 'Tên chỉ được chứa chữ cái';

  @override
  String get fieldRequired => 'Trường này không được để trống';

  @override
  String fieldMinLength(String field, int min) {
    return '$field phải có ít nhất $min ký tự';
  }

  @override
  String fieldMaxLength(String field, int max) {
    return '$field không được quá $max ký tự';
  }

  @override
  String get phoneNumberRequired => 'Số điện thoại không được để trống';

  @override
  String get phoneNumberInvalid => 'Số điện thoại không hợp lệ';

  @override
  String get urlRequired => 'URL không được để trống';

  @override
  String get urlInvalid => 'URL không hợp lệ';

  @override
  String get numberRequired => 'Trường này không được để trống';

  @override
  String get numberInvalid => 'Trường này phải là số';

  @override
  String get integerInvalid => 'Trường này phải là số nguyên';

  @override
  String valueMin(String field, num min) {
    return '$field phải lớn hơn hoặc bằng $min';
  }

  @override
  String valueMax(String field, num max) {
    return '$field phải nhỏ hơn hoặc bằng $max';
  }

  @override
  String valueRange(String field, num min, num max) {
    return '$field phải nằm trong khoảng $min - $max';
  }

  @override
  String get workspaceNameRequired => 'Tên workspace không được để trống';

  @override
  String get workspaceNameMinLength => 'Tên workspace phải có ít nhất 3 ký tự';

  @override
  String get workspaceNameMaxLength => 'Tên workspace không được quá 50 ký tự';

  @override
  String get taskTitleRequired => 'Vui lòng nhập tên công việc';

  @override
  String get taskTitleMaxLength => 'Tiêu đề task không được quá 200 ký tự';

  @override
  String get workspaces => 'Không gian làm việc';

  @override
  String get createWorkspace => 'Tạo không gian mới';

  @override
  String get workspaceName => 'Tên không gian';

  @override
  String get boards => 'Bảng';

  @override
  String get createBoard => 'Tạo bảng mới';

  @override
  String get boardName => 'Tên bảng';

  @override
  String get boardDescription => 'Mô tả bảng';

  @override
  String get myBoards => 'Bảng của tôi';

  @override
  String get searchBoards => 'Tìm bảng';

  @override
  String get newBoard => 'Bảng mới';

  @override
  String get createNewBoard => 'Tạo bảng mới';

  @override
  String get enterBoardName => 'Nhập tên sáng tạo...';

  @override
  String get boardDescriptionOptional => 'Bảng này về cái gì?';

  @override
  String boardCreatedSuccess(Object name) {
    return 'Đã tạo bảng \"$name\" thành công!';
  }

  @override
  String get noBoardsYet => 'Chưa có bảng nào';

  @override
  String get createFirstBoard => 'Tạo bảng đầu tiên để bắt đầu cộng tác';

  @override
  String get inviteMembers => 'Mời thành viên';

  @override
  String get inviteLink => 'Link mời';

  @override
  String get inviteByEmail => 'Mời bằng email';

  @override
  String get joinWorkspace => 'Tham gia nhóm';

  @override
  String get scanQR => 'Quét mã QR';

  @override
  String get generateInviteLink => 'Tạo link mời';

  @override
  String get copyLink => 'Sao chép link';

  @override
  String get share => 'Chia sẻ';

  @override
  String get linkCopied => 'Đã sao chép link!';

  @override
  String get expiresIn => 'Hết hạn sau';

  @override
  String get maxUses => 'Số lần dùng tối đa';

  @override
  String get unlimited => 'Không giới hạn';

  @override
  String get never => 'Không bao giờ';

  @override
  String hours(Object count) {
    return '$count giờ';
  }

  @override
  String days(Object count) {
    return '$count ngày';
  }

  @override
  String uses(Object count) {
    return '$count lần';
  }

  @override
  String get scanQRToJoin => 'Quét mã QR để tham gia';

  @override
  String get enterInviteLink => 'Nhập link mời';

  @override
  String get joinedSuccessfully => 'Đã tham gia nhóm thành công!';

  @override
  String get whiteboard => 'Bảng vẽ';

  @override
  String get drawingTools => 'Công cụ vẽ';

  @override
  String get select => 'Chọn';

  @override
  String get pen => 'Bút';

  @override
  String get eraser => 'Tẩy';

  @override
  String get rectangle => 'Hình chữ nhật';

  @override
  String get circle => 'Hình tròn';

  @override
  String get line => 'Đường thẳng';

  @override
  String get arrow => 'Mũi tên';

  @override
  String get text => 'Văn bản';

  @override
  String get stickyNote => 'Ghi chú';

  @override
  String get taskNode => 'Task';

  @override
  String get color => 'Màu sắc';

  @override
  String get strokeWidth => 'Độ dày nét';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get redo => 'Làm lại';

  @override
  String get clear => 'Xóa tất cả';

  @override
  String get properties => 'Thuộc tính';

  @override
  String get noObjectSelected => 'Chưa chọn đối tượng';

  @override
  String get selectObjectToEdit => 'Chọn đối tượng để chỉnh sửa';

  @override
  String get title => 'Tiêu đề';

  @override
  String get description => 'Mô tả';

  @override
  String get status => 'Trạng thái';

  @override
  String get priority => 'Độ ưu tiên';

  @override
  String get position => 'Vị trí';

  @override
  String get delete => 'Xóa';

  @override
  String get taskStatus => 'Trạng thái công việc';

  @override
  String get todo => 'Cần thực hiện';

  @override
  String get inProgress => 'Đang thực hiện';

  @override
  String get done => 'Hoàn thành';

  @override
  String get blocked => 'Bị chặn';

  @override
  String get taskPriority => 'Độ ưu tiên';

  @override
  String get high => 'Cao';

  @override
  String get medium => 'Trung bình';

  @override
  String get low => 'Thấp';

  @override
  String get peers => 'Thành viên';

  @override
  String get online => 'Trực tuyến';

  @override
  String get offline => 'Ngoại tuyến';

  @override
  String get connected => 'Đã kết nối';

  @override
  String get disconnected => 'Mất kết nối';

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get about => 'Giới thiệu';

  @override
  String get hybridBoard => 'Bảng Lai';

  @override
  String get canvas => 'Bảng vẽ';

  @override
  String get tasks => 'Công việc';

  @override
  String get draw => 'Vẽ';

  @override
  String get pan => 'Di chuyển';

  @override
  String get clearCanvas => 'Xóa bảng vẽ';

  @override
  String get hideTasks => 'Ẩn công việc';

  @override
  String get showTasks => 'Hiện công việc';

  @override
  String get addTask => 'Thêm công việc';

  @override
  String get taskTitle => 'Tên công việc...';

  @override
  String get assignee => 'Người thực hiện';

  @override
  String get assigneeName => 'Tên người thực hiện...';

  @override
  String get start => 'Bắt đầu';

  @override
  String get complete => 'Hoàn thành';

  @override
  String get pending => 'Chờ xử lý';

  @override
  String get doing => 'Đang thực hiện';

  @override
  String get empty => 'Trống';

  @override
  String get members => 'Thành viên';

  @override
  String get addMember => 'Thêm thành viên';

  @override
  String get removeMember => 'Xóa thành viên';

  @override
  String get changeRole => 'Đổi vai trò';

  @override
  String get changePermission => 'Đổi quyền';

  @override
  String get owner => 'Chủ sở hữu';

  @override
  String get admin => 'Quản trị viên';

  @override
  String get member => 'Thành viên';

  @override
  String get editor => 'Người chỉnh sửa';

  @override
  String get viewer => 'Người xem';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get view => 'Xem';

  @override
  String get permissions => 'Quyền hạn';

  @override
  String get workspaceRole => 'Vai trò không gian';

  @override
  String get boardPermission => 'Quyền bảng';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get error => 'Lỗi';

  @override
  String get success => 'Thành công';

  @override
  String get loading => 'Đang tải...';

  @override
  String get retry => 'Thử lại';

  @override
  String get serverError => 'Lỗi máy chủ. Vui lòng thử lại sau.';

  @override
  String get networkError => 'Lỗi mạng. Vui lòng kiểm tra kết nối.';

  @override
  String get connectionError => 'Kết nối thất bại. Vui lòng thử lại.';

  @override
  String get timeoutError => 'Hết thời gian chờ. Vui lòng thử lại.';

  @override
  String get unknownError => 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';

  @override
  String get validationError => 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';

  @override
  String get permissionDenied => 'Bạn không có quyền thực hiện thao tác này';

  @override
  String get notFound => 'Không tìm thấy tài nguyên';

  @override
  String get invalidCredentials => 'Email hoặc mật khẩu không đúng';

  @override
  String get passwordTooShort => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';

  @override
  String get taskSavedSuccess => 'Đã lưu công việc thành công';

  @override
  String get taskUpdatedSuccess => 'Đã cập nhật công việc thành công';

  @override
  String get taskDeletedSuccess => 'Đã xóa công việc thành công';

  @override
  String get taskSaveError => 'Không thể lưu công việc';

  @override
  String get taskUpdateError => 'Không thể cập nhật công việc';

  @override
  String get taskDeleteError => 'Không thể xóa công việc';

  @override
  String get boardUpdatedSuccess => 'Đã cập nhật bảng thành công';

  @override
  String get boardDeletedSuccess => 'Đã xóa bảng thành công';

  @override
  String get boardUpdateError => 'Không thể cập nhật bảng';

  @override
  String get boardDeleteError => 'Không thể xóa bảng';

  @override
  String get boardDeleteConfirm => 'Bạn có chắc muốn xóa bảng này?';

  @override
  String get boardNameRequired => 'Vui lòng nhập tên bảng';

  @override
  String get operationSuccess => 'Thao tác hoàn thành thành công';

  @override
  String get operationFailed => 'Thao tác thất bại';

  @override
  String get pleaseWait => 'Vui lòng đợi...';

  @override
  String get processing => 'Đang xử lý...';

  @override
  String get workspace => 'Không gian';

  @override
  String get workspaceInfo => 'Thông tin không gian';

  @override
  String get workspaceSettings => 'Cài đặt không gian';

  @override
  String get changeWorkspace => 'Đổi không gian';

  @override
  String get leaveWorkspace => 'Rời khỏi không gian';

  @override
  String get deleteWorkspace => 'Xóa không gian';

  @override
  String get leaveWorkspaceConfirm =>
      'Bạn có chắc muốn rời khỏi không gian này?';

  @override
  String get deleteWorkspaceConfirm =>
      'Bạn có chắc muốn xóa không gian này? Hành động này không thể hoàn tác.';

  @override
  String get workspaceUpdated => 'Đã cập nhật không gian';

  @override
  String get workspaceDeleted => 'Đã xóa không gian';

  @override
  String get memberRemoved => 'Đã xóa thành viên';

  @override
  String get roleUpdated => 'Đã cập nhật vai trò';

  @override
  String get inviteRevoked => 'Đã hủy lời mời';

  @override
  String get inviteCodeCreated => 'Đã tạo mã mời';

  @override
  String get shareCodeToInvite => 'Chia sẻ mã này để mời thành viên:';

  @override
  String get scanQROrCopy => '• Quét mã QR\n• Hoặc sao chép và dán mã';

  @override
  String get inviteCode => 'Mã mời';

  @override
  String get copyCode => 'Sao chép mã';

  @override
  String get codeCopied => '✅ Đã sao chép mã';

  @override
  String get close => 'Đóng';

  @override
  String get general => 'Chung';

  @override
  String get invites => 'Lời mời';

  @override
  String get createInviteLink => 'Tạo link mời';

  @override
  String get noActiveInvites => 'Không có lời mời nào';

  @override
  String get expired => 'Hết hạn';

  @override
  String get expires => 'Hết hạn';

  @override
  String get invite => 'Mời';

  @override
  String get dangerZone => 'Khu vực nguy hiểm';

  @override
  String get deleteAllData =>
      'Bạn có chắc? Điều này sẽ xóa tất cả bảng, công việc và dữ liệu. Hành động này không thể hoàn tác.';

  @override
  String get makeAdmin => 'Chuyển thành Admin';

  @override
  String get makeMember => 'Chuyển thành Thành viên';

  @override
  String get remove => 'Xóa';

  @override
  String get useInviteLinkToAdd => 'Dùng link mời để thêm thành viên';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get role => 'Vai trò';

  @override
  String errorLoadingMembers(Object error) {
    return 'Lỗi khi tải thành viên: $error';
  }

  @override
  String get welcome => 'Chào mừng!';

  @override
  String get noWorkspaceYet => 'Bạn chưa có không gian làm việc nào';

  @override
  String get createOrJoinWorkspace =>
      'Tạo mới hoặc tham gia một không gian để bắt đầu';

  @override
  String get create => 'Tạo';

  @override
  String get join => 'Tham gia';

  @override
  String get yourWorkspaces => 'Không gian của bạn';

  @override
  String get selectWorkspace => 'Chọn một không gian để tiếp tục';

  @override
  String get enterWorkspaceName => 'Nhập tên không gian';

  @override
  String get taskCard => 'Thẻ công việc';

  @override
  String get untitled => 'Chưa đặt tên';

  @override
  String get overdue => 'Quá hạn';

  @override
  String get yourWork => 'Việc của bạn';

  @override
  String get nothingAssigned =>
      'Chưa có việc nào được giao cho bạn trong workspace này.';

  @override
  String get dueDate => 'Hạn chót';

  @override
  String get assignees => 'Người thực hiện';

  @override
  String moreAssignees(int count) {
    return 'Còn $count người';
  }

  @override
  String get move => 'Di chuyển';

  @override
  String get moveTask => 'Di chuyển công việc';

  @override
  String get urgent => 'Khẩn cấp';

  @override
  String get labels => 'Nhãn';

  @override
  String get deadline => 'Hạn chót';

  @override
  String get estimatedHours => 'Thời gian ước tính';

  @override
  String get actualHours => 'Thời gian thực tế';

  @override
  String get createdBy => 'Tạo bởi';

  @override
  String get updatedAt => 'Cập nhật lúc';

  @override
  String get createTask => 'Tạo nhiệm vụ';

  @override
  String get editTask => 'Sửa công việc';

  @override
  String get deleteTask => 'Xóa công việc';

  @override
  String get deleteTaskConfirm => 'Bạn có chắc muốn xóa công việc này?';

  @override
  String get todoColumn => 'Cần thực hiện';

  @override
  String get doingColumn => 'Đang thực hiện';

  @override
  String get doneColumn => 'Hoàn thành';

  @override
  String taskCount(int count) {
    return '$count công việc';
  }

  @override
  String get noTasks => 'Chưa có nhiệm vụ';

  @override
  String get addFirstTask => 'Thêm công việc đầu tiên để bắt đầu';

  @override
  String get aiBrainstorm => 'AI Brainstorm';

  @override
  String get aiAssistant => 'Trợ lý AI';

  @override
  String get aiThinking => 'Đang suy nghĩ...';

  @override
  String get aiConnected => 'Đã kết nối AI';

  @override
  String get aiDisconnected => 'AI chưa kết nối';

  @override
  String get aiConnectionError => 'Không thể kết nối Ollama';

  @override
  String get aiConnectionErrorHint =>
      'Hãy chắc chắn Ollama đang chạy (ollama serve)';

  @override
  String get aiRetryConnection => 'Thử kết nối lại';

  @override
  String get brainstormMode => 'Brainstorm';

  @override
  String get brainstormHint => 'Mở rộng ý tưởng';

  @override
  String get tasksMode => 'Công việc';

  @override
  String get tasksHint => 'Tạo danh sách việc';

  @override
  String get improveMode => 'Cải thiện';

  @override
  String get improveHint => 'Cải thiện văn bản';

  @override
  String get enterIdeaToBrainstorm => 'Nhập ý tưởng để brainstorm...';

  @override
  String get describeProjectForTasks =>
      'Mô tả dự án để tạo danh sách công việc...';

  @override
  String get enterTextToImprove => 'Nhập văn bản cần cải thiện...';

  @override
  String get addToBoard => 'Thêm vào bảng';

  @override
  String get addedToCanvas => 'Đã thêm vào canvas!';

  @override
  String get copy => 'Sao chép';

  @override
  String get copied => 'Đã sao chép!';

  @override
  String get mainIdea => 'Ý tưởng chính';

  @override
  String get relatedIdeas => 'Ý tưởng liên quan';

  @override
  String get connections => 'Kết nối';

  @override
  String get nextActions => 'Hành động tiếp theo';

  @override
  String get questionsToConsider => 'Câu hỏi để suy ngẫm';

  @override
  String get highPriority => 'Ưu tiên cao';

  @override
  String get mediumPriority => 'Ưu tiên trung bình';

  @override
  String get lowPriority => 'Ưu tiên thấp';

  @override
  String get taskList => 'Danh sách công việc';

  @override
  String get summary => 'Tổng kết';

  @override
  String get totalTasks => 'Tổng số công việc';

  @override
  String get estimatedTime => 'Thời gian ước tính';

  @override
  String get improvedText => 'Văn bản cải thiện';

  @override
  String get changes => 'Thay đổi';

  @override
  String get dragToMove => 'Kéo để di chuyển';

  @override
  String get clickToSelect => 'Nhấn để chọn';

  @override
  String get textAddedToBoard => 'Đã thêm văn bản vào bảng';

  @override
  String get voiceCall => 'Gọi thoại';

  @override
  String get startVoiceCall => 'Bắt đầu gọi thoại';

  @override
  String get endVoiceCall => 'Kết thúc cuộc gọi';

  @override
  String get microphonePermissionDenied => 'Quyền truy cập micro bị từ chối';

  @override
  String get screenshot => 'Chụp màn hình';

  @override
  String get screenshotSaved => 'Đã lưu ảnh chụp màn hình!';

  @override
  String get screenshotFailed => 'Không thể chụp màn hình';

  @override
  String get canvasAndKanban => 'Canvas + Kanban';

  @override
  String get showKanban => 'Hiện Kanban';

  @override
  String get hideKanban => 'Ẩn Kanban';

  @override
  String get backToBoards => 'Quay lại danh sách bảng';

  @override
  String get saveDraft => 'Lưu nháp lên server';

  @override
  String get draftSaved => 'Đã lưu nháp lên server';

  @override
  String get draftRestored => 'Đã khôi phục nét chưa lưu và ghi lên server';

  @override
  String get unsavedDraft => 'Chưa lưu lên server';

  @override
  String get discardDraft => 'Xóa bản dự phòng máy';

  @override
  String get discardDraftConfirm =>
      'Chỉ xóa bản dự phòng trên máy? Bản trên server vẫn giữ nguyên.';

  @override
  String draftSavedAt(String time) {
    return 'Đã lưu · $time';
  }

  @override
  String get addText => 'Thêm văn bản';

  @override
  String get enterText => 'Nhập văn bản…';

  @override
  String get textSize => 'Cỡ chữ';

  @override
  String get width => 'Nét';

  @override
  String get you => 'Bạn';

  @override
  String get addPage => 'Thêm trang';

  @override
  String get pageLabel => 'Trang';

  @override
  String get speaking => 'Đang trò chuyện';

  @override
  String get toolHintPen => 'Vẽ trên canvas';

  @override
  String get toolHintEraser => 'Tẩy nét vẽ';

  @override
  String get toolHintText => 'Chạm canvas để thêm chữ';

  @override
  String get getStarted => 'Bắt đầu';

  @override
  String get landingHeadline =>
      'Làm việc nhóm dễ dàng hơn, cùng nhau hiệu quả hơn';

  @override
  String get landingSubhead =>
      'Quản lý công việc, cùng vẽ ý tưởng và kết nối với các thành viên trong một không gian duy nhất.';

  @override
  String get landingTasksTitle => 'Quản lý công việc';

  @override
  String get landingTasksBody =>
      'Theo dõi tiến độ từ cần thực hiện đến hoàn thành trực tiếp trên bảng.';

  @override
  String get landingCanvasTitle => 'Bảng vẽ cộng tác';

  @override
  String get landingCanvasBody =>
      'Phác thảo ý tưởng ngay cạnh công việc và mở rộng trang vẽ không giới hạn.';

  @override
  String get landingPresenceTitle => 'Thành viên đang trực tuyến';

  @override
  String get landingPresenceBody =>
      'Theo dõi thành viên đang hoạt động, trạng thái micro và ai đang trao đổi.';

  @override
  String get landingPreviewCaption =>
      'Một không gian làm việc, không chỉ là nơi trao đổi tin nhắn';

  @override
  String get landingCta => 'Khởi tạo không gian làm việc chỉ trong một phút.';

  @override
  String get landingFeaturesBadge => 'Tính năng';

  @override
  String get landingFeaturesHeading => 'Mọi công việc trong một không gian';

  @override
  String get landingPreviewKickoff => 'Lập kế hoạch dự án';

  @override
  String get landingPreviewInvite => 'Mời thành viên';

  @override
  String get landingPreviewLayout => 'Thiết kế giao diện';

  @override
  String get landingPreviewVoice => 'Kiểm tra và hoàn thiện';

  @override
  String get continueOffline => 'Làm việc khi không có mạng';

  @override
  String get downloadAndroidApp => 'Tải ứng dụng Android';

  @override
  String get downloadAndroidAppFailed => 'Không thể tải ứng dụng Android';

  @override
  String get sendResetLink => 'Gửi liên kết đặt lại';

  @override
  String get backToLogin => 'Về đăng nhập';

  @override
  String get emailSent => 'Đã gửi email';

  @override
  String get resetEmailHint => 'Nhập email để nhận liên kết đặt lại mật khẩu.';

  @override
  String get resetEmailSent =>
      'Nếu email đã có tài khoản, liên kết đặt lại sẽ được gửi ngay.';

  @override
  String get createNewPassword => 'Tạo mật khẩu mới';

  @override
  String get enterNewPassword => 'Nhập mật khẩu mới';

  @override
  String get newPassword => 'Mật khẩu mới';

  @override
  String get passwordResetDone => 'Đã cập nhật mật khẩu';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get avatarUpdated => 'Đã cập nhật ảnh đại diện';

  @override
  String get boardSettings => 'Cài đặt bảng';

  @override
  String get deleteBoard => 'Xóa bảng';

  @override
  String get deleteBoardConfirm =>
      'Xóa bảng này và các công việc? Không thể hoàn tác.';

  @override
  String get noMembersAvailable => 'Chưa có thành viên';

  @override
  String get addLabel => 'Thêm nhãn';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get workspaceOverview => 'Tổng quan không gian làm việc';

  @override
  String get openBoardHint => 'Nhấn để mở bảng';

  @override
  String get allCaughtUp => 'Không có việc tồn đọng!';

  @override
  String get clearSearch => 'Xóa tìm kiếm';

  @override
  String get all => 'Tất cả';

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterOwner => 'Chủ sở hữu';

  @override
  String get filterEditor => 'Chỉnh sửa';

  @override
  String get filterViewer => 'Chỉ xem';

  @override
  String get boardMembers => 'Thành viên';

  @override
  String get addCollaborator => 'Thêm cộng tác viên';

  @override
  String get manageMembers => 'Quản lý thành viên';

  @override
  String get noBoardsMatchingFilter => 'Không có bảng nào khớp với bộ lọc';

  @override
  String get clearFilter => 'Xóa bộ lọc';

  @override
  String membersCount(int count) {
    return '$count thành viên';
  }

  @override
  String get oneMember => '1 thành viên';

  @override
  String get filter => 'Bộ lọc';

  @override
  String get sort => 'Sắp xếp';

  @override
  String get boardView => 'Bảng việc';

  @override
  String get canvasView => 'Bản vẽ';

  @override
  String get filterAllTasks => 'Tất cả';

  @override
  String get sortByDate => 'Hạn chót';

  @override
  String get sortByPriority => 'Mức ưu tiên';

  @override
  String get sortByTitle => 'Tiêu đề';

  @override
  String get defaultSort => 'Mặc định';

  @override
  String get urgentPriority => 'Khẩn cấp';

  @override
  String get noTasksInColumn => 'Chưa có công việc nào';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get openBoard => 'Vào bảng';

  @override
  String get createBoardCardDesc => 'Bắt đầu dự án hoặc quy trình làm việc mới';

  @override
  String get noDescription => 'Chưa có mô tả chi tiết';

  @override
  String get activeBoards => 'Bảng hoạt động';

  @override
  String get pendingTasks => 'Việc cần xử lý';

  @override
  String get completedTasks => 'Đã hoàn thành';

  @override
  String get quickTipsTitle => 'Mẹo nhanh';

  @override
  String get quickTipsBody =>
      'Nhấn vào bất kỳ thẻ công việc nào để mở ngay bảng tương ứng.';

  @override
  String get homeNav => 'Trang chủ';

  @override
  String get taskBoardsNav => 'Bảng công việc';

  @override
  String get projectBoardsNav => 'Bảng dự án';

  @override
  String get teamWhiteboardNav => 'Bảng vẽ nhóm';

  @override
  String get voiceRoomNav => 'Phòng thoại';

  @override
  String get projectsAndTeams => 'DỰ ÁN & NHÓM';

  @override
  String greetingMorning(String name) {
    return 'Chào buổi sáng, $name!';
  }

  @override
  String get greetingSubtitle =>
      'Chúc bạn một ngày làm việc hiệu quả! Hãy hoàn thành những nhiệm vụ đang chờ nhé!';

  @override
  String get totalTasksMetric => 'Tổng công việc';

  @override
  String get inProgressMetric => 'Đang thực hiện';

  @override
  String get completedMetric => 'Hoàn thành';

  @override
  String get overdueMetric => 'Quá hạn';

  @override
  String get todayLabel => 'hôm nay';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get viewKanban => 'Xem dạng Kanban';

  @override
  String get filterAction => 'Lọc';

  @override
  String get todaySchedule => 'Lịch hôm nay';

  @override
  String get recentActivity => 'Hoạt động gần đây';

  @override
  String get projectMembers => 'Thành viên dự án';

  @override
  String get upcomingTasks => 'Công việc sắp tới';

  @override
  String get overdueBadge => 'Quá hạn';

  @override
  String get tagline => 'Làm việc cùng nhau hiệu quả';

  @override
  String get todayStatsPrefix => 'Hôm nay bạn có';

  @override
  String get tasksInProgressText => 'công việc đang thực hiện';

  @override
  String get boardsText => 'bảng làm việc';

  @override
  String get getStartedNow => 'Bắt đầu ngay';

  @override
  String get resourceManagement => 'Quản lý tài nguyên';

  @override
  String get resourceManagementDesc => 'Hiệu quả, linh hoạt';

  @override
  String get security => 'Bảo mật';

  @override
  String get securityDesc => 'An toàn, ổn định';

  @override
  String get highPerformance => 'Hiệu suất cao';

  @override
  String get highPerformanceDesc => 'Tối ưu chi phí';

  @override
  String get easyToUse => 'Dễ sử dụng';

  @override
  String get easyToUseDesc => 'Giao diện trực quan';

  @override
  String get activeStatus => 'Đang hoạt động';

  @override
  String get dashboardTaskTip =>
      'Nhấn vào một công việc để xem chi tiết và cập nhật trạng thái nhanh chóng.';

  @override
  String get cloudWorkspaceDefaultDesc =>
      'Quản lý tài nguyên, máy chủ và dịch vụ đám mây của bạn một cách dễ dàng và hiệu quả.';

  @override
  String get searchMembersPlaceholder => 'Tìm kiếm theo tên hoặc email...';

  @override
  String get statusActive => 'Đang hoạt động';

  @override
  String get statusOffline => 'Ngoại tuyến';

  @override
  String get statusPending => 'Chờ chấp nhận';

  @override
  String get columnMember => 'Thành viên';

  @override
  String get columnRole => 'Vai trò';

  @override
  String get columnTasks => 'Số task đang phụ trách';

  @override
  String get columnStatus => 'Trạng thái hoạt động';

  @override
  String get columnActions => 'Thao tác';

  @override
  String get removeMemberConfirm =>
      'Bạn có chắc muốn xóa thành viên này khỏi không gian làm việc?';

  @override
  String get noMembersFound => 'Không tìm thấy thành viên nào phù hợp';

  @override
  String get inviteSentSuccess => 'Đã gửi lời mời thành công!';

  @override
  String get memberRoleUpdated => 'Đã cập nhật vai trò thành công!';

  @override
  String get memberRemovedSuccess =>
      'Đã xóa thành viên khỏi không gian làm việc';

  @override
  String get send => 'Gửi';

  @override
  String get projectSettings => 'Cài đặt dự án';

  @override
  String get projectInfoTab => 'Thông tin dự án';

  @override
  String get membersPermissionsTab => 'Thành viên và quyền hạn';

  @override
  String get workflowTab => 'Quy trình công việc';

  @override
  String get timelineProgressTab => 'Thời gian và tiến độ';

  @override
  String get accessControlTab => 'Quyền truy cập';

  @override
  String get archiveDeleteTab => 'Lưu trữ và xóa dự án';

  @override
  String get ownerOnlyAccess => 'Chỉ dành cho chủ sở hữu';

  @override
  String get ownerOnlyDesc =>
      'Chỉ người sở hữu dự án mới có quyền truy cập và chỉnh sửa các cài đặt của dự án này.';

  @override
  String get backToHome => 'Quay lại Trang chủ';

  @override
  String get projectName => 'Tên dự án';

  @override
  String get projectDescription => 'Mô tả dự án';

  @override
  String get projectOwner => 'Chủ sở hữu dự án';

  @override
  String get archiveProject => 'Lưu trữ dự án';

  @override
  String get archiveProjectDesc =>
      'Lưu trữ dự án khi đã hoàn thành. Dự án sẽ chuyển sang chế độ chỉ đọc.';

  @override
  String get deleteProject => 'Xóa dự án';

  @override
  String get deleteProjectDesc =>
      'Xóa vĩnh viễn dự án này và toàn bộ bảng, công việc, dữ liệu liên quan.';

  @override
  String get deleteConfirmPrompt => 'Nhập tên dự án để xác nhận';

  @override
  String get workBoards => 'Bảng làm việc';

  @override
  String get workBoardsDesc => 'Quản lý và theo dõi các dự án của bạn.';

  @override
  String get renameBoard => 'Đổi tên bảng';

  @override
  String get editDescription => 'Chỉnh sửa mô tả';

  @override
  String get archiveBoard => 'Lưu trữ bảng';

  @override
  String get archiveBoardConfirm => 'Bạn có chắc muốn lưu trữ bảng này?';

  @override
  String get sortByRecent => 'Mới cập nhật';

  @override
  String get sortByName => 'Tên (A-Z)';

  @override
  String get filterAllStatus => 'Tất cả trạng thái';

  @override
  String get filterActive => 'Đang thực hiện';

  @override
  String get filterCompleted => 'Hoàn thành';

  @override
  String get yourTasks => 'Công việc của bạn';

  @override
  String get yourTasksDesc =>
      'Xem và quản lý tất cả nhiệm vụ được giao cho bạn.';

  @override
  String get noTasksMatchingFilter => 'Không có công việc nào khớp với bộ lọc';

  @override
  String get allBoards => 'Tất cả các bảng';

  @override
  String get filterDoing => 'Đang làm';

  @override
  String get filterTodo => 'Cần làm';

  @override
  String get filterDone => 'Đã xong';

  @override
  String get filterOverdue => 'Quá hạn';

  @override
  String get taskDeadline => 'Hạn chót';

  @override
  String get dueToday => 'Hôm nay';

  @override
  String roomMembersTitle(int count) {
    return 'THÀNH VIÊN TRONG PHÒNG ($count)';
  }

  @override
  String get quickDiscussionNotes => 'Ghi chú thảo luận nhanh';

  @override
  String get unassigned => 'Chưa giao';

  @override
  String get unknownUser => 'Không xác định';

  @override
  String get post => 'Đăng';

  @override
  String get renamePage => 'Đổi tên trang';

  @override
  String get deletePage => 'Xóa trang';

  @override
  String get deletePageConfirm => 'Bạn có chắc chắn muốn xóa trang này không?';

  @override
  String get cannotDeleteLastPage => 'Không thể xóa trang cuối cùng';

  @override
  String get pageNameExists => 'Tên trang đã tồn tại';

  @override
  String get pageNameEmpty => 'Tên trang không được để trống';

  @override
  String get pageTitlePrefix => 'Trang';

  @override
  String get autoSyncP2P => 'Tự động đồng bộ P2P 0.1s';

  @override
  String get leaveRoom => 'Rời phòng';

  @override
  String get leaveRoomConfirm =>
      'Bạn có chắc chắn muốn ngắt kết nối và rời phòng họp thoại không?';

  @override
  String get clearCanvasConfirm =>
      'Bạn có chắc chắn muốn xóa toàn bộ nét vẽ và hình trên trang này?';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get undoTooltip => 'Hoàn tác (Ctrl+Z)';

  @override
  String get redoTooltip => 'Làm lại (Ctrl+Shift+Z)';

  @override
  String get toolSelect => 'Chọn (V)';

  @override
  String get toolHand => 'Di chuyển tay (H)';

  @override
  String get toolPen => 'Bút vẽ (P)';

  @override
  String get toolEraser => 'Cục tẩy (E)';

  @override
  String get toolRectangle => 'Hình chữ nhật (R)';

  @override
  String get toolCircle => 'Hình tròn (O)';

  @override
  String get toolArrow => 'Mũi tên (A)';

  @override
  String get toolStickyNote => 'Ghi chú sticky (N)';

  @override
  String get toolText => 'Văn bản (T)';

  @override
  String get toolKanban => 'Thêm thẻ Kanban (K)';

  @override
  String get filterAssignee => 'Phụ trách:';

  @override
  String get filterPriorityAll => 'Mức ưu tiên: Tất cả';

  @override
  String get filterPriorityUrgent => 'Khẩn cấp';

  @override
  String get filterPriorityHigh => 'Ưu tiên cao';

  @override
  String get filterPriorityMedium => 'Ưu tiên trung bình';

  @override
  String get filterPriorityLow => 'Ưu tiên thấp';

  @override
  String get addColumn => 'Thêm cột';

  @override
  String get addNewCard => 'Thêm thẻ mới';

  @override
  String onlinePeople(int count) {
    return '$count người online';
  }

  @override
  String get voiceLive => 'Voice live';

  @override
  String get quickMeetP2P => 'Họp nhanh P2P';

  @override
  String get searchPlaceholder => 'Tìm việc, ghi chú cuộc họp, bảng vẽ...';

  @override
  String get searchFilterPlaceholder => 'Lọc thẻ dự án...';

  @override
  String get exportAction => 'Export';

  @override
  String get createNewAction => 'Tạo mới';

  @override
  String get createTaskCTA => 'Tạo nhiệm vụ';

  @override
  String get enterPageName => 'Nhập tên trang...';

  @override
  String get createNewTaskTitle => 'Tạo nhiệm vụ mới';

  @override
  String get editTaskTitle => 'Chỉnh sửa nhiệm vụ';

  @override
  String get taskDialogSubtitle =>
      'Thêm nhiệm vụ để theo dõi tiến độ công việc của bạn và nhóm.';

  @override
  String get taskNameLabel => 'Tên nhiệm vụ';

  @override
  String get taskNamePlaceholder => 'Nhập tên nhiệm vụ...';

  @override
  String get taskNameRequired => 'Vui lòng nhập tên nhiệm vụ';

  @override
  String get descriptionLabel => 'Mô tả';

  @override
  String get descriptionPlaceholder => 'Nhập mô tả chi tiết về nhiệm vụ...';

  @override
  String get listLabel => 'Danh sách';

  @override
  String get statusTodo => 'Cần làm';

  @override
  String get statusDoing => 'Đang làm';

  @override
  String get statusReview => 'Review / Kiểm thử';

  @override
  String get statusDone => 'Đã hoàn thành';

  @override
  String get priorityLabel => 'Độ ưu tiên';

  @override
  String get priorityUrgent => 'Khẩn cấp';

  @override
  String get priorityHigh => 'Cao';

  @override
  String get priorityMedium => 'Trung bình';

  @override
  String get priorityLow => 'Thấp';

  @override
  String get assigneeLabel => 'Người phụ trách';

  @override
  String get selectMemberPlaceholder => 'Chọn thành viên...';

  @override
  String get labelsLabel => 'Nhãn (Label)';

  @override
  String get startDateLabel => 'Ngày bắt đầu';

  @override
  String get dueDateLabel => 'Hạn hoàn thành';

  @override
  String get pickDate => 'Chọn ngày';

  @override
  String get setReminder => 'Đặt lời nhắc';

  @override
  String get repeatIntervalLabel => 'Lặp lại';

  @override
  String get doesNotRepeat => 'Không lặp lại';

  @override
  String get repeatDaily => 'Hàng ngày';

  @override
  String get repeatWeekly => 'Hàng tuần';

  @override
  String get repeatMonthly => 'Hàng tháng';

  @override
  String get attachmentsLabel => 'File đính kèm';

  @override
  String get dragAndDropFiles => 'Kéo thả file tại đây hoặc chọn file';

  @override
  String get fileSupportHint => 'Hỗ trợ JPG, PNG, PDF, DOC... (tối đa 10MB)';

  @override
  String get quickCreationTitle => 'Tạo nhiệm vụ nhanh chóng';

  @override
  String get quickCreationBody =>
      'Điền thông tin và nhấn \"Tạo nhiệm vụ\" để lưu và bắt đầu làm việc.';

  @override
  String get previewLabel => 'Xem trước';

  @override
  String get previewDescriptionDefault => 'Mô tả nhiệm vụ...';

  @override
  String get moreOptions => 'Tùy chọn khác';

  @override
  String get notifyMembers => 'Gửi thông báo cho các thành viên';

  @override
  String get addToSprintPlan => 'Thêm vào kế hoạch sprint';

  @override
  String get formatBold => 'In đậm';

  @override
  String get formatItalic => 'In nghiêng';

  @override
  String get formatUnderline => 'Gạch chân';

  @override
  String get formatBulletList => 'Danh sách';

  @override
  String get formatNumberedList => 'Danh sách số';

  @override
  String get formatLink => 'Liên kết';

  @override
  String get formatImage => 'Hình ảnh';

  @override
  String get formatCode => 'Mã';

  @override
  String get dueDateMustBeAfterStartDate =>
      'Hạn hoàn thành phải sau hoặc cùng ngày bắt đầu';

  @override
  String get closeTooltip => 'Đóng (ESC)';

  @override
  String get columnTodo => 'CẦN LÀM';

  @override
  String get columnDoing => 'ĐANG LÀM';

  @override
  String get columnReview => 'REVIEW / KIỂM THỬ';

  @override
  String get columnDone => 'ĐÃ HOÀN THÀNH';

  @override
  String get priorityBadgeUrgent => 'Khẩn cấp';

  @override
  String get priorityBadgeHigh => 'Ưu tiên cao';

  @override
  String get priorityBadgeMedium => 'Ưu tiên trung bình';

  @override
  String get priorityBadgeLow => 'Ưu tiên thấp';

  @override
  String dateFrom(String date) {
    return 'Từ $date';
  }

  @override
  String dateTo(String date) {
    return 'Đến $date';
  }

  @override
  String get noDueDate => 'Chưa đặt hạn';

  @override
  String get typeDiscussionNote => 'Nhập ghi chú (Enter)...';

  @override
  String get noDiscussionNotes => 'Chưa có ghi chú nào. Nhập và nhấn Đăng.';

  @override
  String get themeModeLabel => 'Giao diện';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get canvasRestored => 'Đã khôi phục bản vẽ';

  @override
  String get taskCreatedToast => 'Đã tạo nhiệm vụ';

  @override
  String get taskUpdatedToast => 'Đã cập nhật nhiệm vụ';

  @override
  String get taskDeletedToast => 'Đã xóa nhiệm vụ';

  @override
  String get addTextTitle => 'Thêm văn bản';

  @override
  String get enterTextHint => 'Nhập nội dung văn bản...';

  @override
  String get addAction => 'Thêm';

  @override
  String get addStickyNoteTitle => 'Thêm ghi chú sticky';

  @override
  String get enterNoteHint => 'Nhập ghi chú thảo luận...';

  @override
  String get pasteNote => 'Dán ghi chú';

  @override
  String get micPermissionDenied =>
      'Không thể truy cập microphone. Vui lòng cấp quyền.';

  @override
  String micError(String error) {
    return 'Lỗi micro: $error';
  }

  @override
  String get expandSidebar => 'Mở rộng thanh bên';

  @override
  String get accountAndSettings => 'Tài khoản & Cài đặt';

  @override
  String get previousPage => 'Trang trước';

  @override
  String get nextPage => 'Trang sau';

  @override
  String get pageListRename => 'Danh sách trang / Đổi tên';

  @override
  String get addKanbanCard => 'Thêm thẻ Kanban';

  @override
  String get closePanel => 'Đóng panel';

  @override
  String get collapsePanel => 'Thu gọn panel';

  @override
  String get hostBadge => 'CHỦ PHÒNG';

  @override
  String get peerBadge => 'THÀNH VIÊN';

  @override
  String get micOn => 'Đang bật mic';

  @override
  String get micOff => 'Đã tắt mic';

  @override
  String get muteMic => 'Tắt mic';

  @override
  String get unmuteMic => 'Bật mic';

  @override
  String get muteAudio => 'Tắt âm thanh';

  @override
  String get unmuteAudio => 'Bật âm thanh';

  @override
  String get listening => 'Đang nghe';

  @override
  String get newTaskTitle => 'Nhiệm vụ mới';

  @override
  String get deadlineBeforeStart =>
      'Hạn hoàn thành phải sau hoặc cùng ngày bắt đầu';

  @override
  String get sprintHint => 'Đính kèm task trực tiếp vào chu kỳ sprint.';

  @override
  String get checklistLabel => 'Checklist';

  @override
  String get checklistHint =>
      'Thêm các bước để hoàn thành công việc. Đánh dấu khi xong.';

  @override
  String get addChecklistStep => 'Thêm bước';

  @override
  String get removeChecklistStep => 'Xóa bước';

  @override
  String get taskNotesPlaceholder =>
      'Ghi chú cho công việc (không bắt buộc)...';

  @override
  String get uploadImages => 'Nhấn để tải ảnh lên';

  @override
  String get imageSupportHint => 'JPG, PNG, WEBP, GIF - tối đa 10MB mỗi ảnh';

  @override
  String imageTooLarge(String name) {
    return '$name lớn hơn 10MB';
  }

  @override
  String get uploadingImages => 'Đang tải ảnh lên...';

  @override
  String get removeAttachment => 'Xóa ảnh';
}
