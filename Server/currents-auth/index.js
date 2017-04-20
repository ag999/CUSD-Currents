// Requires
var express = require("express");
var stormpath = require("express-stormpath");

// Create the actual app and set port number
var app = express();
app.set('port', process.env.PORT || 5000);

// Stormpath stuff
app.use(stormpath.init(app, {
  expand: {
    customData: true,
  },
  web: {
    produces: ['application/json']
  }
}));

// Endpoints
app.get('/test', function(req, res) {
  res.json({test: "Test success!"});
});

app.get('/notes', stormpath.apiAuthenticationRequired, function(req, res) {
  res.json({notes: req.user.customData.notes || "This is your notebook. Edit this to start saving your notes!"});
});


// This sets the listen port to be the port defined above
app.listen(app.get('port'), function() {
  console.log('Node app is running on port', app.get('port'));
});