function index()
   entry({"admin", "commotion", "main_page"}, template("commotion/main_page"))
   entry({"admin", "commotion", "main_page"}, template("commotion/everything_broken"))
   entry({"admin", "commotion", "submit_clicked"}, call("start_upload"))
end

function start_upload()
   local http = require "luci.http"
   download_location = "/tmp/"
   default_name = "tmp_image.jpg"
   setFileHandler(download_location, "image", default_name)
   if check_file = some_file_checking_function(download_location..default_name) then
	  http.redirect("https://"..env.SERVER_NAME.."commotion/main_page")
   else
	  http.redirect("https://"..env.SERVER_NAME.."commotion/everything_broken")
   end
end