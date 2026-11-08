-- Every new utterance on the agent line goes to the phone agent. One session per
-- call, so the agent remembers earlier requests in the same call.
local last, session = 0, nil
Automation("AgentLineHeard", {
  trigger = Entity("plugin-asterisk.call_agent.transcript"),
  targets = None(),
}, function(ctx)
  local s = ctx.trigger.entity.state
  if s.status ~= "listening" then
    last, session = 0, nil
    return
  end
  if s.text == nil or s.text == "" or (s.seq or 0) <= last then return end
  last = s.seq
  session = session or ("phone-" .. os.time())
  ctx.decision("heard", { text = s.text, session = session })
  ctx.send({ key = "plugin-asterisk.call_agent.call" }, "sip_say", { text = "One moment." })
  ctx.send(ctx.queryOne("plugin-opencode.agent_phone.prompt"), "agent_prompt",
           { text = s.text, session = session })
end)
