import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tetris_flutter/src/common/piece.dart';
import 'package:tetris_flutter/src/common/values.dart';
import 'package:tetris_flutter/src/widgets/pixel.dart';

/*
GAME BOARD

THIS IS A 2X2 GRID WHERE NULL REPRESENTS EMPTY.
A NON EMPTY COLOR WILL REPRESENT THE LANDED PIECES.
*/

//create the gameboard
List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(rowLength, (j) => null),
);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  var currentPiece = Piece(type: Tetromino.L);
  var currentScore = 0;
  var gameOver = false;

  @override
  void initState() {
    super.initState();

    // start the game when app starts
    startGame();
  }

  void startGame() {
    currentPiece.initializePiece();

    // frame refresh rate (game speed)
    var frameRate = const Duration(milliseconds: 400);
    gameLoop(frameRate);
  }

  // game loop
  void gameLoop(Duration frameRate) {
    Timer.periodic(frameRate, (timer) {
      setState(() {
        // clear lines
        clearLines();

        // check landing
        checkLanding();

        // check if game is over
        if (gameOver) {
          timer.cancel();
          showGameOverDialogue();
        }

        // move current piece down
        currentPiece.movePiece(Direction.down);
      });
    });
  }

  // game over message
  void showGameOverDialogue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: Text("Your Score is: $currentScore"),
        actions: [
          TextButton(
            onPressed: () {
              resetGame();
              Navigator.pop(context);
            },
            child: const Text("Play Again"),
          )
        ],
      ),
    );
  }

  void resetGame() {
    gameBoard = List.generate(
      colLength,
      (i) => List.generate(rowLength, (j) => null),
    );

    gameOver = false;

    currentScore = 0;

    createNewPiece();

    startGame();
  }

  // check collision in a future position
  //return true -> if there's a collision
  //return false -> if there's no collision
  bool checkCollision(Direction direction) {
    for (var i = 0; i < currentPiece.position.length; i++) {
      var row = (currentPiece.position[i] / rowLength).floor();
      var col = (currentPiece.position[i] % rowLength);

      // adjust the col and row based on the direction
      if (direction == Direction.left) {
        col -= 1;
      } else if (direction == Direction.right) {
        col += 1;
      } else if (direction == Direction.down) {
        row += 1;
      }

      // check if the piece is too low or twoo far to the left or right
      if (row >= colLength || col < 0 || col >= rowLength) {
        return true;
      } else if (col > 0 && row > 0 && gameBoard[row][col] != null) {
        return true;
      }
    }

    // no collision detected
    return false;
  }

  void checkLanding() {
    // if going down is occupied
    if (checkCollision(Direction.down)) {
      //mark the position as occupied on the gameboard
      for (var i = 0; i < currentPiece.position.length; i++) {
        var row = (currentPiece.position[i] / rowLength).floor();
        var col = currentPiece.position[i] % rowLength;

        if (row >= 0 && col >= 0) {
          gameBoard[row][col] = currentPiece.type;
        }
      }

      //once landed, create a new piece
      createNewPiece();
    }
  }

  void createNewPiece() {
    var tetroValues = Tetromino.values;
    var newPieceType = tetroValues[Random().nextInt(tetroValues.length)];
    currentPiece = Piece(type: newPieceType);
    currentPiece.initializePiece();

    // Everytime a new piece is going to be created, we check if game is already over or not
    gameOver = isGameOver();
  }

  void moveLeft() {
    // check if not collision then move left
    var d = Direction.left;
    if (!checkCollision(d)) {
      setState(() => currentPiece.movePiece(d));
    }
  }

  void moveRight() {
    // check if not collision then move right
    var d = Direction.right;
    if (!checkCollision(d)) {
      setState(() => currentPiece.movePiece(d));
    }
  }

  void rotatePiece() {
    setState(() => currentPiece.rotatePiece());
  }

  // clear lines
  void clearLines() {
    // step 1: loop through game board's each row from bottom to top
    for (var row = colLength - 1; row >= 0; row--) {
      // step 2: variable to check if the row is full
      var rowIsFull = true;

      // step 3: Check all columns of this row to see if there is any null item
      for (var col = 0; col < rowLength; col++) {
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }

      // step 4: If the row is full, clear the row and shift rows down
      if (rowIsFull) {
        //step 5: move all rows above the cleared row down by one position
        for (var r = row; r > 0; r--) {
          //copy the above row to current row
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }

        //step:6 Set the top row to empty
        gameBoard[0] = List.generate(row, (index) => null);

        //step:7 Increase the score
        currentScore++;
      }
    }
  }

  bool isGameOver() {
    // check if any column in the first row is filled (i.e. non null)
    for (var col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: rowLength,
              ),
              itemCount: rowLength * colLength,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                var row = (index / rowLength).floor();
                var col = index % rowLength;

                if (currentPiece.position.contains(index)) {
                  return Pixel(color: currentPiece.color);
                } else if (gameBoard[row][col] != null) {
                  var tetrominoType = gameBoard[row][col];
                  return Pixel(color: tetrominoColors[tetrominoType]);
                }
                return Pixel(color: Colors.grey[900]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Score: $currentScore',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: moveLeft,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back_ios_new),
                  iconSize: 40,
                ),
                IconButton(
                  onPressed: rotatePiece,
                  color: Colors.white,
                  icon: const Icon(Icons.rotate_right),
                  iconSize: 40,
                ),
                IconButton(
                  onPressed: moveRight,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_forward_ios),
                  iconSize: 40,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
