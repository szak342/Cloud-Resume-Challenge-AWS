function getData() {
    fetch("https://0abx8w4o9g.execute-api.eu-west-1.amazonaws.com/prod/dev")
    .then(res => res.json())
    .then(data => document.getElementById("show").innerHTML = data.body.message)
    .catch(error => console.log("Error: ", error))
};

getData()