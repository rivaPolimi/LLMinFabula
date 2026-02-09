import 'package:flutter/material.dart';
import 'dart:async';
import '../shared_widgets.dart';

// Private player class for preview purposes
class _Player {
  final int id;
  final String nickname;
  final bool isDead;

  const _Player({required this.id, required this.nickname, this.isDead = false});
}

class LynchVotingScreenPreview extends StatefulWidget {
  const LynchVotingScreenPreview({super.key});

  @override
  State<LynchVotingScreenPreview> createState() =>
      _LynchVotingScreenPreviewState();
}

class _LynchVotingScreenPreviewState extends State<LynchVotingScreenPreview> {
  int? _selectedPlayerId;
  late Timer _timer;
  int _remainingSeconds = 300; // 5 minutes

  // Hardcoded player list for preview
  final List<_Player> _players = [
    const _Player(id: 1, nickname: 'Matte', isDead: false),
    const _Player(id: 2, nickname: 'Gio', isDead: false),
    const _Player(id: 3, nickname: 'Luca', isDead: false),
    const _Player(id: 4, nickname: 'Giuli', isDead: false),
    const _Player(id: 5, nickname: 'Andre', isDead: false),
    const _Player(id: 6, nickname: 'Lisa', isDead: false),
    const _Player(id: 7, nickname: 'Mark', isDead: false),
    const _Player(id: 8, nickname: 'Dave', isDead: false),
    const _Player(id: 9, nickname: 'Sofia', isDead: true), // Dead
    const _Player(id: 10, nickname: 'Fra', isDead: false),
    const _Player(id: 11, nickname: 'Marta', isDead: false),
    const _Player(id: 12, nickname: 'Pie', isDead: false),
    const _Player(id: 13, nickname: 'Ste', isDead: false),
    const _Player(id: 14, nickname: 'Sara', isDead: true), // Dead
    const _Player(id: 15, nickname: 'Maya', isDead: false),
    const _Player(id: 16, nickname: 'Ali', isDead: false),
    const _Player(id: 17, nickname: 'Diego', isDead: false),
    const _Player(id: 18, nickname: 'Albi', isDead: false),
    const _Player(id: 19, nickname: 'Sonia', isDead: true), // Dead
    const _Player(id: 20, nickname: 'Robi', isDead: false),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return GradientPage(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text(
            '$minutes:$seconds',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _players.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      final isSelected = player.id == _selectedPlayerId;

                      if (player.isDead) {
                        // Dead player UI
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/bara.png',
                              width: 38,
                              height: 38,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              player.nickname,
                              style: const TextStyle(
                                color: Color(0xFF9E9D89),
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      }

                      // Alive player UI
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPlayerId = player.id;
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4B8B9A),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE4D2A6)
                                      : const Color(0xFF5D4D33),
                                  width: isSelected ? 3 : 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF003943),
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              player.nickname,
                              style: const TextStyle(
                                color: Color(0xFFDCC8A0),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  width: 250,
                  child: ElevatedButton(
                    onPressed: _selectedPlayerId == null ? null : () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCC8A0),
                      foregroundColor: const Color(0xFF003943),
                      disabledBackgroundColor:
                          const Color(0xFFDCC8A0).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'confirm your vote',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
