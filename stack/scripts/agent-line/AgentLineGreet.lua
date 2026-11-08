-- Once the agent line is listening, say hello, once per call.
local greeted = false
Automation("AgentLineGreet", {
  trigger = Entity("plugin-asterisk.call_agent.transcript"),
  targets = None(),
}, function(ctx)
  local s = ctx.trigger.entity.state
  if s.status ~= "listening" then
    greeted = false
    return
  end
  if greeted or (s.seq or 0) > 0 then return end
  greeted = true
  ctx.send({ key = "plugin-asterisk.call_agent.call" }, "sip_say", { text = "Hi, what can I do?" })
end)
