import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:whiteboard_sdk_flutter/whiteboard_sdk_flutter.dart';

import 'types/fast_redo_undo_count.dart';
import 'types/types.dart';

class FastRoomController extends ValueNotifier<FastRoomValue> {
  FastRoomController(this.fastRoomOptions)
      : super(FastRoomValue.uninitialized(fastRoomOptions.writable)) {}

  WhiteSdk? whiteSdk;
  WhiteRoom? whiteRoom;
  FastRoomOptions fastRoomOptions;

  final StreamController<FastRoomEvent> _fastEventStreamController =
      StreamController<FastRoomEvent>.broadcast();

  Stream<OverlayChangedEvent> onOverlayChanged() {
    return _fastEventStreamController.stream.whereType<OverlayChangedEvent>();
  }

  void changeOverlay(int key) {
    _fastEventStreamController.add(OverlayChangedEvent(key));
  }

  void cleanScene() {
    whiteRoom?.cleanScene(false);
  }

  void addPage() {
    whiteRoom?.addPage();
  }

  void prevPage() {
    whiteRoom?.prevPage();
  }

  void nextPage() {
    whiteRoom?.nextPage();
  }

  void setAppliance(FastAppliance fastAppliance) {
    if (fastAppliance == FastAppliance.clear) {
      cleanScene();
      return;
    }
    var state = MemberState()
      ..currentApplianceName = fastAppliance.appliance
      ..shapeType = fastAppliance.shapeType;
    whiteRoom?.setMemberState(state);
  }

  void setStrokeWidth(num strokeWidth) {
    var state = MemberState()..strokeWidth = strokeWidth;
    whiteRoom?.setMemberState(state);
  }

  void setStrokeColor(Color strokeColor) {
    var state = MemberState()
      ..strokeColor = [
        strokeColor.red,
        strokeColor.green,
        strokeColor.blue,
      ];
    whiteRoom?.setMemberState(state);
  }

  // TODO 同时开启序列化
  Future<bool?> setWritable(bool writable) async {
    var result = await whiteRoom?.setWritable(writable);
    if (result ?? false) {
      whiteRoom?.disableSerialization(false);
      return true;
    } else {
      return false;
    }
  }

  void undo() {
    whiteRoom?.undo();
  }

  void redo() {
    whiteRoom?.redo();
  }

  void removePages() {
    whiteRoom?.removeScenes('/');
  }

  Future<void> onSdkCreated(WhiteSdk whiteSdk) async {
    this.whiteSdk = whiteSdk;
    await joinRoom();
  }

  Future<void> joinRoom() async {
    whiteRoom = await whiteSdk?.joinRoom(
      options: fastRoomOptions.roomOptions,
      onRoomPhaseChanged: _onRoomPhaseChanged,
      onRoomStateChanged: _onRoomStateChanged,
      onCanRedoStepsUpdate: _onCanRedoUpdated,
      onCanUndoStepsUpdate: _onCanUndoUpdated,
      onRoomDisconnected: _onRoomDisconnected,
      onRoomError: _onRoomError,
    );
    value = value.copyWith(isReady: true, roomState: whiteRoom?.state);
    if (fastRoomOptions.roomOptions.isWritable) {
      whiteRoom?.disableSerialization(false);
    }
  }

  Future<void> reconnect() async {
    // TODO update room value
    value = FastRoomValue.uninitialized(fastRoomOptions.roomOptions.isWritable);
    if (whiteRoom != null) {
      return joinRoom();
    }
    whiteRoom?.disconnect().then((value) {
      return joinRoom();
    }).catchError((e) {
      // ignore
    });
  }

  void _onRoomStateChanged(RoomState newState) {
    value = value.copyWith(roomState: newState);
  }

  /// when reconnected, clear all redoUndoCount
  void _onRoomPhaseChanged(String phase) {
    var redoUndoCount = phase == RoomPhase.connected
        ? const FastRedoUndoCount.initialized()
        : value.redoUndoCount;
    value = value.copyWith(roomPhase: phase, redoUndoCount: redoUndoCount);
  }

  void _onRoomError(String error) {}

  void _onRoomDisconnected(String error) {}

  void _onCanRedoUpdated(int redoCount) {
    var redoUndoCount = value.redoUndoCount.copyWith(redoCount: redoCount);
    value = value.copyWith(redoUndoCount: redoUndoCount);
  }

  void _onCanUndoUpdated(int undoCount) {
    var redoUndoCount = value.redoUndoCount.copyWith(undoCount: undoCount);
    value = value.copyWith(redoUndoCount: redoUndoCount);
  }

  @override
  void dispose() {
    super.dispose();
    _fastEventStreamController.close();
  }
}

/// reserved for replay
class FastReplayController {}
