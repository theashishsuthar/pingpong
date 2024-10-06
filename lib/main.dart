import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bounce Game',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  double _ballX = 0;
  double _ballY = -0.5;
  double _ballSpeedX = 0.03;
  double _ballSpeedY = 0.03;
  double _playerX = 0;
  int _score = 0;
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _isColliding = false;
  final double _paddleWidth = 0.3;
  final double _ballRadius = 0.025;
  late ConfettiController _confettiController;


  int _displayedScore = 0;
  late AnimationController _scoreAnimationController;
  late Animation<int> _scoreAnimation;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateGame);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    _controller.repeat(reverse: true);


        _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scoreAnimation = IntTween(begin: 0, end: 0).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOut,
    ))..addListener(() {
      setState(() {
        print("Score Animation Value : ${_scoreAnimation.value}");
        _displayedScore = _score;
      });
    });

  }

  void _updateGame() {
    setState(() {
      // Update ball position
      double newBallX = _ballX + _ballSpeedX;
      double newBallY = _ballY + _ballSpeedY;

      // Check for wall collisions
      if (newBallX <= -1 + _ballRadius || newBallX >= 1 - _ballRadius) {
        _ballSpeedX = -_ballSpeedX;
        newBallX = _ballX + _ballSpeedX;
      }

      // Check for ceiling collision
      if (newBallY <= -1 + _ballRadius) {
        _ballSpeedY = -_ballSpeedY;
        newBallY = -1 + _ballRadius + 0.01;
      }

      // Check for paddle collision
      double paddleTop = 1 - 0.05;
      if (newBallY + _ballRadius >= paddleTop && _ballY + _ballRadius < paddleTop &&
          newBallX >= _playerX - _paddleWidth / 2 && newBallX <= _playerX + _paddleWidth / 2) {
        _ballSpeedY = -_ballSpeedY;
        newBallY = paddleTop - _ballRadius - 0.01;
        _score++;
        _ballSpeedX *= 1.05;
        _ballSpeedY *= 1.05;
        _isColliding = true;
                _score++;
        _animateScore();

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() => _isColliding = false);
        });
      }

      // Update ball position
      _ballX = newBallX;
      _ballY = newBallY;

      // Check for game over
      if (_ballY > 1 + _ballRadius) {
        _gameOver();
      }
    });
  }


  void _animateScore() {
    _scoreAnimation = IntTween(begin: _displayedScore, end: _score).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOut,
    ));
    _scoreAnimationController.forward(from: 0);
  }

  void _gameOver() {
    _controller.stop();
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your score:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              AnimatedTextKit(
                animatedTexts: [
                  ScaleAnimatedText(
                    '$_score',
                    textStyle: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                    duration: const Duration(seconds: 2),
                  ),
                ],
                isRepeatingAnimation: false,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Play Again', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    setState(() {
      _ballX = 0;
      _ballY = -0.5;
      _ballSpeedX = 0.03;
      _ballSpeedY = 0.03;
      _score = 0;
      _confettiController.stop();
      _controller.repeat(reverse: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _playerX += 2 * details.delta.dx / MediaQuery.of(context).size.width;
                _playerX = _playerX.clamp(-1.0 + _paddleWidth/2, 1.0 - _paddleWidth/2);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[900]!, Colors.blue[300]!],
                ),
              ),
              child: CustomPaint(
                painter: GamePainter(_ballX, _ballY, _playerX, _pulseAnimation.value, _isColliding, _paddleWidth, _ballRadius),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              children: [
                const Text(
                  'Score: ',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return Text(
                      '${_displayedScore}',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 3.0,
                            color: Colors.orange,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Center(
            child: AnimatedTextKit(
              animatedTexts: [
                ScaleAnimatedText(
                  '$_score',
                  textStyle: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5)),
                  duration: const Duration(milliseconds: 200),
                ),
              ],
              totalRepeatCount: 1,
              pause: const Duration(milliseconds: 500),
              displayFullTextOnTap: true,
              stopPauseOnTap: true,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }
}

class GamePainter extends CustomPainter {
  final double ballX;
  final double ballY;
  final double playerX;
  final double pulseValue;
  final bool isColliding;
  final double paddleWidth;
  final double ballRadius;

  GamePainter(this.ballX, this.ballY, this.playerX, this.pulseValue, this.isColliding, this.paddleWidth, this.ballRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final ballPaint = Paint()..color = isColliding ? Colors.yellow : Colors.red;
    final playerPaint = Paint()..color = isColliding ? Colors.yellow : Colors.white;

    // Draw pulsing ball
    canvas.save();
    canvas.translate((ballX + 1) / 2 * size.width, (ballY + 1) / 2 * size.height);
    canvas.scale(pulseValue);
    canvas.drawCircle(Offset.zero, ballRadius * size.height, ballPaint);
    canvas.restore();

    // Draw player paddle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset((playerX + 1) / 2 * size.width, size.height - 20),
          width: paddleWidth * size.width,
          height: 10,
        ),
        const Radius.circular(5),
      ),
      playerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}