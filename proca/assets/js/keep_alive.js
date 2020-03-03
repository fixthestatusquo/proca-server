
function keepAlive() {
  fetch('/keep-alive')
    .then(wait(60 * 1000 /*ms*/))
    .then(keepAlive)
}

function wait(ms) {
  return () => new Promise(resolve => {
    setTimeout(resolve, ms)
  })
}


export default keepAlive
