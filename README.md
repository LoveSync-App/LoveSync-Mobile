# LoveSync Mobile

LoveSync Mobile là ứng dụng Flutter dành cho các cặp đôi, hỗ trợ kết nối tài khoản, lưu giữ kỷ niệm, quản lý lịch hẹn, nhắn tin realtime, gọi trực tuyến và chia sẻ vị trí.

## Tính năng chính

- Xác thực bằng email/mật khẩu và Google.
- Ghép đôi bằng mã hoặc quét QR.
- Quản lý ngày yêu, kỷ niệm và sự kiện lịch.
- Nhắn tin realtime, gửi tệp đính kèm và xem video.
- Gọi audio/video, thông báo đẩy qua Firebase Cloud Messaging.
- Chia sẻ vị trí trực tiếp và gửi ảnh chụp vị trí.
- Mã hóa đầu cuối cho tin nhắn.

## Công nghệ

- Flutter / Dart
- Provider, GoRouter, Dio
- Firebase Core, Auth, Messaging, Analytics, Storage
- Socket.IO, LiveKit
- Flutter Map, Geolocator

## Cài đặt

Yêu cầu:

- Flutter SDK phù hợp với Dart `^3.10.1`
- Android Studio hoặc Xcode cho môi trường mobile
- Cấu hình Firebase đã được thiết lập trong `firebase.json`, `lib/firebase_options.dart` và thư mục nền tảng

Chạy dự án:

```bash
flutter pub get
flutter run
```

Chạy kiểm thử và phân tích mã nguồn:

```bash
flutter test
flutter analyze
```

## Cấu trúc thư mục

```text
lib/
  core/       Cấu hình API, network và lưu trữ
  features/   Các module nghiệp vụ theo từng tính năng
  providers/  Trạng thái dùng chung
  shared/     Widget và tiện ích tái sử dụng
```

## Ghi chú

API mặc định đang trỏ đến môi trường deploy tại `https://love-sync.publicvm.com/api`. Nếu cần đổi môi trường, cập nhật trong `lib/core/constants/api_constants.dart`.
