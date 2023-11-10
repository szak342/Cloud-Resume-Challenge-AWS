function getData() {
    fetch("https://8liiuguz8b.execute-api.eu-west-1.amazonaws.com/dev/data")
    .then(res => res.json())
    .then(data => document.getElementById("show").innerHTML = data.body)
    .catch(error => console.log("Error: ", error))
};

getData()