import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jigsaw_puzzle/puzzle_piece.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  final int rows = 4;
  final int cols = 4;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  List<Widget> pieces = [];
  List<Offset> piecePositions = [];

  double maxTop = 0.0;
  double maxLeft = 0.0;

  Future getImage(ImageSource source) async {
    var image = await ImagePicker().pickImage(
        source: source, maxHeight: 1000, maxWidth: 1000, imageQuality: 50);

    if (image != null) {
      setState(() {
        _image = File(image.path);
        pieces.clear();
      });

      splitImage(Image.file(_image!));
    }
  }

  void checkAllPiecesInCorrectPosition(int row, int col) {
    piecePositions.removeWhere((element) =>
        element.dx == row.toDouble() && element.dy == col.toDouble());

    if (piecePositions.isEmpty) {
      // Trigger your callback function here when all pieces are correct
      onAllPiecesCorrect();
    }
  }

  void onAllPiecesCorrect() {
    // Perform your action here
    debugPrint("All pieces are in the correct positions!");
  }

  // we need to find out the image size, to be used in the PuzzlePiece widget
  Future<Size> getImageSize(Image image) async {
    final Completer<Size> completer = Completer<Size>();

    final listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      },
    );

    image.image.resolve(const ImageConfiguration()).addListener(listener);

    final Size imageSize = await completer.future;

    return imageSize;
  }

  // here we will split the image into small pieces using the rows and columns defined above; each piece will be added to a stack
  void splitImage(Image currentImage) async {
    Image image = Image(
      fit: BoxFit.cover,
      image: currentImage.image, // Reuse the same image
      height: 400, // Set the desired height here
      width: 400, // Set the desired width here
    );
    Size imageSize = await getImageSize(image);
    piecePositions.clear();
    for (int x = 0; x < widget.rows; x++) {
      for (int y = 0; y < widget.cols; y++) {
        setState(() {
          pieces.add(PuzzlePiece(
            key: GlobalKey(),
            image: image,
            imageSize: imageSize,
            row: x,
            col: y,
            maxRow: widget.rows,
            maxCol: widget.cols,
            bringToTop: bringToTop,
            sendToBack: sendToBack,
            onAllPiecesCorrect: checkAllPiecesInCorrectPosition,
          ));

          // Calculate the initial position and add it to piecePositions
          piecePositions.add(Offset(
              double.tryParse(x.toString())!, double.tryParse(y.toString())!));
        });
      }
    }
    debugPrint('Pieces Position ===============> ${pieces.length}');
    debugPrint('Pieces Position ===============> $piecePositions');
    debugPrint(
        'Pieces Position Length ===============> ${piecePositions.length}');
  }

  // Reset Puzzle
  resetPuzzle() {
    pieces.clear();
    piecePositions.clear();
    splitImage(Image.file(_image!));
  }

// when the pan of a piece starts, we need to bring it to the front of the stack
  void bringToTop(Widget widget) {
    setState(() {
      pieces.remove(widget);
      pieces.add(widget);
    });
  }

// when a piece reaches its final position, it will be sent to the back of the stack to not get in the way of other, still movable, pieces
  void sendToBack(Widget widget) {
    setState(() {
      pieces.remove(widget);
      pieces.insert(0, widget);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
            child: _image == null
                ? const Text('No image selected.')
                : Column(
                    children: [
                      Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                          ),
                          // child: BoundedStack(
                          //   width: 300, // Width of the stack
                          //   height: 300, // Height of the stack,
                          //   children: pieces,
                          // )
                          clipBehavior: Clip.hardEdge,
                          height: 400,
                          child: Stack(children: pieces)),
                      const SizedBox(
                        height: 60,
                      ),
                      InkWell(
                          onTap: () {
                            resetPuzzle();
                          },
                          child: const Icon(
                            Icons.refresh,
                            size: 50,
                          )),
                    ],
                  )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(Icons.camera),
                        title: const Text('Camera'),
                        onTap: () {
                          getImage(ImageSource.camera);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.image),
                        title: const Text('Gallery'),
                        onTap: () {
                          getImage(ImageSource.gallery);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              });
        },
        tooltip: 'New Image',
        child: const Icon(Icons.add),
      ),
    );
  }
}