import 'package:spella/app/app.locator.dart';
import 'package:spella/core/models/player.dart';
import 'package:spella/core/models/power_up.dart';
import 'package:spella/core/services/player_service.dart';
import 'package:stacked/stacked.dart';

/// An avatar for sale.
class AvatarOffer {
  const AvatarOffer({required this.emoji, required this.name, required this.gemCost});

  final String emoji;
  final String name;
  final int gemCost;
}

/// The shop: cosmetics you can buy now, and the boosters you spend coins on
/// mid-match.
class ShopViewModel extends ReactiveViewModel {
  final PlayerService _playerService = locator<PlayerService>();

  String? _message;

  @override
  List<ListenableServiceMixin> get listenableServices => <ListenableServiceMixin>[
    _playerService,
  ];

  Player get player => _playerService.currentPlayer;

  /// Feedback from the last purchase attempt, shown as a banner.
  String? get message => _message;

  List<PowerUp> get boosters => PowerUp.values;

  static const List<AvatarOffer> avatars = <AvatarOffer>[
    AvatarOffer(emoji: '🦸', name: 'Hero', gemCost: 0),
    AvatarOffer(emoji: '🐉', name: 'Dragon', gemCost: 30),
    AvatarOffer(emoji: '🦉', name: 'Owl', gemCost: 25),
    AvatarOffer(emoji: '🐙', name: 'Octo', gemCost: 40),
    AvatarOffer(emoji: '🤖', name: 'Bot', gemCost: 35),
    AvatarOffer(emoji: '👻', name: 'Ghost', gemCost: 20),
    AvatarOffer(emoji: '🦊', name: 'Fox', gemCost: 45),
    AvatarOffer(emoji: '🐳', name: 'Whale', gemCost: 60),
  ];

  bool isEquipped(AvatarOffer offer) => player.avatar == offer.emoji;

  bool isOwned(AvatarOffer offer) => player.owns(offer.emoji);

  bool canAfford(AvatarOffer offer) => player.gems >= offer.gemCost;

  /// Equips an owned avatar, or buys it when the player has the gems.
  void selectAvatar(AvatarOffer offer) {
    if (isEquipped(offer)) return;

    if (isOwned(offer)) {
      _playerService.equipAvatar(offer.emoji);
      _setMessage('${offer.name} equipped');
      return;
    }

    final bool bought = _playerService.unlockAvatar(offer.emoji, offer.gemCost);
    _setMessage(
      bought
          ? '${offer.name} unlocked and equipped'
          : 'You need ${offer.gemCost - player.gems} more gems for ${offer.name}',
    );
  }

  void dismissMessage() {
    if (_message == null) return;
    _message = null;
    rebuildUi();
  }

  void _setMessage(String value) {
    _message = value;
    rebuildUi();
  }
}
