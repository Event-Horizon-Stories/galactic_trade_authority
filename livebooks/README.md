# Livebook Companions

These notebooks are the interactive entry points for the
`galactic_trade_authority` series.

Open them from Livebook while the repository is checked out locally. Each
notebook uses a local path dependency back to its lesson directory, so the
examples stay tied to the code in this repo instead of drifting into copied
snippets.

## Setup

From the repo root:

```bash
./scripts/install_livebook.sh
./scripts/livebook.sh server livebooks
```

## Notebooks

- [01_order.livemd](./01_order.livemd) for resources, create actions, and shipment validation
- [02_planetary_law.livemd](./02_planetary_law.livemd) for route-aware validation and tax changes
- [03_faction_power.livemd](./03_faction_power.livemd) for actor-dependent authorization and filtered reads

## Opening The Series

Then open any notebook from the `livebooks/` directory.
