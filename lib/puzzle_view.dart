import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jigsaw_puzzle/puzzle_piece.dart';

class PuzzleView extends StatefulWidget {
  final File? image;
  final int gridSize;
  final double height;
  final double width;
  final Color? backgroundColor;
  final VoidCallback? onCompleted;

  const PuzzleView(
      {required Key key,
      required this.image,
      required this.height,
      required this.width,
      this.onCompleted,
      this.backgroundColor,
      this.gridSize = 4})
      : super(key: key);

  @override
  PuzzleViewState createState() => PuzzleViewState();
}

class PuzzleViewState extends State<PuzzleView> {
  List<Widget> _pieces = [];
  final List<Offset> _piecePositions = [];

  void _checkAllPiecesInCorrectPosition(int row, int col) {
    final removedPiece = Offset(row.toDouble(), col.toDouble());

    if (_piecePositions.remove(removedPiece) && _piecePositions.isEmpty) {
      // Trigger your callback function here when all pieces are correct
      widget.onCompleted!();
    }
  }

  // here we will split the image into small pieces using the rows and columns defined above; each piece will be added to a stack
  void generatePuzzle(File newImage) {
    Image currentImage = Image.file(newImage);
    _pieces.clear();
    Image image = Image(
      fit: BoxFit.cover,
      image: currentImage.image, // Reuse the same image
      height: widget.height, // Set the desired height here
      width: widget.width, // Set the desired width here
    );

    _piecePositions.clear();
    List<PuzzlePiece> newPieces = [];

    for (int x = 0; x < widget.gridSize; x++) {
      // Rows
      for (int y = 0; y < widget.gridSize; y++) {
        // Colunms
        newPieces.add(
          PuzzlePiece(
            key: GlobalKey(),
            image: image,
            imageSize: Size(widget.width, widget.height),
            row: x,
            col: y,
            gridSize: widget.gridSize,
            bringToTop: _bringToTop,
            sendToBack: _sendToBack,
            onAllPiecesCorrect: _checkAllPiecesInCorrectPosition,
          ),
        );

        _piecePositions.add(Offset(x.toDouble(), y.toDouble()));
      }
    }

    setState(() {
      _pieces = newPieces;
    });
  }

  // Reset Puzzle
  resetPuzzle() {
    if (_pieces.isNotEmpty) {
      generatePuzzle(widget.image!);
    }
  }

// when the pan of a piece starts, we need to bring it to the front of the stack
  void _bringToTop(Widget widget) {
    setState(() {
      _pieces.remove(widget);
      _pieces.add(widget);
    });
  }

// when a piece reaches its final position, it will be sent to the back of the stack to not get in the way of other, still movable, pieces
  void _sendToBack(Widget widget) {
    setState(() {
      _pieces.remove(widget);
      _pieces.insert(0, widget);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.grey.shade300,
        ),
        clipBehavior: Clip.hardEdge,
        height: widget.height,
        width: widget.width,
        child: _pieces.isEmpty
            ? const Center(child: Text('No image selected.'))
            : Stack(children: _pieces));
  }
}
