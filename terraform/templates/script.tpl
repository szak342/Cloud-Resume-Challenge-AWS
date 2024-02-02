function getData() {
    fetch("${invoke_url}/dev")
    .then(res => res.json())
    .then(data => document.getElementById("show").innerHTML = data.message)
    .catch(error => console.log("Error: ", error))
};

getData()