import 'package:fastboard_flutter/src/types/fast_redo_undo_count.dart';
import 'package:flutter/material.dart';

import '../controller.dart';
import 'fast_base_ui.dart';
import 'fast_icons.dart';

class FastRedoUndoWidget extends FastRoomControllerWidget {
  const FastRedoUndoWidget(FastRoomController controller, {Key? key})
      : super(controller, key: key);

  @override
  State<StatefulWidget> createState() {
    return FastRedoUndoState();
  }
}

class FastRedoUndoState extends FastRoomControllerState<FastRedoUndoWidget> {
  late FastRedoUndoCount redoUndoCount;

  @override
  void initState() {
    super.initState();
    redoUndoCount = widget.controller.value.redoUndoCount;
  }

  @override
  Widget build(BuildContext context) {
    return FastContainer(
        child: Row(
      children: [
        InkWell(
          child: FastIcons.undo,
          onTap: redoUndoCount.undo != 0 ? _onUndoTap : null,
        ),
        const SizedBox(width: 4),
        InkWell(
          child: FastIcons.redo,
          onTap: redoUndoCount.redo != 0 ? _onRedoTap : null,
        ),
      ],
    ));
  }

  void _onUndoTap() {
    widget.controller.undo();
  }

  void _onRedoTap() {
    widget.controller.redo();
  }

  @override
  void calculateState() {
    redoUndoCount = widget.controller.value.redoUndoCount;
  }
}