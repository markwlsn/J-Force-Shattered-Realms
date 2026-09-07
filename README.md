# ⚔️ J Force: Shattered Realms

A multiplayer PvP arena fighter built on **Roblox** set in the **Shattered Realms** — a fractured dimension where three worlds have collided. Players choose one of three anime-inspired factions (**Pirate**, **Shinigami**, **Ninja**), fight in arena matches to earn currency, and progressively unlock and equip skills from branching skill trees to create unique custom builds.

---

## 🎮 Core Gameplay

```
Fight → Earn → Unlock → Customize → Fight
```

| Feature | Description |
|---|---|
| **3 Factions** | Pirate, Shinigami, Ninja — each with 4 branching skill paths |
| **Skill Trees** | 3 tiers of depth per path, mix-and-match builds |
| **Loadout System** | 4 Active + 2 Passive + 1 Ultimate — limited slots = strategic depth |
| **Arena Modes** | 1v1 Ranked, 2v2, Free-for-All, 3v3v3 Faction War, PvE Boss Raids |
| **Progression** | Earn Gold & XP → unlock skills → climb ranks (Bronze → Legend) |
| **Fair Play** | Cosmetics-only monetization, no pay-to-win |

---

## 📁 Project Structure

```
J-Force-Shattered-Realms/
├── default.project.json                    ← Rojo project config
├── JForceShatteredRealms_GameSpec.md       ← Full game design spec (for AI/devs)
├── src/
│   ├── ReplicatedStorage/
│   │   ├── Remotes/
│   │   │   └── RemoteDefinitions.lua       ← All 21 network remotes
│   │   └── Shared/
│   │       ├── Config.lua                  ← All balance constants
│   │       ├── Enums.lua                   ← Game enumerations (frozen)
│   │       ├── Types.lua                   ← Data models & factories
│   │       └── Utils.lua                   ← Shared utility functions
│   ├── ServerScriptService/
│   │   ├── Main.server.lua                 ← Server entry point
│   │   └── Managers/
│   │       └── PlayerDataManager.lua       ← DataStore CRUD & migrations
│   ├── StarterGui/                         ← UI screens (coming soon)
│   ├── StarterPlayer/                      ← Client scripts (coming soon)
│   └── Workspace/                          ← Arena maps (coming soon)
└── assets/                                 ← Models, animations, sounds, VFX (coming soon)
```

---

## 🚀 Getting Started — Setup Guide

### Prerequisites

| Tool | What It Does | Install Link |
|---|---|---|
| **Roblox Studio** | The game engine | [Download](https://www.roblox.com/create) |
| **Rojo** (v7+) | Syncs files from VS Code → Roblox Studio | [Install Guide](https://rojo.space/docs/v7/getting-started/installation/) |
| **Git** | Version control | [Download](https://git-scm.com/downloads) |
| **VS Code** (recommended) | Code editor | [Download](https://code.visualstudio.com/) |
| **Rojo VS Code Extension** (optional) | Start/stop Rojo from VS Code | [Marketplace](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo) |

### Step-by-Step Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/markwlsn/J-Force-Shattered-Realms.git
cd J-Force-Shattered-Realms
```

#### 2. Install Rojo

If you haven't installed Rojo yet, install it via one of these methods:

**Option A — Aftman (recommended tool manager):**
```bash
aftman install
```

**Option B — Foreman:**
```bash
foreman install
```

**Option C — Direct download:**
Download the latest release from [rojo-rbx/rojo/releases](https://github.com/rojo-rbx/rojo/releases) and add it to your PATH.

**Option D — Roblox Studio Plugin only:**
1. Install the [Rojo Plugin](https://www.roblox.com/library/13916111004/Rojo-v7) from the Roblox Marketplace
2. You'll still need the Rojo CLI for serving

#### 3. Install the Rojo Plugin in Roblox Studio

If this is your first time using Rojo:

1. Open Roblox Studio
2. Go to **Plugins** → **Manage Plugins**
3. Search for **"Rojo"** and install it
4. You should see a **Rojo** button in your Plugins toolbar

#### 4. Serve the Project

Open a terminal in the project root and run:

```bash
rojo serve
```

You should see:
```
Rojo server listening:
  Address: localhost
  Port:    34872
```

#### 5. Connect Roblox Studio

1. Open **Roblox Studio** → create a new **Baseplate** place (or open an existing one)
2. Click the **Rojo** plugin button in the toolbar
3. Click **"Connect"**
4. You should see all the scripts appear in the Explorer panel under their correct services

> ✅ **That's it!** Rojo will now live-sync any changes you make in VS Code directly into Roblox Studio.

#### 6. Verify It Works

After connecting, check the Roblox Studio **Output** window. You should see:

```
========================================
  J Force: Shattered Realms - Server Starting
========================================
[Main] Server initialized successfully!
[Main] Loaded managers: PlayerDataManager
[Main] Waiting for players...
```

When you hit **Play** in Studio, you should see:
```
[Main] Player joined: YourUsername
[PlayerDataManager] Loaded data for YourUsername
```

---

## 🛠️ Development Workflow

### Making Changes

1. Edit `.lua` files in VS Code (or your preferred editor)
2. Rojo auto-syncs changes to Roblox Studio in real-time
3. Hit **Play** in Studio to test
4. Commit and push your changes:

```bash
git add .
git commit -m "your commit message"
git push
```

### Without Rojo (Manual Method)

If you prefer not to use Rojo:

1. Open each `.lua` file in the `src/` folder
2. In Roblox Studio, create the corresponding Script/ModuleScript in the correct service
3. Copy-paste the code into each script
4. Save the `.rbxl` file

### File Naming Conventions

Rojo uses file names to determine script types:

| File Suffix | Roblox Script Type |
|---|---|
| `.server.lua` | **Script** (runs on server) |
| `.client.lua` or `.local.lua` | **LocalScript** (runs on client) |
| `.lua` (no suffix) | **ModuleScript** (shared) |

---

## 📖 Game Specification

The full game design document is available at [`JForceShatteredRealms_GameSpec.md`](./JForceShatteredRealms_GameSpec.md). It contains:

- Complete data models (PlayerData, SkillDefinition, MatchState)
- All module API contracts with function signatures
- Every network remote with payload documentation
- Combat formulas, damage calculations, hitbox specs
- All 54 skills across 3 factions with stats
- Skill tree definitions and unlock rules
- Economy & progression tables
- UI screen specifications
- Implementation order (7 phases)

This document is designed to be handed to an **AI coding agent** or a **development team** to build from.

---

## 🗺️ Development Roadmap

| Phase | Status | Description |
|---|---|---|
| **Phase 1: Foundation** | ✅ Complete | Config, types, data persistence, networking |
| **Phase 2: Combat Core** | 🔜 Next | Hitboxes, damage, status effects, starter skills |
| **Phase 3: Skills & Trees** | ⬜ Planned | All 54 skills, skill trees, loadout system |
| **Phase 4: Match System** | ⬜ Planned | Matchmaking, arenas, round lifecycle |
| **Phase 5: Economy** | ⬜ Planned | Gold/XP rewards, ELO ranking, shop |
| **Phase 6: UI** | ⬜ Planned | All game screens and HUD |
| **Phase 7: Polish** | ⬜ Planned | VFX, SFX, balance, anti-cheat, launch |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

This project is for personal/educational use. All anime-inspired content is fan-made and not affiliated with or endorsed by the original creators of One Piece, Bleach, or Naruto.

---

**Built with ⚔️ by [markwlsn](https://github.com/markwlsn)**
