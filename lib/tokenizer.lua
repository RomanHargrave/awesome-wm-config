-- Decompose text.
-- (C) 2020- Roman Hargrave

local Tokenizer = {}

local function is_whitespace(c)
   return c == ' ' or c == '\r' or c == '\n' or c == '\t' -- also lazy
end

local function is_quote(c)
   return c == '"' or c == "'"
end

local function is_esc(c)
   return c == '\\'
end

-- Decompose a string composed of space-separated tokens into its individual tokens.
-- Supports quoting, and partial tokenization.
--
-- Specifically, the tokenizer accepts two parameters - a string, and a "cutoff point" (e.g. a cursor position).
-- The tokenizer will process the string, assembling a table consisting of tables representing either
-- tokens or non-token spans (e.g. \t, space, etc...)
-- Tokens may be made to contain spaces via quoting ("", '') of the token or escaping spaces.
Tokenizer.tokenize = function (str, up_to)
   up_to = up_to or #str

   -- Token fields
   -- {
   --   whitespace  = true, -- is the token whitespace?
   --   content     = '',
   --   quote       = nil, -- contains quotation mark used if applicable
   --   cutoff_pos  = nil, -- if non-nil, this number is the position within the token that the cutoff fell
   -- }
   local token = nil
   local tokens = {}

   -- walk string
   for i = 1, #str do
      local c = str:sub(i, i)
      local n = str:sub(i + 1, i + 1)

      local whitespace = is_whitespace(c) and not esc_flag
      local quote = is_quote(c) and not esc_flag
      local esc = is_esc(c) and not esc_flag

      -- if we aren't working on a token, initialize an appropriate token
      if not esc_flag and c == ' ' and not token then
         token = {
            whitespace = true,
            content    = '',
            quote      = '',
            start_pos  = i
         }
      elseif not token then
         token = {
            whitespace = false,
            content    = '',
            quote      = '',
            start_pos  = i
         }
      end

      -- distance between current character position and cutoff
      local co = i - up_to
      if co == 0 then -- we are at the character at the cutoff
         token.cutoff_pos = #token.content + 1
      end

      --'test string  "with spaces" \\a\\ \\ 'print("e=" .. tostring(esc) .. " ef=" .. tostring(esc_flag) .. " c=«" .. c .. "» n=«" .. tostring(n) .. "»" .. " «" .. token.content .. "»")
      
      if false and esc and token.whitespace then -- if in a whitespace token, stop building the current token
         token.end_pos = i - 1 -- end pos is before this char, since we're examining \
         table.insert(tokens, token)
         token = nil
         -- continue
      elseif whitespace and token.whitespace then -- append whitespace
         token.content = token.content .. c

         if not is_whitespace(n) then -- finish whitespace if next char is not whitespace
            token.end_pos = i
            table.insert(tokens, token)
            token = nil
         end
         -- continue
      elseif quote and token.quote == '' and not esc_flag then -- effectively will be the first char in the token
         token.quote = c
         -- continue
      elseif c == token.quote and not esc_flag then -- effective end of token (yeah, a little lazy)
         token.end_pos = i
         table.insert(tokens, token)
         token = nil
         -- continue
      else
         if not esc then
            token.content = token.content .. c
         end

         if (is_whitespace(n) and token.quote == '' and not esc) or n == '' then
            token.end_pos = i
            table.insert(tokens, token)
            token = nil
         end
      end

      esc_flag = esc
   end

   if token then
      table.insert(tokens, token)
   end

   local result = {
      tokens     = tokens,
      words      = {},
      at_cutoff  = nil,
      tokens_lhs = {},
      tokens_rhs = {},
      argv       = {}
   }

   for _, token in ipairs(tokens) do
      if result.at_cutoff then
         table.insert(result.tokens_rhs, token)
      else
         table.insert(result.tokens_lhs, token)
      end

      if token.cutoff_pos then
         result.at_cutoff = token
      end

      if not token.whitespace then
         table.insert(result.words, token)
      end
   end
   
   return result
end

-- Glue tokens back together
Tokenizer.join = function (tokens)
   local buf = ''

   for _, token in ipairs(tokens) do
      local q = token.quote or ''
      local content = token.content
      local escaped = ''
      for i = 1, #content do
         local c = content:sub(i, i)
         
         if c == q or is_esc(c) then
            escaped = escaped .. '\\'
         elseif q == '' and is_whitespace(c) and not token.whitespace then
            escaped = escaped .. '\\'
         end

         escaped = escaped .. c
      end
      
      buf = buf .. q .. escaped .. q
   end

   return buf
end

return Tokenizer
