function getData() {
    fetch("https://ji74h9h238.execute-api.eu-west-1.amazonaws.com/prod/dev")
    .then(res => res.json())
    .then(data => document.getElementById("show").innerHTML = data.message)
    .catch(error => console.log("Error: ", error))
};

getData()