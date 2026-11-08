-- The phone agent's answer is spoken on the agent line.
local last = 0
Automation("AgentLineReply", {
  trigger = Entity("plugin-opencode.agent_phone.prompt"),
  targets = None(),
}, function(ctx)
  local s = ctx.trigger.entity.state
  if s.status == "thinking" or (s.seq or 0) <= last then return end
  if s.session == nil or string.sub(s.session, 1, 6) ~= "phone-" then return end
  last = s.seq
  local text = s.result
  if s.status == "error" or text == nil or text == "" then
    text = "Sorry, that didn't work."
  end
  if #text > 590 then text = string.sub(text, 1, 590) end
  ctx.send({ key = "plugin-asterisk.call_agent.call" }, "sip_say", { text = text })
end)
