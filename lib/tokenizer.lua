-- Decompose text.
-- (C) 2020- Roman Hargrave

local Tokenizer = {}
local Token = {}

local function is_whitespace(c)
   return c == ' ' or c == '\r' or c == '\n' or c == '\t' -- also lazy
end

local function is_quote(c)
   return c == '"' or c == "'"
end

local function is_esc(c)
   return c == '\\'
end

function Token:new(params)
   local content = ''
   if params.content then
      content = params.content
   end

   local t = {
      whitespace = params.whitespace or false,
      content    = content,
      quote      = params.quote or '',
      start_pos  = params.start_pos or 0,
      end_pos    = params.end_pos or (#content),
      next   = nil
   }

   setmetatable(t, self)
   self.__index = self

   return t
end

local function scan_whitespace(str)
   local r = 'none'

   local whitespace_only = true
   local whitespace_flag = false

   for i = 1, #str do
      whitespace_flag = whitespace_flag or is_whitespace(str:sub(i, i))
      whitespace_only = whitespace_only and whitespace_flag
   end

   if whitespace_only then
      r = 'only'
   elseif whitespace_flag then
      r = 'some'
   end

   return r
end

function Token.singleton(str)
   local tbl = {
      content    = str,
      quote      = '',
      start_pos  = 0,
      end_pos    = #str,
   }

   local w = scan_whitespace(str)
   if w == 'some' then
      tbl.quote = '"'
   end
   tbl.whitespace = w == 'only'

   return Token:new(tbl)
end

-- Adjust start_pos for tokens down-chain
-- Adjusts the start position of the next token to be
-- the position after this token's start position combined with its length
-- after setting the next token's start position, it has the next token
-- do the same, ad infinitum
function Token:recompute_offset()
   self.end_pos = self.start_pos + #self.content
   if self.next then
      self.next.start_pos = self.end_pos + 1
      self.next:recompute_offset()
   end
end

function Token:update(content)
   self.content = content
   local w = scan_whitespace(content)
   if w == 'some' then
      self.quote = '"'
   else
      self.quote = ''
   end
   self.whitespace = w == 'only'
   self:recompute_offset()
end

-- Append a chain of tokens to this token, recompute offset
-- This will take a token (and implicitly it's linked tokens)
-- and insert that token chain between this token and its current neighbour
-- after doing this, the start_pos will be recomputed for all tokens after this token
function Token:append(token)
   if token == nil then
      return nil
   end

   token:tail().next = self.next
   self.next = token
   self:recompute_offset()
   return token
end

-- Same as append, but inserts whitespace before the new token
-- if the next token would not otherwise be whitespace
function Token:append_sep(token)
   if self.whitespace then
      return self:append(token)
   else
      return self:append(Token.singleton(' ')):append(token)
   end
end

-- Skip whitespace after this token
function Token:next_word()
   local lnk = self.next

   while lnk do
      if not lnk.whitespace then
         return lnk
      end

      lnk = lnk.next
   end

   return nil
end

-- Return an iterator over each token
function Token:iter()
   local nxt = self
   return function()
      local tok = nxt

      if tok then
         nxt = tok.next
      end

      return tok
   end
end

-- Return an iterator over each word token
function Token:iter_words()
   local nxt = self
   if self.whitespace then
      nxt = self:next_word()
   end

   return function()
      local tok = nxt

      if tok then
         nxt = tok:next_word()
      end

      return tok
   end
end

-- Get the last token in the chain
function Token:tail()
   if self.next then
      return self.next:tail()
   else
      return self
   end
end

-- Get the last word in the chain
function Token:tail_word(limit_pos)
   local w = nil
   for word in self:iter_words() do
      if limit_pos
         and word.start_pos >= limit_pos
      then
         return w
      end

      w = word
   end
   return w
end

function Token:count()
   local r = 0
   for token in self:iter() do
      r = r + 1
   end
   return r
end

function Token:word_count()
   local r = 0
   for token in self:iter_words() do
      r = r + 1
   end
   return r
end

-- Collect words in non-token form
function Token:collect_plain_words()
   local words = {}
   for token in self:iter_words() do
      table.insert(words, token.content)
   end
   return words
end

function Token:escaped()
   if self.whitespace then
      return self.content
   else
      local buf = ''
      for i = 1, #self.content do
         local c = self.content:sub(i, i)
         if c == self.quote
            or is_esc(c)
            or (self.quote == '' and is_whitespace(c) and not self.whitespace)
         then
            buf = buf .. '\\'
         end

         buf = buf .. c
      end
      return buf
   end
end

function Token:string()
   return self.quote .. self:escaped() .. self.quote
end

function Token:join()
   local buf = ''

   for token in self:iter() do
      buf = buf .. token:string()
   end

   return buf
end

function Token:join_raw()
   local buf = ''

   for token in self:iter() do
      buf = buf .. token.content
   end

   return buf
end


-- Decompose a string composed of space-separated tokens into its individual tokens.
-- Supports quoting, and partial tokenization.
--
-- Specifically, the tokenizer accepts two parameters - a string, and a "cutoff point" (e.g. a cursor position).
-- The tokenizer will process the string, assembling a table consisting of tables representing either
-- tokens or non-token spans (e.g. \t, space, etc...)
-- Tokens may be made to contain spaces via quoting ("", '') of the token or escaping spaces.
function Tokenizer.tokenize (str, up_to)
   if up_to and up_to <= #str then
      up_to = up_to
   else
      up_to = #str
   end

   local token = nil

   local result = {
      head        = nil,
      tail        = nil,
      rhs_head    = nil,
      lhs_tail    = nil,
      split_token = nil,
   }

   -- walk string
   for i = 1, #str do
      local c = str:sub(i, i)
      local n = str:sub(i + 1, i + 1)

      local whitespace = is_whitespace(c) and not esc_flag
      local quote = is_quote(c) and not esc_flag
      local esc = is_esc(c) and not esc_flag

      if not token then
         token = Token:new {
            whitespace = (not esc_flag and c == ' '),
            start_pos = i
         }

         if result.tail then
            result.tail.next = token
         end

         result.tail = token

         if not result.head then
            result.head = token
         end
      end

      if i - up_to == 0 then -- we are at the character at the cutoff
         token.cutoff_pos = #token.content + 1 -- relative cursor pos would equal length of content buf + 1
         result.split_token = token
      elseif not result.rhs_head and result.split_token then
         result.rhs_head = token
      elseif not result.rhs_head and not result.split_token then
         result.lhs_tail = token
      end


      if false and esc and token.whitespace then -- if in a whitespace token, stop building the current token
         token.end_pos = i - 1 -- end pos is before this char, since we're examining \
         tail = token
         token = nil
         -- continue
      elseif whitespace and token.whitespace then -- append whitespace
         token.content = token.content .. c

         if not is_whitespace(n) then -- finish whitespace if next char is not whitespace
            token.end_pos = i
            tail = token
            token = nil
         end
         -- continue
      elseif quote and token.quote == '' and not esc_flag then -- effectively will be the first char in the token
         token.quote = c
         -- continue
      elseif c == token.quote and not esc_flag then -- effective end of token (yeah, a little lazy)
         token.end_pos = i
         tail = token
         token = nil
         -- continue
      else
         if not esc then
            token.content = token.content .. c
         end

         if (is_whitespace(n) and token.quote == '' and not esc) or n == '' then
            token.end_pos = i
            tail = token
            token = nil
         end
      end

      esc_flag = esc
   end

   if token then
      tail = token
   end

   return result
end

function Tokenizer.find_at_pos (tokens, pos)
   local count

   for _, token in ipairs(tokens) do
      local end_pos = token.start_pos + #token.content
      if pos > token.start_pos and pos < end_pos then
         return token
      end
   end

   return nil
end

function Tokenizer.singleton(content)
   return Token.singleton(content)
end

return Tokenizer
