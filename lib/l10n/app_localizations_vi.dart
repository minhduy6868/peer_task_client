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
  String get serverError => 'Lỗi máy chủ';

  @override
  String get networkError => 'Lỗi mạng';

  @override
  String get invalidCredentials => 'Email hoặc mật khẩu không đúng';

  @override
  String get emailRequired => 'Vui lòng nhập email';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get passwordTooShort => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get passwordsDoNotMatch => 'Mật khẩu không khớp';

  @override
  String get nameRequired => 'Vui lòng nhập tên';
}
