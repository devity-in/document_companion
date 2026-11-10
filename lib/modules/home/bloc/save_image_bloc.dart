import 'package:document_companion/config/custom_key.dart';
import 'package:flutter/material.dart';

import '../view/save_image_bottom_sheet.dart';

class SaveImageBloc {
  void openSaveImageSheet() {
    final context = CustomKey.navigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => SaveImageBottomSheet(),
    );
  }
}

final saveImageBloc = SaveImageBloc();
