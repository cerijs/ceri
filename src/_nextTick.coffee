if MessageChannel?
  channel = new MessageChannel()
  tasks = {}
  id = 0
  addTask = (cb) -> tasks[++id] = cb; return id
  callTask = (i) -> tasks[i](); delete tasks[i]
  channel.port1.onmessage = ({data}) -> callTask(data)
  module.exports = (cb) -> channel.port2.postMessage(addTask(cb.bind(@)))
else
  module.exports = (cb) -> setTimeout cb.bind(@), 0