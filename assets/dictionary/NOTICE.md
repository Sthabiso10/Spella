# Dictionary asset provenance

`words_en.txt` is the word list Spella validates plays against — roughly
315,000 English words, bundled so the game works offline and a timed round
never waits on a network call.

## Source

Derived from [`words_alpha.txt`][src] in **dwyl/english-words**, released under
the [Unlicense][unlicense] — a public domain dedication. No attribution is
legally required; this file exists so the provenance stays auditable.

[src]: https://github.com/dwyl/english-words/blob/master/words_alpha.txt
[unlicense]: https://unlicense.org/

## How it was filtered

The upstream list is ~370,000 lines. Spella's copy drops:

- entries shorter than two letters, and
- any line containing a character outside `a–z`.

Every word in `words_en.txt` is present in the upstream list — it is a strict
subset, with nothing added.

To regenerate it from a fresh upstream copy:

```bash
curl -sL https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt \
  | tr -d '\r' \
  | grep -E '^[a-z]{2,}$' \
  | sort -u > assets/dictionary/words_en.txt
```

## Note on the curated list

This file is only the **validation** tier. Rack generation, hints and the bot's
moves run against the much smaller curated list in
[`lib/core/data/word_bank.dart`](../../lib/core/data/word_bank.dart), which is
hand-maintained — a bot that plays `aalii` teaches nothing and feels unfair.

See [THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md) for the project's
full attribution list.
