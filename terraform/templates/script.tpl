const url = "${invoke_url}";
const socket = new WebSocket(url);

  socket.addEventListener('open', (event) => {
    console.log('WebSocket connection opened.');
  });

  socket.addEventListener('message', (event) => { 
    document.getElementById("show").innerHTML = event.data;
  });

  socket.addEventListener('close', (event) => {
    console.log('WebSocket connection closed.');
  });

  socket.addEventListener('error', (error) => {
    console.error('WebSocket error:', error);
  });