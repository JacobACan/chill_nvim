local M = {}

local config = {
  music_interval_min = 300,
  music_interval_max = 120,
  ambiance_interval_min = 30,
  ambiance_interval_max = 120,
  music_volume = 70,
  ambiance_volume = 75,
  extensions = { '.mp3', '.ogg', '.wav' },
}

local state = {
  music_files = {},
  ambiance_files = {},
  last_music = nil,
  last_ambiance = nil,
  music_pid = nil,
  ambiance_pid = nil,
  music_timer = nil,
  ambiance_timer = nil,
  music_socket = '/tmp/chill-music.sock',
  ambiance_socket = '/tmp/chill-ambiance.sock',
}

local function notify(msg)
  vim.schedule(function() vim.api.nvim_notify('[chill] ' .. msg, vim.log.levels.INFO, { timeout = 2000 }) end)
end

local function get_plugin_dir()
  local info = debug.getinfo(1, 'S')
  local path = info.source:sub(2)
  path = vim.fn.fnamemodify(path, ':p:h')
  return path
end

local function scan_directory(dir)
  local files = {}
  local handle = vim.fn.glob(dir .. '/*', true, true)
  for _, filepath in ipairs(handle) do
    if vim.fn.isdirectory(filepath) == 0 then
      local ext = string.lower(vim.fn.fnamemodify(filepath, ':e'))
      for _, valid_ext in ipairs(config.extensions) do
        if ext == valid_ext:sub(2) then
          table.insert(files, filepath)
          break
        end
      end
    end
  end
  return files
end

local function check_mpv()
  if vim.fn.executable 'mpv' == 0 then
    notify 'mpv not found. Please install: sudo apt install mpv (Linux) or brew install mpv (macOS)'
    return false
  end
  return true
end

local function get_random_file(files, last_file)
  if #files == 0 then return nil end
  if #files == 1 then return files[1] end
  local candidates = {}
  for _, f in ipairs(files) do
    if f ~= last_file then table.insert(candidates, f) end
  end
  if #candidates == 0 then return files[math.random(#files)] end
  return candidates[math.random(#candidates)]
end

local function send_mpv_command(socket_path, command)
  local cmd = string.format('echo \'{"command":%s}\' | socat - %s', vim.fn.json_encode(command), socket_path)
  vim.fn.system(cmd)
end

local function stop_mpv(pid, socket_path)
  if pid and pid > 0 then vim.fn.jobstart({ 'kill', pid }, { detach = true }) end
  if vim.fn.filereadable(socket_path) == 1 then vim.fn.delete(socket_path) end
end

local function play_file(filepath, volume, socket_path, callback)
  if not filepath or filepath == '' then return end

  local pid_var = filepath == state.music_files[1] and 'music_pid' or 'ambiance_pid'
  local socket_var = filepath == state.music_files[1] and 'music_socket' or 'ambiance_socket'

  if state[pid_var] then stop_mpv(state[pid_var], state[socket_var]) end

  local socket = state[socket_var]
  vim.fn.delete(socket)

  local cmd = {
    'mpv',
    '--no-video',
    '--idle=no',
    '--volume=' .. volume,
    '--input-ipc-server=' .. socket,
    filepath,
  }

  local job_opts = {
    on_exit = function(_, exit_code)
      state[pid_var] = nil
      if callback then callback() end
    end,
  }

  state[pid_var] = vim.fn.jobstart(cmd, job_opts)
end

local function schedule_next_music()
  if #state.music_files == 0 then return end

  local interval = config.music_interval_min + math.random(0, config.music_interval_max)
  state.music_timer = vim.fn.timer_start(interval * 1000, function()
    local file = get_random_file(state.music_files, state.last_music)
    if file then
      state.last_music = file
      notify('Now playing: ' .. vim.fn.fnamemodify(file, ':t'))
      play_file(file, config.music_volume, state.music_socket, function() schedule_next_music() end)
    end
  end)
end

local function schedule_next_ambiance()
  if #state.ambiance_files == 0 then return end

  local interval = config.ambiance_interval_min + math.random(0, config.ambiance_interval_max)
  state.ambiance_timer = vim.fn.timer_start(interval * 1000, function()
    local file = get_random_file(state.ambiance_files, state.last_ambiance)
    if file then
      state.last_ambiance = file
      notify('Ambiance: ' .. vim.fn.fnamemodify(file, ':t'))
      play_file(file, config.ambiance_volume, state.ambiance_socket, function() schedule_next_ambiance() end)
    end
  end)
end

local function start_playback()
  math.randomseed(os.time())

  if #state.music_files > 0 then
    local file = get_random_file(state.music_files, nil)
    if file then
      state.last_music = file
      notify('Now playing: ' .. vim.fn.fnamemodify(file, ':t'))
      play_file(file, config.music_volume, state.music_socket, function() schedule_next_music() end)
    end
  end

  if #state.ambiance_files > 0 then
    local file = get_random_file(state.ambiance_files, nil)
    if file then
      state.last_ambiance = file
      notify('Ambiance: ' .. vim.fn.fnamemodify(file, ':t'))
      play_file(file, config.ambiance_volume, state.ambiance_socket, function() schedule_next_ambiance() end)
    end
  end
end

local function init()
  if not check_mpv() then return end

  local plugin_dir = get_plugin_dir()
  local music_dir = plugin_dir .. '/audio/music'
  local ambiance_dir = plugin_dir .. '/audio/ambiance'

  state.music_files = scan_directory(music_dir)
  state.ambiance_files = scan_directory(ambiance_dir)

  if #state.music_files == 0 and #state.ambiance_files == 0 then
    notify 'No audio files found in audio/music or audio/ambiance'
    return
  end

  notify('Chill loaded: ' .. #state.music_files .. ' music, ' .. #state.ambiance_files .. ' ambiance files')

  start_playback()
end

M.init = init

if vim.v.vim_did_enter == 1 then
  init()
else
  vim.api.nvim_create_autocmd('VimEnter', {
    callback = init,
    once = true,
  })
end

return M
