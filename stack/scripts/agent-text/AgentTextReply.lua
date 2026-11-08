-- The text agent's answer goes back, as a text, to the extension it came from. The
-- session names that extension.
local last = nil
Automation("AgentTextReply", {
  trigger = Entity("plugin-opencode.agent_text.prompt"),
  targets = None(),
}, function(ctx)
  local s = ctx.trigger.entity.state
  if s.status == "thinking" or s.seq == nil or s.seq == last then return end
  local to = s.session and string.match(s.session, "^text%-(%d+)$")
  if to == nil then return end
  last = s.seq
  local text = s.result
  if s.status == "error" or s.error ~= nil and s.error ~= "" or text == nil or text == "" then
    text = "Sorry, that didn't work."
  end
  if #text > 990 then text = string.sub(text, 1, 990) end
  ctx.send({ key = "plugin-asterisk.ext_4000.messages" }, "sip_message_send", { to = to, text = text })
end)
