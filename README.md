# Sirius

A zero-replication-overhead cinematic death system for Roblox. Replaces the default death sequence with a smooth out-of-body soul experience where the player freely navigates the world before respawning.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Language: Luau](https://img.shields.io/badge/Language-Luau-red.svg)]()
[![Status: Active](https://img.shields.io/badge/Status-Active-brightgreen.svg)]()

---

## Demo

[![Watch Demo](https://img.shields.io/badge/%E2%96%B6%20Watch%20Demo-Jumpshare-2962FF?style=for-the-badge)](https://jumpshare.com/share/LWM307YQgz2uKM0TC7MaBYnu8)

You can also try the [Test Game on Roblox](https://www.roblox.com/games/110489496445625/Sirius-Project).

---

## Highlights

- **Zero server replication** — Death events broadcast via a single `RemoteEvent` dispatch. No character cloning, no part replication, no streaming impact on other players.
- **Client-rendered soul** — All animation, movement, and camera logic runs locally on the dying client.
- **Cinematic camera** — Dynamic FOV expansion bound to `RenderStepped` with sine-out easing for a wide-angle, stutter-free transition.
- **Concurrency safe** — Server cost stays constant whether one or fifty players die simultaneously.
- **Drop-in** — Two folders, two locations, works without modifying existing systems.

---

## Architecture

Sirius separates responsibilities by trust boundary:

| Concern | Owner | Reason |
|---|---|---|
| Death detection | Server | Authoritative; client cannot fake death |
| Soul rendering | Client | Local-only; never replicates |
| Camera transition | Client (`RenderStepped`) | Frame-pacing tied to client refresh rate |
| Respawn trigger | Client → Server | UI prompt confirms; `CharacterAutoLoads` is disabled |

When a `Humanoid` dies, the server fires a single `RemoteEvent:FireClient(player)`. The client then:

1. Instantiates a local soul model (or fallback orb) directly in its own Workspace.
2. Detaches the existing camera subject and binds a custom render loop.
3. Interpolates camera CFrame and Field of View with a sine-out easing curve.
4. Hands movement control to the soul entity until the player initiates respawn.
5. Signals the server to load a fresh character.

Because the soul never replicates, server CPU and bandwidth costs are identical regardless of concurrent death count.

---

## Performance Notes

- **Server cost per death:** a single `RemoteEvent:FireClient` invocation. Sub-microsecond at the dispatch layer.
- **Client cost:** comparable to a standard custom camera. The `RenderStepped` binding adds no frame-time cost outside the death window.
- **No `Heartbeat` polling**, no part streaming, no animation track replication.
- **Minified codebase** — boilerplate stripped, fast parse and execution.

---

## Installation

### Option A — Manual (no tooling)

1. Download this repository.
2. Copy the contents of `src/Server` into `ServerScriptService`.
3. Copy the contents of `src/Client` into `StarterPlayerScripts`.
4. Play — the system hooks `Humanoid.Died` automatically.

### Option B — Rojo

The repository includes a working `default.project.json` and `aftman.toml`:

```bash
aftman install
rojo serve
```

Connect the Rojo plugin in Studio and sync.

---

## Roadmap

- Configuration API (flight speed, FOV target, easing curve, soul model override)
- Optional cross-player visibility (souls can see each other in a shared spirit realm)
- Custom particle and `Highlight` property overrides
- Cinematic post-processing (depth of field, color correction for the "spirit realm" effect)
- Mobile UI and input optimization

Track progress in [Issues](../../issues).

---

## Contributing

Feedback, code reviews, and pull requests are welcome. For larger feature work, please open an issue first so we can align on scope and API shape.

---

## License

Released under the [MIT License](LICENSE).

---

## Contact

- **Discord:** `@baranyerlikaya`
- **DevForum:** [Sirius release thread](https://devforum.roblox.com/t/sirius-zero-lag-cinematic-out-of-body-death-experience-open-source/4696939)
