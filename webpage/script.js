function getData() {
    fetch("https://52o0iqefzh.execute-api.eu-west-1.amazonaws.com/Dev/dev")
    .then(res => res.json())
    .then(data => document.getElementById("show").innerHTML = data.body.message)
    .catch(error => console.log("Error: ", error))
};

getData()