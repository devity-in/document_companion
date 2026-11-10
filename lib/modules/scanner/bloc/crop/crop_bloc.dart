import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../models/area.dart';
import '../../models/contour.dart';
import '../../utils/dot_utils.dart';
import '../../utils/image_utils.dart';
import 'crop_event.dart';
import 'crop_state.dart';

class CropBloc extends Bloc<CropEvent, CropState> {
  final DotUtils _dotUtils;
  final ImageUtils _imageUtils;

  CropBloc({required this._dotUtils, required this._imageUtils})
    : super(CropState.init()) {
    on<CropAreaInitialized>(_areaInitialized);
    on<CropDotMoved>(_dotMoved);
    on<CropPhotoByAreaCropped>(_photoByAreaCropped);
  }

  late Rect _imageRect;
  late Size newScreenSize;

  ///
  Future<void> _areaInitialized(
    CropAreaInitialized event,
    Emitter<CropState> emit,
  ) async {
    newScreenSize = Size(
      (event.screenSize.width - event.positionImage.left) -
          event.positionImage.right,
      (event.screenSize.height - event.positionImage.top) -
          event.positionImage.bottom,
    );

    _imageRect = _imageUtils.imageRect(newScreenSize);

    // Without a detected document, start with (almost) the whole photo.
    final insetX = newScreenSize.width * 0.08;
    final insetY = newScreenSize.height * 0.08;
    Area area = Area(
      topLeft: Point(insetX, insetY),
      topRight: Point(newScreenSize.width - insetX, insetY),
      bottomLeft: Point(insetX, newScreenSize.height - insetY),
      bottomRight: Point(
        newScreenSize.width - insetX,
        newScreenSize.height - insetY,
      ),
    );

    if (event.areaInitial != null) {
      final imageDecoded = await decodeImageFromList(
        event.image.readAsBytesSync(),
      );

      final scalingFactorY = newScreenSize.height / imageDecoded.height;
      final scalingFactorX = newScreenSize.width / imageDecoded.width;

      area = Area(
        topRight: Point(
          event.areaInitial!.topRight.x * scalingFactorX,
          event.areaInitial!.topRight.y * scalingFactorY,
        ),
        topLeft: Point(
          event.areaInitial!.topLeft.x * scalingFactorX,
          event.areaInitial!.topLeft.y * scalingFactorY,
        ),
        bottomLeft: Point(
          event.areaInitial!.bottomLeft.x * scalingFactorX,
          event.areaInitial!.bottomLeft.y * scalingFactorY,
        ),
        bottomRight: Point(
          event.areaInitial!.bottomRight.x * scalingFactorX,
          event.areaInitial!.bottomRight.y * scalingFactorY,
        ),
      );
    }

    emit(state.copyWith(area: area));
  }

  ///
  Future<void> _dotMoved(CropDotMoved event, Emitter<CropState> emit) async {
    Area newArea;

    switch (event.dotPosition) {
      case DotPosition.topRight:
        final result = _dotUtils.moveTopRight(
          original: state.area.topRight,
          deltaX: event.deltaX,
          deltaY: event.deltaY,
          imageRect: _imageRect,
          originalArea: state.area,
        );

        newArea = state.area.copyWith(topRight: result);
        break;

      case DotPosition.topLeft:
        final result = _dotUtils.moveTopLeft(
          original: state.area.topLeft,
          deltaX: event.deltaX,
          deltaY: event.deltaY,
          imageRect: _imageRect,
          originalArea: state.area,
        );

        newArea = state.area.copyWith(topLeft: result);
        break;

      case DotPosition.bottomRight:
        final result = _dotUtils.moveBottomRight(
          original: state.area.bottomRight,
          deltaX: event.deltaX,
          deltaY: event.deltaY,
          imageRect: _imageRect,
          originalArea: state.area,
        );

        newArea = state.area.copyWith(bottomRight: result);
        break;

      case DotPosition.bottomLeft:
        final result = _dotUtils.moveBottomLeft(
          original: state.area.bottomLeft,
          deltaX: event.deltaX,
          deltaY: event.deltaY,
          imageRect: _imageRect,
          originalArea: state.area,
        );

        newArea = state.area.copyWith(bottomLeft: result);
        break;

      case DotPosition.all:
        newArea = _dotUtils.moveArea(
          original: state.area,
          deltaX: event.deltaX,
          deltaY: event.deltaY,
          imageRect: _imageRect,
        );

        break;
    }

    emit(state.copyWith(area: newArea));
  }

  ///
  Future<void> _photoByAreaCropped(
    CropPhotoByAreaCropped event,
    Emitter<CropState> emit,
  ) async {
    try {
      // Check if image file exists
      if (!await event.image.exists()) {
        throw Exception('Image file does not exist');
      }

      final imageBytes = await event.image.readAsBytes();

      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      final imageDecoded = await decodeImageFromList(imageBytes);

      if (newScreenSize.height <= 0 || newScreenSize.width <= 0) {
        throw Exception('Invalid screen size for cropping');
      }

      final scalingFactorY = imageDecoded.height / newScreenSize.height;
      final scalingFactorX = imageDecoded.width / newScreenSize.width;

      final area = Area(
        topRight: Point(
          state.area.topRight.x * scalingFactorX,
          state.area.topRight.y * scalingFactorY,
        ),
        topLeft: Point(
          state.area.topLeft.x * scalingFactorX,
          state.area.topLeft.y * scalingFactorY,
        ),
        bottomLeft: Point(
          state.area.bottomLeft.x * scalingFactorX,
          state.area.bottomLeft.y * scalingFactorY,
        ),
        bottomRight: Point(
          state.area.bottomRight.x * scalingFactorX,
          state.area.bottomRight.y * scalingFactorY,
        ),
      );

      final contour = Contour(
        points: [
          area.topLeft,
          area.topRight,
          area.bottomRight,
          area.bottomLeft,
        ],
      );

      final response = await _imageUtils.adjustingPerspective(
        imageBytes,
        contour,
      );

      if (response == null || response.isEmpty) {
        throw Exception(
          'Failed to crop image. Both native and fallback methods failed.',
        );
      }

      emit(state.copyWith(imageCropped: response, areaParsed: area));
    } catch (e) {
      // If cropping fails, emit error but don't crash
      // The AppBloc listener should handle this
      developer.log('Error cropping image', error: e);
      // Re-emit current state to allow retry
      // Don't set imageCropped to null explicitly to avoid triggering listeners incorrectly
      emit(state);
    }
  }
}
