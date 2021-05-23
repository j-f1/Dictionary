document.addEventListener("DOMContentLoaded", () => {
  if (window.queue) window.queue.forEach(f => f())
  window.queue = null
})
