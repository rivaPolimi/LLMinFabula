import 'package:flutter/material.dart';
import 'dart:async';
import 'package:llm_in_fabula/models/model.dart';
import '../shared_widgets.dart';

class WolfVotingScreenPreview extends StatefulWidget {
  const WolfVotingScreenPreview({super.key});

  @override
  State<WolfVotingScreenPreview> createState() => _WolfVotingScreenPreviewState();
}

class _WolfVotingScreenPreviewState extends State<WolfVotingScreenPreview> {
  int? _selectedPlayerId;
  late Timer _timer;
  int _remainingSeconds = 30;

  final List<Player> _players = [
    Player(id: 1, nickname: 'Matte', isDead: false),
    Player(id: 2, nickname: 'Gio', isDead: false),
    Player(id: 3, nickname: 'Luca', isDead: false),
    Player(id: 4, nickname: 'Giuli', isDead: false),
    Player(id: 5, nickname: 'Andre', isDead: false),
    Player(id: 6, nickname: 'Lisa', isDead: false),
    Player(id: 7, nickname: 'Mark', isDead: false),
    Player(id: 8, nickname: 'Dave', isDead: false),
    Player(id: 9, nickname: 'Sofia', isDead: true),
    Player(id: 10, nickname: 'Fra', isDead: false),
    Player(id: 11, nickname: 'Marta', isDead: false),
    Player(id: 12, nickname: 'Pie', isDead: false),
    Player(id: 13, nickname: 'Ste', isDead: false),
    Player(id: 14, nickname: 'Sara', isDead: false),
    Player(id: 15, nickname: 'Maya', isDead: false),
    Player(id: 16, nickname: 'Ali', isDead: false),
    Player(id: 17, nickname: 'Diego', isDead: false),
    Player(id: 18, nickname: 'Albi', isDead: false),
    Player(id: 19, nickname: 'Sonia', isDead: true),
    Player(id: 20, nickname: 'Robi', isDead: false),
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
              ),
              Text(
                '$minutes:$seconds',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  itemCount: _players.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    final isSelected = player.id == _selectedPlayerId;
                    final isVotable = !player.isDead;

                    return GestureDetector(
                      onTap: isVotable
                          ? () {
                              setState(() {
                                _selectedPlayerId = player.id;
                              });
                            }
                          : null,
                      child: Opacity(
                        opacity: isVotable ? 1.0 : 0.4,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
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
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              player.nickname,
                              style: const TextStyle(
                                color: Color(0xFFDCC8A0),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
                    backgroundColor: const Color(0xFFDCC8A0),
                    foregroundColor: const Color(0xFF003943),
                    disabledBackgroundColor:
                        const Color(0xFFDCC8A0).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'confirm your victim',
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
