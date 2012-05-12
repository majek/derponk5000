$(function(){
    var canvas = document.getElementById('canvas');
    var ctx = canvas.getContext('2d');
    var c_width = 55.0;
    var ppm = canvas.width/c_width;
    var c_height = canvas.height/ppm;
    ctx.setTransform(ppm, 0, 0, -ppm, 0, canvas.height);


});


function Game(){
    this.paddle1 = {x:1, y:1, width:1, height:10};
    this.paddle2 = {x:4, y:1, width:1, height:10};

    this.top = {x:0, y:0, width:10, height:1};
    this.bottom = {x:12, y:0, width:10, height:1};

    this.matrix = {};
};

Game.prototype = {
    init: function() {
        this.
    },
};