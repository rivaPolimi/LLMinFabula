import 'package:flutter/material.dart';
import 'package:llm_in_fabula/models/state.dart';
import 'package:provider/provider.dart';
import '../shared_widgets.dart';

class LynchResultsScreen extends StatelessWidget {
  const LynchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (_, state, _) {
        // Create a map to count votes for each player
        final voteCounts = state.tally;

        // Find the maximum number of votes received by any player
        final maxVotes = voteCounts.values.fold(0, (max, a) => a > max ? a : max);

        // Create a list of results to display
        final results = voteCounts.entries.map((entry) {
          // This is a bit of a hack, we need a way to get the player nickname from the ID
          // For now, we'll just show the ID
          return _VoteResult(state.game!.getPlayerById(entry.key)!.nickname, entry.value);
        }).toList();

        // Sort the results by vote count in descending order
        results.sort((a, b) => b.voteCount.compareTo(a.voteCount));

        return GradientPage(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: true,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return _buildVoteResultRow(context, result, maxVotes);
                  },
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildVoteResultRow(
    BuildContext context, _VoteResult result, int maxVotes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4B8B9A), // Teal color
                    border: Border.all(
                      color: const Color(0xFF5D4D33), // Default border
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF003943), // Darker Teal icon
                    size: 40,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.nickname,
                  style: const TextStyle(color: Color(0xFFDCC8A0)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: [
                    Expanded(
                      flex: result.voteCount,
                      child: Container(
                        color: const Color(0xFFBEA774), // Light part of bar
                      ),
                    ),
                    Expanded(
                      flex: maxVotes - result.voteCount,
                      child: Container(
                        color: const Color(0xFF4B6973), // Dark part of bar
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 30,
            child: Text(
              result.voteCount.toString(),
              style: const TextStyle(color: Color(0xFFDCC8A0), fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteResult {
  final String nickname;
  final int voteCount;

  const _VoteResult(this.nickname, this.voteCount);
}
