import 'package:flutter/material.dart';
import 'package:llm_in_fabula/widgets/themed_widgets.dart';
import '../shared_widgets.dart';

// Test screen for RoleScreen
class RoleScreenPreview extends StatelessWidget {
  const RoleScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    const roleName = 'wolf';
    const roleDescription = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    return GradientPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 24.0),
        child: Column(
          children: [
            const Text(
              '00:30',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 16),
            const Text(
              'YOUR ROLE',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 4),
                image: const DecorationImage(
                  image: AssetImage('assets/images/moon2.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              roleName.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFDCC8A0),
                fontSize: 48,
                fontFamily: 'JollyLodger-Regular',
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF9E9D89),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    roleDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF282828), height: 1.5, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
