# chill_nvim

A Neovim plugin that plays ambient background audio to help you chill while coding.

## Prerequisites

Install `mpv` media player:

- **Linux**: `sudo apt install mpv`
- **macOS**: `brew install mpv`

## Installation

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'JacobACan/chill_nvim',
  event = 'VimEnter',
  lazy = false,
}
```

## How It Works

The plugin scans two directories for audio files:

- `plugin/audio/music/` - Background music tracks
- `plugin/audio/ambiance/` - Ambient sounds (rain, nature, etc.)

On startup, it automatically begins playing random audio from both directories:

- **Music**: Plays on a random interval (2-5 minutes)
- **Ambiance**: Plays on a shorter interval (30-120 seconds)
- Each track is randomly selected, avoiding the same file twice in a row

## Adding Audio Files

Simply drop audio files into the appropriate directories:

```
plugin/audio/music/
  ├── song1.mp3
  ├── song2.ogg
  └── ...

plugin/audio/ambiance/
  ├── rain.mp3
  ├── forest.wav
  └── ...
```

Supported formats: `.mp3`, `.ogg`, `.wav`

## Configuration

The plugin works out of the box with sensible defaults. If you'd like to customize it, you can modify the `config` table in `plugin/init.lua`:

```lua
local config = {
  music_interval_min = 300,    -- Min seconds between music tracks
  music_interval_max = 120,    -- Max seconds between music tracks
  ambiance_interval_min = 30, -- Min seconds between ambiance sounds
  ambiance_interval_max = 120, -- Max seconds between ambiance sounds
  music_volume = 70,          -- Music volume (0-100)
  ambiance_volume = 75,       -- Ambiance volume (0-100)
  extensions = { '.mp3', '.ogg', '.wav' }, -- Supported audio formats
}
```

## Troubleshooting

If audio doesn't play:

1. Ensure `mpv` is installed: `which mpv`
2. Check Neovim notifications for error messages
3. Verify audio files exist in the correct directories

## License

MIT
