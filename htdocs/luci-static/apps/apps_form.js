window.onload=function() {
	toggleAdvanced();
	document.getElementById("apps_advanced").onclick=toggleAdvanced;
}
function toggleAdvanced() {
	if (document.getElementById("advanced_options").style.display == "none") {
		document.getElementById("advanced_options").style.display = "block";
	} else {
		document.getElementById("advanced_options").style.display = "none";
	}
}