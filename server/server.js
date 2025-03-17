const EXPRESS = require("express");
const HTTPS = require('https');
const fs = require('fs');
const jwt = require("jsonwebtoken");

const PRIVATEKEY = fs.readFileSync("../keys/privateKey.pem", "utf8");
const CERTIFICATE = fs.readFileSync("../keys/certificate.pem", "utf8");
const CREDENTIALS = {"key":PRIVATEKEY, "cert":CERTIFICATE};

const PORT = 8443;
let app = EXPRESS();

// database di utenti
var users = [
    {
        ut:"pinco",
        pwd:"12345",
        mail:"pinco@hotmail.com"
    },
    {
        ut:"tizio",
        pwd:"00000",
        mail:"tizio@yahoo.com"
    }
];

var httpsServer = HTTPS.createServer(CREDENTIALS, app);
httpsServer.listen(PORT,  function() {
    console.log("Il server https in ascolto sulla porta " + PORT);
});

app.get("/login.html", (req, res) => {
    res.sendFile(__dirname + "/login.html");
});

