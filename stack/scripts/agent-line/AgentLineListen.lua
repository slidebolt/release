-- When someone calls the agent line, start listening. Safe to repeat.
Automation("AgentLineListen", {
  trigger = Entity("plugin-asterisk.call_agent.call"),
  targets = None(),
}, function(ctx)
  if ctx.trigger.entity.state.status == "active" then
    ctx.send({ key = "plugin-asterisk.call_agent.call" }, "sip_transcribe_start", {})
  end
end)
