module query;

import std.algorithm;
import std.string;
import std.stdio;
import std.range;
import std.array;
import std.conv;

import data;

alias TDList = ToiletDetail*[];

auto ProcessQuery(string query, ref ToiletDetail[] data){
	auto ndata = data.map!((ref d) => &d).array;
	toiletStack = [ndata];

	foreach(line; query.toLower.strip.splitLines()){
		auto tokens = line.strip.splitter(" ");
		if(tokens.walkLength == 0) continue;

		auto cmd = tokens.front;
		tokens.popFront();

		if(cmd.front == '#') continue;

		switch(cmd){
			case "sort": Sort(tokens.array, ndata); break;
			case "filter": Filter(tokens.array, ndata); break;
			case "limit": Limit(tokens.array, ndata); break;

			case "push": Push(ndata); break;
			case "pop": Pop(ndata); break;
			case "style": Style(tokens.array, ndata); break;

			case "print": Print(ndata); break;

			default: Error("Unknown token "~cmd);
		}
	}

	return ndata.map!(d => *d).array;
}

protected:

void Assert(bool cond, string e){
	if(!cond) throw new Exception(e);
}
void Error(string e){
	throw new Exception(e);
}

TDList[] toiletStack;

void Push(TDList td){
	toiletStack ~= td.dup; // Bad but whatever
}
void Pop(ref TDList td){
	td = toiletStack.back;
	toiletStack = toiletStack[0..$-1];
}

void Print(ref TDList td){
	foreach(t; td){
		writeln(*t);
	}
}

GeoPos ParseGeoPos(string[] args){
	Assert(args.length >= 2, "GeoPos' require two elements");

	return GeoPos(to!double(args[0]), to!double(args[1]));
}

void ToiletSort(string whatby)(ref TDList data, bool descending = false){
	if(descending){
		data.sort!((a,b){
			return mixin("(a."~whatby~") > (b."~whatby~")");
		});
	}else{
		data.sort!((a,b){
			return mixin("(a."~whatby~") < (b."~whatby~")");
		});
	}
}
void ToiletSort(string whatby, alias A)(ref TDList data, bool descending = false){
	if(descending){
		data.sort!((a,b){
			return mixin("(a."~whatby~"(A)) > (b."~whatby~"(A))");
		});
	}else{
		data.sort!((a,b){
			return mixin("(a."~whatby~"(A)) < (b."~whatby~"(A))");
		});
	}
}

void ToiletFilter(string whatby)(ref TDList data){
	data = data.filter!(t => mixin("("~whatby~")")).array;
}
void ToiletFilter(string whatby, A...)(ref TDList data, A args){
	data = data.filter!(t => mixin("("~whatby~")")).array;
}

void Sort(string[] args, ref TDList data){
	Assert(args.length >= 1, "sort takes at least one argument");

	bool descending = false;

	switch(args[0]){
	case "descending": descending = true; args = args[1..$]; break;
	case "ascending": args = args[1..$]; break;

	default: break;
	}

	string sortby = args.front;
	args = args[1..$];

	if([__traits(allMembers, Features)].map!toLower.canFind(sortby)){
		foreach(f; __traits(allMembers, Features)){
			if(sortby == f.toLower){
				ToiletSort!("features & Features."~f)(data, descending);
				break;
			}
		}

		return;
	}else if([__traits(allMembers, Facility)].map!toLower.canFind(sortby)){
		foreach(f; __traits(allMembers, Facility)){
			if(sortby == f.toLower){
				ToiletSort!("genacc & Facility."~f)(data, descending);
				break;
			}
		}

		return;
	}

	switch(sortby){
		case "postcode":{
			ToiletSort!"postcode"(data, descending);
			break;
		}

		case "distto":{
			auto pos = ParseGeoPos(args);
			ToiletSort!("pos.dist", pos)(data, descending);
			break;
		}

		default: Error("Unknown sort parameter: "~sortby);
	}
}

template Tuple(A...){
	alias Tuple = A;
}

void Filter(string[] args, ref TDList data){
	bool not = false;
	if(args.front == "!") {
		not = true;
		args.popFront();
	}

	string filterwhat = args.front;
	args.popFront();

	alias filterOps = Tuple!("<", ">", "<=", ">=", "==", "!=");

	if([__traits(allMembers, Features)].map!toLower.canFind(filterwhat)){
		foreach(f; __traits(allMembers, Features)){
			if(filterwhat == f.toLower){
				if(not)
					ToiletFilter!("!((t.features & Features."~f~") > 0)")(data);
				else
					ToiletFilter!("((t.features & Features."~f~") > 0)")(data);
				break;
			}
		}

		return;
	}else if([__traits(allMembers, Facility)].map!toLower.canFind(filterwhat)){
		foreach(f; __traits(allMembers, Facility)){
			if(filterwhat == f.toLower){
				if(not)
					ToiletFilter!("!((t.genacc & Facility."~f~") > 0)")(data);
				else
					ToiletFilter!("((t.genacc & Facility."~f~") > 0)")(data);
				break;
			}
		}

		return;
	}

	switch(filterwhat){
		case "postcode":{
			while(args.length >= 2){
				auto op = args.front;
				auto val = to!uint(args[1]);

				foreach(cop; filterOps){
					if(op == cop){
						if(not)
							ToiletFilter!("!(t.postcode "~cop~" args[0])")(data, val);
						else
							ToiletFilter!("t.postcode "~cop~" args[0]")(data, val);
						break;
					}
				}

				args.popFrontN(2);
			}
			break;
		}

		case "distto":{
			auto pos = ParseGeoPos(args);
			args.popFrontN(2);

			while(args.length >= 2){
				auto op = args.front;
				auto val = to!double(args[1]);

				foreach(cop; filterOps){
					if(op == cop){
						if(not)
							ToiletFilter!("!(t.pos.dist(args[0]) "~cop~" args[1])")(data, pos, val);
						else
							ToiletFilter!("t.pos.dist(args[0]) "~cop~" args[1]")(data, pos, val);
						break;
					}
				}

				args.popFrontN(2);
			}

			break;
		}

		default: Error("Unknown filter parameter: "~filterwhat);
	}
	
}

void Limit(string[] args, ref TDList data){
	Assert(args.length == 1, "limit takes one argument");

	auto count = min(to!ulong(args[0]), data.length);
	data = data[0..count];
}

void Style(string[] args, ref TDList data){
	foreach(d; data){
		d.style = args[0];
	}
}