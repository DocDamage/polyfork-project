# AI Creation System

## Provider model
Provider-agnostic adapter interface. Support local and cloud providers without coupling the editor to one vendor.

## Modes
- Suggest: return plan only.
- Preview: create ghost/proposed results.
- Execute: commit changes.

## Grounding
AI queries the actual local asset registry and project state. Requests like "build an abandoned gas station" must resolve available assets, terrain constraints, roads, and project rules.

## Transaction boundary
Each accepted AI command is one top-level transaction even if it creates or modifies hundreds of child operations. One Undo reverts the entire command.

## Safety and trust
- Show what will change before destructive operations.
- Preserve source/license metadata.
- Never overwrite source assets.
- Record an AI action history with prompt, provider, resolved asset IDs, and transaction ID.
- Allow deterministic replay only when commands are deterministic and dependencies still exist.
