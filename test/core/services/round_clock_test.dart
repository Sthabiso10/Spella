import 'package:flutter_test/flutter_test.dart';
import 'package:spella/core/services/round_clock.dart';

void main() {
  late RoundClock clock;
  late int ticks;
  late int expiries;

  setUp(() {
    ticks = 0;
    expiries = 0;
    clock = RoundClock(onTick: () => ticks++, onExpired: () => expiries++);
  });

  tearDown(() => clock.dispose());

  testWidgets('a reset clock is loaded but not running', (WidgetTester tester) async {
    clock.reset(45);

    expect(clock.remaining, 45);
    expect(clock.allotted, 45);
    expect(clock.elapsed, 0);
    expect(clock.progress, 1);
    expect(clock.isRunning, isFalse);

    await tester.pump(const Duration(seconds: 3));
    expect(clock.remaining, 45, reason: 'a clock that was never started');
  });

  testWidgets('a running clock counts down and reports each second', (
    WidgetTester tester,
  ) async {
    clock
      ..reset(45)
      ..start();

    await tester.pump(const Duration(seconds: 3));

    expect(clock.remaining, 42);
    expect(clock.elapsed, 3);
    expect(ticks, 3);
    clock.stop();
  });

  testWidgets('a paused clock holds, and picks up where it left off', (
    WidgetTester tester,
  ) async {
    clock
      ..reset(45)
      ..start();
    await tester.pump(const Duration(seconds: 5));

    clock.pause();
    expect(clock.isPaused, isTrue);
    expect(clock.isRunning, isFalse);

    // The whole point: time passing while the game is not in the player's
    // hands must not come off their clock.
    await tester.pump(const Duration(seconds: 30));
    expect(clock.remaining, 40);

    clock.resume();
    await tester.pump(const Duration(seconds: 2));
    expect(clock.remaining, 38);
    clock.stop();
  });

  testWidgets('resuming a clock that was never paused does nothing', (
    WidgetTester tester,
  ) async {
    clock.reset(45);
    clock.resume();

    expect(clock.isRunning, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(clock.remaining, 45);
  });

  testWidgets('extending buys a longer round, not a fuller one', (
    WidgetTester tester,
  ) async {
    clock
      ..reset(45)
      ..start();
    await tester.pump(const Duration(seconds: 5));

    clock.extend(15);

    // Both sides grow, so the bar still reads as draining rather than pinning
    // at full, and the play is still recorded as having taken five seconds.
    expect(clock.remaining, 55);
    expect(clock.allotted, 60);
    expect(clock.elapsed, 5);
    expect(clock.progress, lessThanOrEqualTo(1));
    clock.stop();
  });

  testWidgets('progress never leaves 0..1 however much time is bought', (
    WidgetTester tester,
  ) async {
    clock
      ..reset(25)
      ..start();

    for (int i = 0; i < 5; i++) {
      clock.extend(15);
      await tester.pump(const Duration(seconds: 1));
      expect(clock.progress, inInclusiveRange(0, 1));
      expect(clock.elapsed, greaterThanOrEqualTo(0));
    }
    clock.stop();
  });

  testWidgets('the clock expires once, at zero', (WidgetTester tester) async {
    clock
      ..reset(3)
      ..start();

    await tester.pump(const Duration(seconds: 3));

    expect(clock.remaining, 0);
    expect(clock.isRunning, isFalse);
    expect(expiries, 1);

    await tester.pump(const Duration(seconds: 5));
    expect(expiries, 1, reason: 'a finished clock keeps quiet');
  });

  testWidgets('starting an empty clock does not fire', (WidgetTester tester) async {
    clock
      ..reset(0)
      ..start();

    await tester.pump(const Duration(seconds: 2));
    expect(expiries, 0);
    expect(clock.progress, 0);
  });
}
