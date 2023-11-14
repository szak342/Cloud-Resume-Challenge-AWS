function getData() {
    fetch("https://mhfmljn6v6.execute-api.eu-west-1.amazonaws.com/dev/data")
    .then(res => res.json())
    .then(data => document.getElementById("show").innerHTML = data.body.message)
    .catch(error => console.log("Error: ", error))
};

getData()