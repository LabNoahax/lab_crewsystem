
// Armories 
var currentCode = "";
var warehouseCode = "";
var audioPlayer = null;
var data = null;
var active = false;

$(document).ready(function(){  

	if (audioPlayer != null) {
		audioPlayer.pause();
	}

	audioPlayer = new Howl({src: ["numField.mp3"]});
	audioPlayer.volume(50.0);
	
	$("#key1").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "1";
	}); 
	$("#key2").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "2";
	}); 
	$("#key3").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "3";
	}); 
	$("#key4").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "4";
	}); 
	$("#key5").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "5";
	}); 
	$("#key6").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "6";
	}); 
	$("#key7").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "7";
	}); 
	$("#key8").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "8";
	}); 
	$("#key9").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "9";
	}); 
	$("#key0").click(function(){
		audioPlayer.play();
		currentCode = currentCode + "0";
	}); 

    	$("#keyCancel").click(function(){
		audioPlayer.play();
		active = false;
		warehouseCode = "";
		$('body').css('display', "none");
		fetch(`https://lab_crewsystem/escape`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json; charset=UTF-8',
			},
			body: JSON.stringify({})
        	});
    	}); 

	$("#keyClear").click(function(){
		audioPlayer.play();
		currentCode = "";
	});

	$("#keyEnter").click(function(){
		audioPlayer.play();
		fetch(`https://lab_crewsystem/try`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json; charset=UTF-8',
			},
			body: JSON.stringify({
				code: currentCode,
				warehouseCode: warehouseCode
			})
		});
		active = false;
		currentCode = "";
		warehouseCode = "";
		fetch(`https://lab_crewsystem/escape`, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json; charset=UTF-8',
			},
			body: JSON.stringify({})
		});
		$('body').css('display', "none"); 
	});

	window.addEventListener('message', function(event) {
		data = event.data;
		currentCode = "";
		warehouseCode = data.action;
		
		if (event.data.type == "enableui") {
			$('body').css('display', event.data.enable ? "block" : "none")
		}
		
		if (event.data.enable) {
			active = true;
		}
	});

	$(document).on("keypress", function (e) {
		if (active && e.which >= 48 && e.which <= 57){
			currentCode = currentCode + String(e.which-48);
			audioPlayer.play();
		}
		if (active && e.which == 13){
			audioPlayer.play();
			fetch(`https://lab_crewsystem/try`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json; charset=UTF-8',
				},
				body: JSON.stringify({
					code: currentCode,
					warehouseCode: warehouseCode
				})
			});
			active = false;
			currentCode = "";
			warehouseCode = "";
			fetch(`https://lab_crewsystem/escape`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json; charset=UTF-8',
				},
				body: JSON.stringify({})
			});
			$('body').css('display', "none");
		}
        
    	});
});
// End