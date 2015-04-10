pages = {
	{ index="BusAdmin", href="busadmin.htm", title="Bus Admin API" },
}
refs = {
	{ index="Tecgraf", href="http://www.tecgraf.puc-rio.br/", title="Tecgraf" },
	{ index="PUC-Rio", href="http://www.puc-rio.br/" , title="PUC-Rio" },
}
template = [===================================================================[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<title>OpenBus</title>
	<style type="text/css" media="all"><!--
		@import "<%=href("gray.css")%>";
		@import "<%=href("layout1.css")%>";
	--></style>
</head>

<body>

<div class="content">
<% if item.title then return "<h1>"..item.title.."</h1>" end %>
<%
	local contents = contents()
	if contents then
		return contents:gsub("<pre>(.-)</pre>", function(code)
			return "<pre>"..code:gsub("\t", "  ").."</pre>"
		end)
	end
%>
</div>

<div class="content">
<p><small><strong>Copyright (C) 2004-2014 Tecgraf, PUC-Rio</strong></small></p>
<small>This project is currently being maintained by <%=link("Tecgraf")%> at <%=link("PUC-Rio")%>.</small>
</div>

</body>

</html>    ]===================================================================]
