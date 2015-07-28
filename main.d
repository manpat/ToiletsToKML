module main;

pragma(lib, "kxml");

// https://256.makerslocal.org/wiki/KXML
import kxml.xml;
import std.algorithm;
import std.string;
import std.stdio;
import std.file;
import std.conv;
import std.getopt;

import query;
import data;

struct Options {
	bool showLabels = false;
	ulong maxToiletsOut = 100;
	string query = "";
	string outfile = "toilets.kml";

	void setQuery(string, string v){
		query = cast(string) read(v);
	}
}

Options options;

void main(string[] args){
	try{
		auto optinfo = getopt(
			args,
			"maxtoilets|t", &options.maxToiletsOut,
			"showlabels|l", &options.showLabels,
			"queryfile|f", &options.setQuery,
			"outputfile|o", &options.outfile,
			"query|q", &options.query,
		);

		if(optinfo.helpWanted){
			writeln(args[0], " [-ht] [-o outputFile] [-f queryfile] [-q \"query\"] inputFile");
			writeln("A tool for converting and processing toilet data to kml for viewing in Google Earth");
			writeln();
			writeln("  -t, --maxtoilets", "    Sets the maximum number of toilets to output");
			writeln("  -l, --showlabels", "    Enables the drawing of labels");
			writeln("  -o, --outputfile", "    Specifies a filename for the output");
			writeln("  -f, --queryfile ", "    Specifies a file to read a query from");
			writeln("  -q, --query     ", "    Specifies a query to run");
			writeln("  -h, --help      ", "    Displays this");
			writeln();
			writeln("This tool uses a simple query language for processing toilet data.");
			writeln("There are several commands in the language");
			writeln();
			writeln("  sort [ascending|descending] distto <latitude> <longitude>");
			writeln("    - Sorts data based on distance (km) from a geographical point");
			writeln();
			writeln("  sort [ascending|descending] postcode");
			writeln("    - Sorts data based on postcode");
			writeln();
			writeln("  sort [ascending|descending] <feature>");
			writeln("    - Sorts data based on a feature");
			writeln("    - e.g. `sort descending showers` moves all toilets with showers");
			writeln("      to 'front' of the dataset");
			writeln();
			writeln("  filter [!] postcode <op> <value> [<op> <value> [...]]");
			writeln("    - Filters data based on one or several comparisons of postcodes");
			writeln("    - Using ! negates the result of the comparisons");
			writeln("    - e.g. `filter postcode > 4000 < 5000` returns toilets with postcodes");
			writeln("      between 4000 and 5000");
			writeln();
			writeln("  filter [!] distto <latitude> <longitude> <op> <value> [...]");
			writeln("    - Filters data based on one or several comparisons of distance (km) to");
			writeln("      a geographical point");
			writeln("    - Using ! negates the result of the comparisons");
			writeln("    - e.g. `filter distto -25.1212 123.56 > 10` returns toilets with further");
			writeln("      than 10km from point (-25.1212, 123.56)");
			writeln();
			writeln("  filter [!] <feature>");
			writeln("    - Filters toilets based on whether or not they have a feature/facility");
			writeln("    - Using ! selects toilets that do not have the specified feature/facility");
			writeln("    - e.g. `filter ! ParkingAccessible` returns toilets that do not");
			writeln("      have accessible parking");
			writeln();
			writeln("  limit <count>");
			writeln("    - Reduces the size of the set to be at maximum `count` large");
			writeln("    - e.g. `limit 200` returns the first 200 toilets in the set");
			writeln();
			writeln("  push");
			writeln("    - Pushes the current set onto a stack");
			writeln();
			writeln("  pop");
			writeln("    - Returns set to previously pushed state");
			writeln("    - Discards the results of sorts, filters and limits");
			writeln();
			writeln("  style <style>");
			writeln("    - Sets the style of all data in the set");
			writeln("    - Not affected by push/pop");
			writeln("    - Useful for conditional styling");
			writeln();
			writeln("  print");
			writeln("    - Prints the set as it is in it's current state");
			writeln();
			writeln("<feature/facility> can be one of the following");
			writeln("  Male, Female, AccessibleMale,");
			writeln("  AccessibleFemale, AccessibleUnisex,");
			writeln("  ParkingAccessible, BabyChange,");
			writeln("  Showers, DrinkingWater, SharpsDisposal,");
			writeln("  SanitaryDisposal");
			writeln();
			writeln("<op> can be one of the following");
			writeln("  <, >, <=, >=, ==, !=");
			writeln();
			writeln("<style> can be one of the following");
			writeln("  default (yellow)");
			writeln("  good (green), bad (red)");
			writeln("  red, green, blue");
			writeln("  cyan, magenta, yellow");
			writeln("  white, black");
			writeln();

			return;
		}

		auto toiletString = cast(string) read(args[1]);

		XmlNode[] root = readDocument(toiletString, true).parseXPath("//ToiletDetails");
		ToiletDetail[] dets;
		dets.reserve(root.length);

		foreach(i, ref xn; root){
			dets ~= ParseSingleToiletDetail(xn);
		}

		dets = ProcessToilets(dets, options);

		auto kmlOut = ToiletDetailsToKML(dets);
		std.file.write(options.outfile, kmlOut.toString);

	}catch(Exception e){
		writeln("Error: ", e.msg);
	}
}

T getData(T)(XmlNode node, string path){
	auto xp = node.parseXPath(path);
	assert(xp.length > 0);
	if(xp[0].getCData.length == 0) return T.init;

	return to!T(xp[0].getCData());
}

ToiletDetail ParseSingleToiletDetail(XmlNode root){
	assert(root.getName() == "ToiletDetails");

	ToiletDetail details;
	details.name = root.parseXPath("Name")[0].getCData();
	details.pos.longitude = to!double(root.getAttribute("Longitude"));
	details.pos.latitude  = to!double(root.getAttribute("Latitude"));
	details.postcode  = root.getData!uint("Postcode");

	foreach(f; __traits(allMembers, Features)){
		details.features |= root.getData!bool("Features/"~f) * mixin("Features."~f);
	}

	enum genaccmem = __traits(allMembers, Facility);
	foreach(f; genaccmem[0..2]){
		details.genacc |= root.getData!bool("GeneralDetails/"~f) * mixin("Facility."~f);
	}
	foreach(f; genaccmem[2..$]){
		details.genacc |= root.getData!bool("AccessibilityDetails/"~f) * mixin("Facility."~f);
	}

	return details;	
}

ToiletDetail[] ProcessToilets(ref ToiletDetail[] toilets, Options options){
	import std.range;

	auto nt = ProcessQuery(options.query, toilets);

	auto len = nt.walkLength;
	writeln(len, " toilets processed");
	if(len > options.maxToiletsOut){
		writeln("Capped to ", options.maxToiletsOut);
		len = options.maxToiletsOut;
	}

	toilets = nt.array[0..len];

	foreach(ref t; toilets){
		char[] buff;
		buff ~= "<h1>%s</h1>".format(t.name);
		buff ~= "<table>";
		buff ~= "<tr>";
		buff ~= "<td><b>Postcode</b></td>";
		buff ~= "<td>%s</td>".format(t.postcode);
		buff ~= "</tr>";

		foreach(f; __traits(allMembers, Features)){
			buff ~= "<tr>";
			buff ~= "<td><b>%s</b></td>".format(f);
			buff ~= "<td>%s</td>".format(
				(t.features & mixin("Features."~f))?"Yes":"No");
			buff ~= "</tr>";
		}

		foreach(f; __traits(allMembers, Facility)){
			buff ~= "<tr>";
			buff ~= "<td><b>%s</b></td>".format(f);
			buff ~= "<td>%s</td>".format(
				(t.genacc & mixin("Facility."~f))?"Yes":"No");
			buff ~= "</tr>";
		}

		buff ~= "</table>";

		t.description = buff.idup;
	}

	return toilets;
}

XmlNode ToiletDetailsToKML(R)(R toilets){
	auto root = new XmlNode("kml");
	root.setAttribute("xmlns", "http://www.opengis.net/kml/2.2");

	auto doc = new XmlNode("Document");
	doc.addChild(new XmlNode("name").setCData("Toilets"));

	auto styles = [
		"good": "ff00ff00",
		"bad": "ff0000ff",
		"default": "ff00ffff",

		"red": "ff0000ff",
		"green": "ff00ff00",
		"blue": "ffff0000",

		"cyan": "ffffff00",
		"magenta": "ffff00ff",
		"yellow": "ff00ffff",

		"white": "ffffffff",
		"black": "ff000000",
	];

	auto whitePin = new XmlNode("Icon")
		.addChild(new XmlNode("href")
			.setCData("http://maps.google.com/mapfiles/kml/pushpin/wht-pushpin.png"));

	foreach(style; styles.byKey){
		doc.addChild(
			new XmlNode("Style")
			.setAttribute("id", style)
			.addChild(new XmlNode("IconStyle")
				.addChild(new XmlNode("color")
					.setCData(styles[style]))
				.addChild(whitePin)));
	}
	
	foreach(ref toilet; toilets){
		auto placemark = new XmlNode("Placemark");
		if(options.showLabels) placemark.addChild(new XmlNode("name").setCData(toilet.name));
		placemark.addChild(new XmlNode("description").setCData(toilet.description));
		if(toilet.style.length > 0){
			placemark.addChild(
				new XmlNode("styleUrl").setCData("#"~toilet.style)
			);
		}

		placemark.addChild(
			new XmlNode("Point")
				.addChild(new XmlNode("coordinates")
					.setCData("%2.10f,%2.10f,0".format(toilet.pos.longitude, toilet.pos.latitude))
				)
			);

		doc.addChild(placemark);
	}

	root.addChild(doc);
	return root;
}