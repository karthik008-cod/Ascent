import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BadgeData {
  final int level;
  final String emoji;
  final String name;
  final String desc;
  final IconData icon;

  const BadgeData({
    required this.level,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.icon,
  });
}

const List<BadgeData> allBadges = [
  // Levels 1–20: every 2nd level (10 badges)
  BadgeData(level: 2,  emoji: '🌱', name: 'Seedling',      desc: 'First steps on the path',        icon: Icons.eco_rounded),
  BadgeData(level: 4,  emoji: '🔥', name: 'Spark',         desc: 'The fire within ignites',         icon: Icons.local_fire_department_rounded),
  BadgeData(level: 6,  emoji: '⚡', name: 'Bolt',          desc: 'Quick and determined',            icon: Icons.bolt_rounded),
  BadgeData(level: 8,  emoji: '🛡️', name: 'Shield',       desc: 'Building resilience',             icon: Icons.shield_rounded),
  BadgeData(level: 10, emoji: '⭐', name: 'Rising Star',   desc: 'You\'re shining bright',          icon: Icons.star_rounded),
  BadgeData(level: 12, emoji: '🗡️', name: 'Blade',        desc: 'Sharp and focused',               icon: Icons.content_cut_rounded),
  BadgeData(level: 14, emoji: '🦅', name: 'Hawk',          desc: 'Vision from above',               icon: Icons.flight_rounded),
  BadgeData(level: 16, emoji: '💎', name: 'Diamond',       desc: 'Unbreakable spirit',              icon: Icons.diamond_rounded),
  BadgeData(level: 18, emoji: '🌊', name: 'Tidal Force',   desc: 'Unstoppable momentum',            icon: Icons.waves_rounded),
  BadgeData(level: 20, emoji: '👑', name: 'Crown',         desc: 'Royalty of discipline',           icon: Icons.workspace_premium_rounded),
  // Levels 20–50: every 5 levels (6 badges)
  BadgeData(level: 25, emoji: '🐉', name: 'Dragon',        desc: 'Power awakened',                  icon: Icons.whatshot_rounded),
  BadgeData(level: 30, emoji: '🔱', name: 'Trident',       desc: 'Master of three realms',          icon: Icons.security_rounded),
  BadgeData(level: 35, emoji: '🌌', name: 'Nebula',        desc: 'Cosmic ambition',                 icon: Icons.blur_on_rounded),
  BadgeData(level: 40, emoji: '⚜️', name: 'Sovereign',    desc: 'Stories written in gold',         icon: Icons.military_tech_rounded),
  BadgeData(level: 45, emoji: '🏔️', name: 'Summit',       desc: 'Peak of perseverance',            icon: Icons.landscape_rounded),
  BadgeData(level: 50, emoji: '🌟', name: 'Ascendant',     desc: 'Transcended all limits',          icon: Icons.auto_awesome_rounded),
  // Levels 50+: every 10 levels (5 badges)
  BadgeData(level: 60, emoji: '💫', name: 'Celestial',     desc: 'Beyond mortal bounds',            icon: Icons.brightness_7_rounded),
  BadgeData(level: 70, emoji: '🔮', name: 'Oracle',        desc: 'Wisdom of ages',                  icon: Icons.visibility_rounded),
  BadgeData(level: 80, emoji: '🌠', name: 'Supernova',     desc: 'Explosive brilliance',            icon: Icons.flare_rounded),
  BadgeData(level: 90, emoji: '🏛️', name: 'Pantheon',     desc: 'Among the immortals',             icon: Icons.account_balance_rounded),
  BadgeData(level: 100,emoji: '∞',  name: 'Infinity',      desc: 'The journey is eternal',          icon: Icons.all_inclusive_rounded),
];

String _getMilestoneMessage(int level) {
  if (level >= 100) return 'You are infinite. A true legend of Ascent. There are no limits for you!';
  if (level >= 50) return 'You\'ve transcended! The Ascendant walks among us. 🌟';
  if (level >= 40) return 'Sovereign power! Your discipline is legendary! ⚜️';
  if (level >= 30) return 'You\'ve mastered three realms of growth! Unstoppable! 🔱';
  if (level >= 20) return 'You are crowned! A royalty of discipline! 👑';
  if (level >= 15) return 'What a journey! You\'re halfway to greatness! 🚀';
  if (level >= 10) return 'You\'re a Rising Star! The world is taking notice! ⭐';
  if (level >= 5) return 'Solid foundation! You\'re building something incredible! 💪';
  return 'Great start! Every step matters! 🌱';
}

/// Shows a level-up celebration dialog. Special celebration for every 5th level.
void showLevelUpCelebration(BuildContext context, int newLevel) {
  final isMilestone = newLevel % 5 == 0;

  // Find badge for this level
  final badge = allBadges.where((b) => b.level == newLevel).toList();
  final hasBadge = badge.isNotEmpty;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Level Up',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (context, anim1, anim2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: isMilestone
                  ? const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMilestone ? null : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: isMilestone ? AppColors.accent.withOpacity(0.4) : AppColors.primary.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration header
                Text(
                  isMilestone ? '🎆 MILESTONE! 🎆' : '🎉 LEVEL UP!',
                  style: TextStyle(
                    fontSize: isMilestone ? 22 : 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: isMilestone ? AppColors.accent : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                // Level circle
                Container(
                  width: isMilestone ? 110 : 90,
                  height: isMilestone ? 110 : 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isMilestone
                        ? const LinearGradient(colors: [AppColors.accent, Color(0xFFF59E0B)])
                        : AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: (isMilestone ? AppColors.accent : AppColors.primary).withOpacity(0.5),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('LVL', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        Text('$newLevel', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Motivational message
                Text(
                  isMilestone
                      ? _getMilestoneMessage(newLevel)
                      : 'Keep pushing your limits!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isMilestone ? Colors.white : null,
                    height: 1.4,
                  ),
                ),
                // Badge unlock section
                if (hasBadge) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(badge.first.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BADGE UNLOCKED!', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.accent)),
                              Text(badge.first.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isMilestone ? Colors.white : null)),
                              Text(badge.first.desc, style: TextStyle(fontSize: 11, color: isMilestone ? Colors.white70 : AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                // Close button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMilestone ? AppColors.accent : AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      isMilestone ? 'Celebrate! 🥳' : 'Continue →',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
