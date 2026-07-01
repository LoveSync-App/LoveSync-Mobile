import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/memory/data/datasources/memory_remote_datasource.dart';
import 'package:lovesync_mobile/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:lovesync_mobile/features/memory/domain/entities/memory_response.dart';
import 'package:lovesync_mobile/features/memory/domain/usecases/get_all_memories.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:intl/intl.dart';

class MemoryListPage extends StatefulWidget {
  const MemoryListPage({super.key});

  @override
  State<StatefulWidget> createState() => _MemoryListPageState();
}

class _MemoryListPageState extends State<MemoryListPage> {
  late final GetAllMemories _getAllMemories;

  bool _isLoading = false;
  bool _isFetching = false;
  bool _hasLoadedOnce = false;
  bool _wasVisible = false;

  //  List<MemoryModel> mockMemories = [
  // MemoryModel(
  //   title: 'Beach Day',
  //   desc: 'Fun day...',
  //   date: DateTime(2026, 6, 15),
  //   imageUrl:
  //       'https://scr.vn/wp-content/uploads/2020/07/Ho%C3%A0ng-h%C3%B4n-tr%C3%AAn-bi%E1%BB%83n-h%C3%ACnh-4k-ch%E1%BA%A5t-l%C6%B0%E1%BB%A3ng-cao-scaled.jpg',
  // ),
  // MemoryModel(
  //   title: 'Cafe Date',
  //   desc: 'Chill...',
  //   date: DateTime(2026, 6, 10),
  //   imageUrl:
  //       'https://scr.vn/wp-content/uploads/2020/07/Ho%C3%A0ng-h%C3%B4n-tr%C3%AAn-bi%E1%BB%83n-h%C3%ACnh-4k-ch%E1%BA%A5t-l%C6%B0%E1%BB%A3ng-cao-scaled.jpg',
  // ),
  // MemoryModel(
  //   title: 'Trip to Hanoi',
  //   desc: 'Cold weather...',
  //   date: DateTime(2026, 5, 20),
  //   imageUrl:
  //       'https://scr.vn/wp-content/uploads/2020/07/Ho%C3%A0ng-h%C3%B4n-tr%C3%AAn-bi%E1%BB%83n-h%C3%ACnh-4k-ch%E1%BA%A5t-l%C6%B0%E1%BB%A3ng-cao-scaled.jpg',
  // ),
  // ];

  List<MemoryResponse> memories = [];

  @override
  void initState() {
    super.initState();
    _getAllMemories = GetAllMemories(
      MemoryRepositoryImpl(
        MemoryRemoteDatasource(context.read<DioClient>().dio),
      ),
    );

    _fetchMemories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isVisible = TickerMode.of(context);
    if (isVisible && !_wasVisible && _hasLoadedOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchMemories(showLoading: false);
      });
    }
    _wasVisible = isVisible;
  }

  Future<void> _fetchMemories({bool showLoading = true}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final loadedMemories = await _getAllMemories();
      loadedMemories.sort((a, b) => b.time.compareTo(a.time));
      if (mounted) setState(() => memories = loadedMemories);
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tải kỷ niệm')));
      }
    } finally {
      _isFetching = false;
      _hasLoadedOnce = true;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshMemories() {
    return _fetchMemories(showLoading: false);
  }

  Future<void> _openShareMemory() async {
    final created = await context.push<bool>('/memory/create');
    if (created == true && mounted) {
      await _fetchMemories(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thêm Scaffold để bọc chuẩn cấu trúc trang
      body: (_isLoading)
          ? Skeletonizer(
              enabled: _isLoading,
              child: ListView.builder(
                itemBuilder: (context, index) => _buildMemoryItem(
                  MemoryResponse(
                    id: '1',
                    fileUrl:
                        'https://scr.vn/wp-content/uploads/2020/07/Ho%C3%A0ng-h%C3%B4n-tr%C3%AAn-bi%E1%BB%83n-h%C3%ACnh-4k-ch%E1%BA%A5t-l%C6%B0%E1%BB%A3ng-cao-scaled.jpg',
                    description: 'Mô tả kỷ niệm mẫu',
                    time: DateTime.now(),
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refreshMemories,
                  child: memories.isEmpty
                      ? const CustomScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.photo_library_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Chưa có kỷ niệm nào',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Kéo xuống để tải lại',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                         itemCount: memories.length,
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        itemBuilder: (context, index) {
                          final currentItem = memories[index];

                          // Xác định item đầu tiên của tháng
                          bool isFirstInMonth = false;
                          if (index == 0) {
                            isFirstInMonth = true;
                          } else {
                            final prevItem = memories[index - 1];
                            if (currentItem.time.month != prevItem.time.month ||
                                currentItem.time.year != prevItem.time.year) {
                              isFirstInMonth = true;
                            }
                          }

                          // Áp dụng giải pháp bọc Stack bên ngoài thay vì IntrinsicHeight tốn hiệu năng
                          return Stack(
                            children: [
                              // ĐƯỜNG TRỤC DỌC: Vẽ bằng border left của Container giúp nét vẽ liền mạch mượt mà
                              Positioned(
                                top: index == 0
                                    ? 30
                                    : 0, // Item đầu tiên thụt xuống tránh đứt đuôi đầu
                                bottom: index == memories.length - 1
                                    ? 100
                                    : 0, // Item cuối ngắt sớm đường line
                                left:
                                    28, // Căn giữa chính xác với Node tròn bên dưới (60 width / 2 = 30 trừ nửa nét border)
                                child: Container(
                                  width: 2,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // KHỐI NỘI DUNG CHÍNH (Row ngang)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Giúp các node neo cố định ở đỉnh top Card
                                children: [
                                  // 1. Khối chứa Node hiển thị thời gian (Tháng hoặc Chấm tròn)
                                  SizedBox(
                                    width: 58,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                      ), // Căn node đều với lề trên của Card
                                      child: Center(
                                        child: isFirstInMonth
                                            ? _buildMonthYearNode(
                                                currentItem.time,
                                              )
                                            : _buildDotNode(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // 2. Nội dung Card Memory bên phải
                                  Expanded(
                                    child: _buildMemoryItem(currentItem),
                                  ),
                                ],
                              ),
                            ],
                          );
                          },
                        ),
                ),
                // Nút Thêm Mới Kỷ Niệm
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _openShareMemory,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
    );
  }

  // --- CÁC WIDGET THÀNH PHẦN (Giữ nguyên cấu trúc của bạn nhưng tối ưu lại kích thước) ---

  Widget _buildMonthYearNode(DateTime date) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMonthNode(date),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF0C8D2)),
          ),
          child: Text(
            date.year.toString(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA03B56),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNode(DateTime date) {
    final monthVn = [
      "T1",
      "T2",
      "T3",
      "T4",
      "T5",
      "T6",
      "T7",
      "T8",
      "T9",
      "T10",
      "T11",
      "T12",
    ];
    String monthText = monthVn[date.month - 1]; // Lấy tháng theo index (0-11)
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.pink.shade300,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade300.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        monthText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDotNode() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.pink.shade300, width: 3),
      ),
    );
  }

  Widget _buildMemoryItem(MemoryResponse item) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ), // Thay bằng bottom margin tránh lỗi đè layout trục dọc
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị hình ảnh động lấy từ Object data thực tế
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.fileUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 160,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Color(0xFF363238),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm, dd/MM/yyyy').format(item.time.toLocal()),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MemoryModel {
  final String title;
  final String desc;
  final DateTime date;
  final String imageUrl; // Thêm trường hình ảnh vào model

  MemoryModel({
    required this.title,
    required this.desc,
    required this.date,
    required this.imageUrl,
  });
}
