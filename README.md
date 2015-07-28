Toilets To KML
==============

A command line tool for processing australian public toilet data (available at https://data.gov.au/dataset/national-public-toilet-map) and converting it into kml for viewing in Google Earth

Invocation
----------
build [-ht] [-o outputFile] [-f queryfile] [-q "query"] inputFile

   Flags                  | Description
  ------------------------|---------------------------------------------
  -t, --maxtoilets <num>  | Sets the maximum number of toilets to output
  -l, --showlabels        | Enables the drawing of labels
  -o, --outputfile <file> | Specifies a filename for the output
  -f, --queryfile <file>  | Specifies a file to read a query from
  -q, --query <query>     | Specifies a query to run
  -h, --help              | Displays help

Queries
-------

This tool uses a simple query language for processing toilet data.
There are several commands in the language

```
  sort [ascending|descending] distto <latitude> <longitude> 
    - Sorts data based on distance (km) from a geographical point

  sort [ascending|descending] postcode
    - Sorts data based on postcode

  sort [ascending|descending] <feature>
    - Sorts data based on a feature
    - e.g. `sort descending showers` moves all toilets with showers
      to 'front' of the dataset

  filter [!] postcode <op> <value> [<op> <value> [...]]
    - Filters data based on one or several comparisons of postcodes
    - Using ! negates the result of the comparisons
    - e.g. `filter postcode > 4000 < 5000` returns toilets with postcodes
      between 4000 and 5000

  filter [!] distto <latitude> <longitude> <op> <value> [...]
    - Filters data based on one or several comparisons of distance (km) to
      a geographical point
    - Using ! negates the result of the comparisons
    - e.g. `filter distto -25.1212 123.56 > 10` returns toilets with further
      than 10km from point (-25.1212, 123.56)

  filter [!] <feature>
    - Filters toilets based on whether or not they have a feature/facility
    - Using ! selects toilets that do not have the specified feature/facility
    - e.g. `filter ! ParkingAccessible` returns toilets that do not
      have accessible parking

  limit <count>
    - Reduces the size of the set to be at maximum `count` large
    - e.g. `limit 200` returns the first 200 toilets in the set

  push
    - Pushes the current set onto a stack

  pop
    - Returns set to previously pushed state
    - Discards the results of sorts, filters and limits

  style <style>
    - Sets the style of all data in the set
    - Not affected by push/pop
    - Useful for conditional styling

  print
    - Prints the set as it is in it's current state
```

`<feature/facility>` can be one of the following: 
  `Male, Female, AccessibleMale,
  AccessibleFemale, AccessibleUnisex,
  ParkingAccessible, BabyChange,
  Showers, DrinkingWater, SharpsDisposal,
  SanitaryDisposal`

`<op>` can be one of the following: 
  `<, >, <=, >=, ==, !=`

`<style>` can be one of the following
  `default (yellow),
  good (green), bad (red),
  red, green, blue,
  cyan, magenta, yellow,
  white, black`
