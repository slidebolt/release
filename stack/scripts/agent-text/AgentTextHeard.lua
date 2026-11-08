-- Every text message to the agent line goes to the text agent. One session per
-- extension, so the agent remembers earlier texts from the same phone.
local lastAt = nil
Automation("AgentTextHeard", {
  trigger = Entity("plugin-asterisk.ext_4000.messages"),
  targets = None(),
}, function(ctx)
  local s = ctx.trigger.entity.state
  if s.text == nil or s.text == "" or s.from == nil or s.at == lastAt then return end
  lastAt = s.at
  local session = "text-" .. s.from
  ctx.decision("texted", { from = s.from, session = session })
  ctx.send(ctx.queryOne("plugin-opencode.agent_text.prompt"), "agent_prompt",
           { text = s.text, session = session })
end)
