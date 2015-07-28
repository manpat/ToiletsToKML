module data;

import std.math;

enum Facility {
	Male 				= 1 << 0,
	Female 				= 1 << 1,
	AccessibleMale 		= 1 << 2,
	AccessibleFemale 	= 1 << 3,
	AccessibleUnisex 	= 1 << 4,
	ParkingAccessible 	= 1 << 5,
}

enum Features {
	BabyChange 			= 1 << 0,
	Showers 			= 1 << 1,
	DrinkingWater 		= 1 << 2,
	SharpsDisposal 		= 1 << 3,
	SanitaryDisposal 	= 1 << 4,
}

struct GeoPos {
	double latitude, longitude;

	// in km
	double dist(GeoPos o){
		import std.math;

		auto latMid = (latitude+o.latitude)/2.0;

		auto m_per_deg_lat = 111132.954 - 559.822 * cos(2.0 * latMid) + 1.175 * cos(4.0 * latMid);
		auto m_per_deg_lon = (3.14159265359/180) * 6367449 * cos (latMid);

		double deltaLat = fabs(latitude - o.latitude);
		double deltaLon = fabs(longitude - o.longitude);

		return sqrt(pow(deltaLat * m_per_deg_lat, 2) + pow(deltaLon * m_per_deg_lon, 2))/1000.0;
	}
}

struct ToiletDetail{
	string name;
	uint postcode;
	GeoPos pos;

	Facility genacc;
	Features features;

	string description;
	string style;
}