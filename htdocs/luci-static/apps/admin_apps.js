function JudgeApp(app,approved) {
        var action, ajax = new XHR();
	if (approved == 1) {
		action = "approved";
	} else if (approved == 0) {
		action = "banned";
	} else {
		action == "delete"
	} // FIXME! can be made more efficient a ? b : c
        ajax.post(
        	window.location.pathname + '/judge',
        	{
			uuid:app,
			approved:approved
		},
        	function(resp){
        		console.log(resp.status);
        		if (resp.status !== 200) {
        			console.log('error!');
        		} else if (approved != "delete") {
        			var elems = document.getElementsByTagName('*');
                                for (var i in elems) {
                                        if((' ' + elems[i].className + ' ').indexOf(' ' + app + ' ') > -1) {
                                                $(elems[i]).appendTo("#"+action+"Apps")

                                        }
                                }
        		}
				else{
					var elems = document.getElementsByTagName('*');
                    for (var i in elems) {
                        if((' ' + elems[i].className + ' ').indexOf(' ' + app + ' ') > -1) {
                            $(elems[i].remove())
                        }
                    }
				}
        	}
        );
	return false;
}
