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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: true,
                iconTheme: const IconThemeData(color: Colors.white),
                centerTitle: true,
                title: Text(
                  '$minutes:$seconds',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  itemCount: _players.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12, // Reduced from 16
                    childAspectRatio: 0.9, // Adjusted from 0.8
                  ),
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    final isSelected = player.id == _selectedPlayerId;

                    if (player.isDead) {
                      // Dead player UI
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/bara.png', // Tombstone image
                            width: 50, // Reduced from 60
                            height: 50, // Reduced from 60
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 4), // Reduced from 8
                          Text(
                            player.nickname,
                            style: const TextStyle(
                              color: Color(0xFF9E9D89), // Muted color
                              fontSize: 14,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50, // Reduced from 60
                            height: 50, // Reduced from 60
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4B8B9A), // Teal color
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE4D2A6) // Highlight
                                    : const Color(0xFF5D4D33), // Default
                                width: isSelected ? 3 : 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF003943), // Darker Teal
                              size: 35, // Reduced from 40
                            ),
                          ),
                          const SizedBox(height: 4), // Reduced from 8
                          Text(
                            player.nickname,
                            style: const TextStyle(
                              color: Color(0xFFDCC8A0), // Beige text
                              fontSize: 14,
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
              SizedBox(
                height: 48,
                width: 250,
                child: ElevatedButton(
                  onPressed: _selectedPlayerId == null ? null : () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDCC8A0), // Beige
                    foregroundColor: const Color(0xFF003943), // Dark Teal
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
    );
  }
}
