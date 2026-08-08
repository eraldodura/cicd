const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
    res.send("Hello from my DevOps application!");
});

app.get("/health", (req, res) => {
    res.status(200).json({
        status: "OK",
        message: "Application is healthy"
    });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});