import 'package:flutter_test/flutter_test.dart';
import 'package:spella/core/models/letter_tile.dart';
import 'package:spella/core/models/score_breakdown.dart';
import 'package:spella/core/models/slot_bonus.dart';
import 'package:spella/core/services/scoring_service.dart';

List<LetterTile> tilesOf(String word) => <LetterTile>[
  for (int i = 0; i < word.length; i++) LetterTile.of(word[i], index: i),
];

List<SlotBonus> plainSlots(int count) => List<SlotBonus>.filled(count, SlotBonus.none);

void main() {
  final ScoringService scoring = ScoringService();

  group('scoreArrangement', () {
    test('sums letter values when no bonuses apply', () {
      // c=3, a=1, t=1
      final ScoreBreakdown breakdown = scoring.scoreArrangement(
        tiles: tilesOf('cat'),
        bonuses: plainSlots(7),
        rackSize: 7,
      );

      expect(breakdown.letterPoints, 5);
      expect(breakdown.total, 5);
    });

    test('applies the letter multiplier of the slot the tile landed on', () {
      final List<SlotBonus> bonuses = plainSlots(7).toList()
        ..[0] = SlotBonus.tripleLetter;

      // c=3 tripled, plus a=1 and t=1.
      final ScoreBreakdown breakdown = scoring.scoreArrangement(
        tiles: tilesOf('cat'),
        bonuses: bonuses,
        rackSize: 7,
      );

      expect(breakdown.letterPoints, 11);
    });

    test('multiplies the whole word when a word bonus is covered', () {
      final List<SlotBonus> bonuses = plainSlots(7).toList()..[1] = SlotBonus.doubleWord;

      final ScoreBreakdown breakdown = scoring.scoreArrangement(
        tiles: tilesOf('cat'),
        bonuses: bonuses,
        rackSize: 7,
      );

      expect(breakdown.wordMultiplier, 2);
      expect(breakdown.multipliedPoints, 10);
    });

    test('ignores a bonus the word is too short to reach', () {
      final List<SlotBonus> bonuses = plainSlots(7).toList()..[5] = SlotBonus.tripleWord;

      final ScoreBreakdown breakdown = scoring.scoreArrangement(
        tiles: tilesOf('cat'),
        bonuses: bonuses,
        rackSize: 7,
      );

      expect(breakdown.wordMultiplier, 1);
    });

    test('rewards length past four letters', () {
      final ScoreBreakdown breakdown = scoring.scoreArrangement(
        tiles: tilesOf('planet'),
        bonuses: plainSlots(7),
        rackSize: 7,
      );

      expect(breakdown.lengthBonus, 2 * ScoringService.lengthBonusPerLetter);
    });

    test('awards the full rack bonus for using every tile', () {
      final ScoreBreakdown breakdown = scoring.scoreArrangement(
        tiles: tilesOf('planets'),
        bonuses: plainSlots(7),
        rackSize: 7,
      );

      expect(breakdown.fullRackBonus, ScoringService.fullRackBonus);
    });

    test('scales the speed bonus by the fraction of the clock left', () {
      final ScoreBreakdown breakdown = scoring.scoreArrangement(
        tiles: tilesOf('cat'),
        bonuses: plainSlots(7),
        rackSize: 7,
        secondsRemaining: 20,
        secondsTotal: 40,
      );

      expect(breakdown.speedBonus, ScoringService.maxSpeedBonus ~/ 2);
    });

    test('an empty board scores nothing', () {
      final ScoreBreakdown breakdown = scoring.scoreArrangement(
        tiles: const <LetterTile>[],
        bonuses: plainSlots(7),
        rackSize: 7,
      );

      expect(breakdown.total, 0);
    });
  });

  group('bestScoreFor', () {
    test('puts the most valuable letter on the biggest letter multiplier', () {
      final List<SlotBonus> bonuses = plainSlots(7).toList()
        ..[0] = SlotBonus.tripleLetter;

      // Best is z(10) tripled + o(1) + o(1) = 32.
      final ScoreBreakdown best = scoring.bestScoreFor(
        word: 'zoo',
        bonuses: bonuses,
        rackSize: 7,
      );

      expect(best.letterPoints, 32);
    });

    test('never scores below the arrangement the player chose', () {
      final List<SlotBonus> bonuses = plainSlots(7).toList()
        ..[2] = SlotBonus.doubleLetter;

      final ScoreBreakdown played = scoring.scoreArrangement(
        tiles: tilesOf('quiz'),
        bonuses: bonuses,
        rackSize: 7,
      );
      final ScoreBreakdown best = scoring.bestScoreFor(
        word: 'quiz',
        bonuses: bonuses,
        rackSize: 7,
      );

      expect(best.total, greaterThanOrEqualTo(played.total));
    });
  });
}
