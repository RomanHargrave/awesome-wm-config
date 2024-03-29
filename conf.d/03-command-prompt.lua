-- Command prompt for awesome
-- (C) 2020- Roman Hargrave
-- License: GPL-3

local wm = require('awful')
local util = require('gears')
local wibox = require('wibox')
local theme = require('beautiful')
local tokenizer = require('lib/tokenizer')

local CommandPrompt = {}

-- @param commands command table reference
function CommandPrompt:new(commands)
   local inst = {
      wibox = wibox { ontop = true },
      prompt = wm.widget.prompt(),
      prompt_args = {},
      layout = wibox.layout.fixed.vertical(),
      suggestion_layout = wibox.layout.fixed.vertical(),
      geometry = {
         min_height = theme.get_font_height(theme.font),
         inset = 2,
         width_factor = 5,
         width = nil
      },
      suggestions = {},
      suggestion_cache = setmetatable({}, {__mode = 'kv'}),
      selected_suggestion = nil,
      selection_index = 0,
      commands = commands
   }

   setmetatable(inst, self)
   self.__index = self

   
   inst.layout:add(inst.prompt)
   inst.layout:add(inst.suggestion_layout)

   local inset = inst.geometry.inset

   inst.geometry.min_height = inst.geometry.min_height + (inset * 2)
   inst.margin = wibox.container.margin(inst.layout, inset, inset, inset, inset)

   inst.wibox:set_widget(inst.margin)

   -- abusing anon functions to call mt fn correctly
   inst.prompt_args = {
      prompt = '% ',
      textbox = inst.prompt.widget,
      done_callback = function()
         inst:hide()
      end,
      changed_callback = function(text)
         return inst:generate_suggestions(text)
      end,
      keypressed_callback = function(mod, key, text)
         return inst:handle_keypress(mod, key, text)
      end,
      completion_callback = function(text, pos, n)
         return inst:handle_completion(text, pos, n)
      end,
      exe_callback = function(text)
         return inst:invoke_command(text)
      end
   }

   return inst
end

-- Handle keypresses from prompt
-- @param mod table of modifiers
-- @param key keysym pressed
-- @param text prompt content
function CommandPrompt:handle_keypress(mod, key, text)
   if key == "Up" then
      self.selection_index = math.max(1, self.selection_index - 1)
      return true
   elseif key == "Down" then
      self.selection_index = self.selection_index + 1 -- update_suggestions will prevent read-beyond
      return true
   end
end

function CommandPrompt:invoke_command(command)
   local syn = tokenizer.tokenize(command)
   if syn.head then
      local argv = syn.head:collect_plain_words()
      argv.raw = command
      argv.syn = syn

      local command = nil
      for _, cmd in ipairs(self.commands) do
         if cmd.verb == argv[1] then
            command = cmd
            break
         end
      end

      if command and command.exec_fn then
         local e, r = pcall(command.exec_fn, argv)
         return r
      end
   end
end

-- search suggestions for a suggestion where .text == text
-- @param text suggestion text
function CommandPrompt:find_suggestion_by_text(text)
   for _, suggestion in ipairs(self.suggestions) do
      if suggestion.text == text then
         return suggestion
      end
   end

   return nil
end

local function str_join(tbl, delim)
   local a = ''
   for _, t in ipairs(tbl) do
      a = a .. delim .. t
   end
   return a:sub(2, #a)
end

-- Handle prompt completion, operates on space-separated tokens
-- @param content current prompt contents
-- @param cursor_pos current index within prompt
-- @param cycle current iteration in completion
function CommandPrompt:handle_completion(content, cursor_pos, cycle)
   local syn = tokenizer.tokenize(content, cursor_pos)

   if cycle == 1 then
      self.working_suggestions = util.table.join(self.suggestions)
      self.working_suggestion_index = self.selection_index
   end

   local suggestion =
      self.working_suggestions[math.fmod(self.working_suggestion_index - 1 + cycle - 1, #self.working_suggestions) + 1]

   if suggestion then
      local at_point = nil

      if not syn.head then -- if there is no head token (content = '') then crete one
         syn.head = tokenizer.singleton(suggestion.text)
         at_point = syn.head
      else -- otherwise, append to or alter the split point (can be tail if cursor_pos == #content)
         if syn.split_token.whitespace then -- the split token is whitespace, so we need to append the suggestion
            at_point = syn.split_token:append(tokenizer.singleton(suggestion.text))
         else -- the split token is not whitespace, so we need to update its contents
            syn.split_token:update(suggestion.text)
            at_point = syn.split_token
         end
      end

      return syn.head:join(), at_point.end_pos + 1
   end
   
   return content, cursor_pos
end

-- Generate suggestions for a query
-- TODO it would be great if i could inspect the cursor position in the prompt...
-- @param query prompt content
function CommandPrompt:generate_suggestions(query)
   self.suggestions = {}
   local syn = tokenizer.tokenize(query)
   local count = 0
   local verb = ''
   if syn.head then
      verb = syn.head.content
      count = syn.head:word_count()
   end

   for _, command in ipairs(self.commands) do
      if string.match(command.verb, '^' .. verb) then
         table.insert(self.suggestions, { command = command,
                                          description = command.description,
                                          text = command.verb })
      end
   end
   
   if count > 0 then
      local suggestion = self:find_suggestion_by_text(verb)

      if suggestion
         and suggestion.command
         and suggestion.command.completion_fn
      then
         local s, r = pcall(suggestion.command.completion_fn, { syn = syn, query = query })
         if s then
            self.suggestions = r or {}
         else
            util.debug.print_warning('Completion delegate failed for verb «' .. verb .. '»: ' .. tostring(r))
         end
      else
         -- don't show anything, otherwise we'd be offering bad completions
         self.suggestions = {}
      end
   end
   
   if self.selection_index > #self.suggestions then
      self.selection_index = #self.suggestions
   elseif self.selection_index == 0 and #self.suggestions > 0 then
      self.selection_index = 1
   end

   if self.selection_index > 0 then
      self.selected_suggestion = self.suggestions[self.selection_index]
   end

   -- now, (re-)populate the suggestion layout
   wm.widget.common.list_update(
      self.suggestion_layout,
      nil, -- this would be a set of buttons (mouse) to handle
      function(obj) -- label function
         return self:generate_suggestion_label(obj)
      end,
      self.suggestion_cache, -- data
      self.suggestions -- list
   )

   -- and adjust the wibox geometry to fit them
   self.wibox:geometry({ height = self.geometry.min_height + (theme.get_font_height(theme.font) * #self.suggestions) })
end

-- Generate label for a suggestion
-- @param suggestion suggestion
function CommandPrompt:generate_suggestion_label(suggestion)
   local text = util.string.xml_escape(suggestion.text)

   if suggestion.description then
      text = text .. ' <i>«' .. util.string.xml_escape(suggestion.description) .. '»</i>'
   end

   local fg = theme.menubar_fg_normal or theme.menu_fg_normal or theme.fg_normal
   local bg = theme.menubar_bg_normal or theme.menu_bg_normal or theme.bg_normal

   if suggestion == self.selected_suggestion then
      fg = theme.menubar_fg_focus or theme.menu_fg_focus or theme.fg_focus
      bg = theme.menubar_bg_focus or theme.menu_bg_focus or theme.bg_focus
   end

   text = '<span color="' .. util.color.ensure_pango_color(fg) .. '">' .. text .. '</span>'

   return text, bg, nil, nil
end

-- Show the command prompt
function CommandPrompt:show()
   if self:visible() then return end

   local screen = wm.screen.focused()

   if not screen then return end

   local computed_width =
      self.geometry.width or (screen.workarea.width / self.geometry.width_factor)

   local center_x =
      screen.workarea.x
      + (screen.workarea.width / 2)
      - (computed_width / 2)

   local center_y =
      screen.workarea.y
      + (screen.workarea.height / 2)
      - (self.geometry.min_height / 2)

   self.wibox:geometry({ x = center_x,
                         y = center_y,
                         width = computed_width,
                         height = self.geometry.min_height })

   self.wibox.visible = true

   self:generate_suggestions('')

   wm.prompt.run(self.prompt_args)
end

function CommandPrompt:hide()
   self.wibox.visible = false
end

function CommandPrompt:visible()
   return self.wibox.visible
end

return function(state, full)
   state.commands = util.table.join(state.commands or {}, base_commands)
   
   state.command_prompt = CommandPrompt:new(state.commands)

   table.insert(state.keys,
                wm.key({}, 'Super_R', function()
                      if not state.command_prompt:visible() then
                         state.command_prompt:show()
                      end
                end)
   ) -- table.insert
end
