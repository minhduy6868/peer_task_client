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
  String get signInSubtitle => 'Đăng nhập bằng địa chỉ email';

  @override
  String get signUpSubtitle => 'Tạo tài khoản để bắt đầu';

  @override
  String get signInToAdventure => 'ĐĂNG NHẬP ĐỂ BẮT ĐẦU\nHÀNH TRÌNH!';

  @override
  String get startYourAdventure => 'BẮT ĐẦU HÀNH TRÌNH\nCỦA BẠN!';

  @override
  String get collaborativeDescription =>
      'Cộng tác liền mạch với nhóm của bạn\ntrên bảng trắng và bảng công việc P2P';

  @override
  String get realTimeCollaboration => 'Cộng tác thời gian thực';

  @override
  String get secureP2P => 'Kết nối P2P bảo mật';

  @override
  String get crossPlatform => 'Hỗ trợ đa nền tảng';

  @override
  String get emailPlaceholder => 'Yourname@gmail.com';

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
  String get byRegistering =>
      'Bằng việc đăng ký, bạn đồng ý với Điều khoản và Điều kiện của chúng tôi';

  @override
  String get emailRequired => 'Vui lòng nhập email';

  @override
  String get emailInvalid => 'Vui lòng nhập email hợp lệ';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

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
  String get inviteByEmail => 'Mời qua Email';

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
  String get todo => 'Cần làm';

  @override
  String get inProgress => 'Đang làm';

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
  String get doing => 'Đang làm';

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
  String get nameRequired => 'Vui lòng nhập tên';

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
  String get taskTitleRequired => 'Vui lòng nhập tên công việc';

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
}
