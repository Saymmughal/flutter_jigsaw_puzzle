import 'dart:math';

import 'package:flutter/material.dart';

class PuzzlePiece extends StatefulWidget {
  final Image image;
  final Size imageSize;
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;
  final Function bringToTop;
  final Function sendToBack;
  final Function onAllPiecesCorrect;

  const PuzzlePiece(
      {Key? key,
      required this.image,
      required this.imageSize,
      required this.row,
      required this.col,
      required this.maxRow,
      required this.maxCol,
      required this.bringToTop,
      required this.sendToBack,
      required this.onAllPiecesCorrect})
      : super(key: key);

  @override
  PuzzlePieceState createState() {
    return PuzzlePieceState();
  }
}

class PuzzlePieceState extends State<PuzzlePiece> {
  double? top;
  double? left;
  bool isMovable = true;

  @override
  Widget build(BuildContext context) {
    final imageWidth = widget.imageSize.width;
    final imageHeight = widget.imageSize.height *
        widget.imageSize.width /
        widget.imageSize.width;
    final pieceWidth = imageWidth / widget.maxCol;
    final pieceHeight = imageHeight / widget.maxRow;

    double maxTopValue = pieceHeight * (widget.maxRow - 1);
    double minTopValue =
        (((widget.maxCol * widget.maxRow) + widget.row) - maxTopValue);

    double maxLeftValue = pieceWidth * (widget.maxCol - 1);
    double minLeftValue =
        (((widget.maxCol * widget.maxRow) + widget.col) - maxLeftValue);

    if (top == null) {
      top = Random().nextInt((imageHeight - pieceHeight).ceil()).toDouble();
      top = top! - (widget.row * pieceHeight);
    }
    if (left == null) {
      left = Random().nextInt((imageWidth - pieceWidth).ceil()).toDouble();
      left = left! - (widget.col * pieceWidth);
    }
    final positions = topPosition(
        widget.maxCol,
        widget.maxRow,
        widget.col,
        widget.row,
        top!,
        left!,
        maxTopValue,
        minTopValue,
        maxLeftValue,
        minLeftValue);

    top = positions.first;
    left = positions.last;
    return Positioned(
      top: top,
      left: left,
      width: imageWidth,
      child: GestureDetector(
        onTap: () {
          if (isMovable) {
            widget.bringToTop(widget);
          }
        },
        onPanStart: (_) {
          if (isMovable) {
            widget.bringToTop(widget);
          }
        },
        onPanUpdate: (dragUpdateDetails) {
          if (isMovable) {
            setState(() {
              top = top! + dragUpdateDetails.delta.dy;
              left = left! + dragUpdateDetails.delta.dx;

              final positionValue = topPosition(
                  widget.maxCol,
                  widget.maxRow,
                  widget.col,
                  widget.row,
                  top!,
                  left!,
                  maxTopValue,
                  minTopValue,
                  maxLeftValue,
                  minLeftValue);

              top = positionValue.first;
              left = positionValue.last;

              if (-10 < top! && top! < 10 && -10 < left! && left! < 10) {
                top = 0;
                left = 0;
                isMovable = false;
                widget.onAllPiecesCorrect(widget.row, widget.col);
                widget.sendToBack(widget);
              }
            });
          }
        },
        child: ClipPath(
          clipper: PuzzlePieceClipper(
              widget.row, widget.col, widget.maxRow, widget.maxCol),
          child: CustomPaint(
              foregroundPainter: PuzzlePiecePainter(
                  widget.row, widget.col, widget.maxRow, widget.maxCol),
              child: widget.image),
        ),
      ),
    );
  }
}

// this class is used to clip the image to the puzzle piece path
class PuzzlePieceClipper extends CustomClipper<Path> {
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  PuzzlePieceClipper(this.row, this.col, this.maxRow, this.maxCol);

  @override
  Path getClip(Size size) {
    return getPiecePath(size, row, col, maxRow, maxCol);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// this class is used to draw a border around the clipped image
class PuzzlePiecePainter extends CustomPainter {
  final int row;
  final int col;
  final int maxRow;
  final int maxCol;

  PuzzlePiecePainter(this.row, this.col, this.maxRow, this.maxCol);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(getPiecePath(size, row, col, maxRow, maxCol), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// this is the path used to clip the image and, then, to draw a border around it; here we actually draw the puzzle piece
Path getPiecePath(Size size, int row, int col, int maxRow, int maxCol) {
  final width = size.width / maxCol;
  final height = size.height / maxRow;
  final offsetX = col * width;
  final offsetY = row * height;
  final bumpSize = height / 4;

  var path = Path();
  path.moveTo(offsetX, offsetY);

  if (row == 0) {
    // top side piece
    path.lineTo(offsetX + width, offsetY);
  } else {
    // top bump
    path.lineTo(offsetX + width / 3, offsetY);
    path.cubicTo(
        offsetX + width / 6,
        offsetY - bumpSize,
        offsetX + width / 6 * 5,
        offsetY - bumpSize,
        offsetX + width / 3 * 2,
        offsetY);
    path.lineTo(offsetX + width, offsetY);
  }

  if (col == maxCol - 1) {
    // right side piece
    path.lineTo(offsetX + width, offsetY + height);
  } else {
    // right bump
    path.lineTo(offsetX + width, offsetY + height / 3);
    path.cubicTo(
        offsetX + width - bumpSize,
        offsetY + height / 6,
        offsetX + width - bumpSize,
        offsetY + height / 6 * 5,
        offsetX + width,
        offsetY + height / 3 * 2);
    path.lineTo(offsetX + width, offsetY + height);
  }

  if (row == maxRow - 1) {
    // bottom side piece
    path.lineTo(offsetX, offsetY + height);
  } else {
    // bottom bump
    path.lineTo(offsetX + width / 3 * 2, offsetY + height);
    path.cubicTo(
        offsetX + width / 6 * 5,
        offsetY + height - bumpSize,
        offsetX + width / 6,
        offsetY + height - bumpSize,
        offsetX + width / 3,
        offsetY + height);
    path.lineTo(offsetX, offsetY + height);
  }

  if (col == 0) {
    // left side piece
    path.close();
  } else {
    // left bump
    path.lineTo(offsetX, offsetY + height / 3 * 2);
    path.cubicTo(
        offsetX - bumpSize,
        offsetY + height / 6 * 5,
        offsetX - bumpSize,
        offsetY + height / 6,
        offsetX,
        offsetY + height / 3);
    path.close();
  }

  return path;
}

Set<double> topPosition(
    int maxCol,
    int maxRow,
    int currentCol,
    int currentRow,
    double top,
    double left,
    double maxTopValue,
    double minTopValue,
    double maxLeftValue,
    double minLeftValue) {

  // Set the Range to Top to Bottom
  double totalRows = (maxRow - 1);

  double maxSingleTop = (maxTopValue / totalRows);
  double minSingleTop = (minTopValue / totalRows);

  double expactedMinTop = currentRow == 0.0 ? 0.0 : (currentRow * minSingleTop);
  double expactedMaxTop = (totalRows - currentRow) * maxSingleTop;

  if (top > expactedMaxTop) {
    top = expactedMaxTop;
  } else if (top < expactedMinTop) {
    top = expactedMinTop;
  }

  //Set the range to Left to Right
  double totalCols = (maxCol - 1);

  double maxSingleLeft = (maxLeftValue / totalCols);
  double minSingleLeft = (minLeftValue / totalCols);

  double expactedMinLeft = currentCol == 0 ? 0 : (currentCol * minSingleLeft);
  double expactedMaxLeft = (totalCols - currentCol) * maxSingleLeft;

  if (left > expactedMaxLeft) {
    left = expactedMaxLeft;
  } else if (left < expactedMinLeft) {
    left = expactedMinLeft;
  }

  return {top, left};
}
