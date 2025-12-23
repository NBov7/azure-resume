window.addEventListener('DOMContentLoaded', () => {
    getVisitCount();
});

const functionApiUrl = '/api/GetResumeCounter';

const getVisitCount = () => {
    let count = 0;

    fetch(functionApiUrl)
        .then(response => response.json())
        .then(response => {
            console.log("Website called function API.");
            count = response.count;
            document.getElementById("counter").innerText = count;
        })
        .catch(error => {
            console.error("Error fetching visit count:", error);
        });

    return count;
};
