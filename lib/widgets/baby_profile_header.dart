import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_baby_sara/blocs/baby/baby_bloc.dart';
import 'package:open_baby_sara/core/app_colors.dart';
import 'package:open_baby_sara/core/utils/shared_prefs_helper.dart';
import 'package:open_baby_sara/data/models/baby_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class BabyProfileHeader extends StatefulWidget {
  final List<BabyModel> babiesList;

  const BabyProfileHeader({super.key, required this.babiesList});

  @override
  State<BabyProfileHeader> createState() => _BabyProfileHeaderState();
}

class _BabyProfileHeaderState extends State<BabyProfileHeader> {
  BabyModel? _cachedBaby;
  String? _cachedImagePath;
  int _imageVersion = 0;
  final GlobalKey _headerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final babyState = context.read<BabyBloc>().state;
    if (babyState is BabyLoaded) {
      _cachedBaby = babyState.selectedBaby;
      _cachedImagePath = babyState.imagePath;
    }
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    if (birthDate.isAfter(now)) return context.tr('0_day');
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;
    if (days < 0) {
      final lastDay = DateTime(now.year, now.month, 0).day;
      days += lastDay;
      months--;
    }
    if (months < 0) {
      months += 12;
      years--;
    }
    final totalMonths = years * 12 + months;
    String age = '';
    if (totalMonths > 0) {
      age += '$totalMonths ${context.tr('month')}${totalMonths > 1 ? 's' : ''}';
    }
    if (days > 0) {
      if (age.isNotEmpty) age += ' ';
      age += '$days ${context.tr('day')}${days > 1 ? 's' : ''}';
    }
    return age.isEmpty ? context.tr('0_day') : age;
  }

  Future<void> _showBabyDropdown(
      BuildContext context, BabyModel? selectedBaby) async {
    final RenderBox box =
        _headerKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    final screenWidth = MediaQuery.of(context).size.width;

    final result = await showMenu<BabyModel>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        screenWidth - (offset.dx + size.width),
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 8,
      items: widget.babiesList.map((baby) {
        final isSelected = baby.babyID == selectedBaby?.babyID;
        return PopupMenuItem<BabyModel>(
          value: baby,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14.sp,
                backgroundColor: AppColors.historyPink.withValues(alpha: 0.15),
                child: Text(
                  baby.firstName.isNotEmpty
                      ? baby.firstName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppColors.historyPink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  baby.firstName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.historyPink,
                    size: 16.sp,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );

    if (result != null && mounted) {
      this.context.read<BabyBloc>().add(SelectBaby(selectBabyModel: result));
      await SharedPrefsHelper.saveSelectedBabyID(result.babyID);
    }
  }

  Future<void> _pickAndSaveImage(String babyID) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (!mounted) return;
    context.read<BabyBloc>().add(
      UpdateBabyImageLocal(babyID: babyID, imagePath: picked.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BabyBloc, BabyState>(
      listenWhen: (_, curr) =>
          curr is BabyLoaded || curr is BabyImagePathLoaded,
      listener: (context, state) {
        if (state is BabyLoaded) {
          setState(() {
            _cachedBaby = state.selectedBaby;
            _cachedImagePath = state.imagePath;
            _imageVersion++;
          });
        } else if (state is BabyImagePathLoaded) {
          setState(() {
            _cachedImagePath = state.imagePath;
            _imageVersion++;
          });
        }
      },
      buildWhen: (prev, curr) =>
          curr is BabyLoaded || curr is BabyImagePathLoaded,
      builder: (context, state) {
        // Always use cached values so baby info survives image-path-only updates
        final selectedBaby = _cachedBaby;
        final imagePath = _cachedImagePath;

        return Padding(
          padding: EdgeInsets.only(left: 8.w, top: 4.h, bottom: 4.h),
          child: Row(
            key: _headerKey,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarWithPicker(
                key: ValueKey(_imageVersion),
                babyID: selectedBaby?.babyID,
                imagePath: imagePath,
                onTap: () {
                  if (selectedBaby != null) {
                    _pickAndSaveImage(selectedBaby.babyID);
                  }
                },
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _showBabyDropdown(context, selectedBaby),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              selectedBaby?.firstName ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18.sp,
                                color: Colors.grey[850],
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.historyPink,
                            size: 22.sp,
                          ),
                        ],
                      ),
                    ),
                    if (selectedBaby != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        _calculateAge(selectedBaby.dateTime),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarWithPicker extends StatefulWidget {
  final String? babyID;
  final String? imagePath;
  final VoidCallback onTap;

  const _AvatarWithPicker({
    super.key,
    required this.babyID,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_AvatarWithPicker> createState() => _AvatarWithPickerState();
}

class _AvatarWithPickerState extends State<_AvatarWithPicker> {
  File? _localFile;

  @override
  void initState() {
    super.initState();
    _tryLoadLocal(); // no cache to evict on first load
  }

  @override
  void didUpdateWidget(covariant _AvatarWithPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.babyID != widget.babyID) {
      _evictCacheAndReload();
    }
  }

  void _evictCacheAndReload() {
    // Evict current file from Flutter's image cache so the new file is loaded
    // fresh from disk, even if the path is identical (overwrite case).
    if (_localFile != null) {
      PaintingBinding.instance.imageCache.evict(FileImage(_localFile!));
    }
    _tryLoadLocal();
  }

  Future<void> _tryLoadLocal() async {
    final dir = await getApplicationDocumentsDirectory();

    // 1. Direct imagePath (highest priority — set after UpdateBabyImageLocal)
    if (widget.imagePath != null) {
      final f = File(widget.imagePath!);
      if (await f.exists()) {
        // Evict the specific path in case it was cached under this key before
        PaintingBinding.instance.imageCache.evict(FileImage(f));
        if (mounted) setState(() => _localFile = f);
        return;
      }
    }

    if (widget.babyID != null) {
      // 2. saveBabyImageLocally saves here: <dir>/baby_images/<babyID>.jpg
      final babyImagesPath =
          p.join(dir.path, 'baby_images', '${widget.babyID}.jpg');
      final file1 = File(babyImagesPath);
      if (await file1.exists()) {
        PaintingBinding.instance.imageCache.evict(FileImage(file1));
        if (mounted) setState(() => _localFile = file1);
        return;
      }

      // 3. getLocalBabyImage looks here: <dir>/<babyID>.jpg
      final directPath = p.join(dir.path, '${widget.babyID}.jpg');
      final file2 = File(directPath);
      if (await file2.exists()) {
        PaintingBinding.instance.imageCache.evict(FileImage(file2));
        if (mounted) setState(() => _localFile = file2);
        return;
      }
    }

    if (mounted) setState(() => _localFile = null);
  }

  @override
  Widget build(BuildContext context) {
    final double size = 52.sp;
    final ImageProvider imageProvider = _localFile != null
        ? FileImage(_localFile!) as ImageProvider
        : const AssetImage('assets/images/default_baby.png');

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6F91), Color(0xFFDCA6F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.historyPink.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: size,
                height: size,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18.sp,
              height: 18.sp,
              decoration: BoxDecoration(
                color: AppColors.historyPink,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 10.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
