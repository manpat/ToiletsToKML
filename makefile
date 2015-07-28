

build: *.d
	dmd $^ -ofbuild

run: build
	./build -f "query" -t 1000 "toilets.xml" | tee output
	@# ./build -f "query" -t 100 "singletoilet.xml" | tee output