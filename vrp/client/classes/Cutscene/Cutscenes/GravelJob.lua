CutscenePlayer:getSingleton():registerCutscene("GravelJob", {
	name = "Gravel-Job";
	startscene = "Gravel-Job";
	debug = false;

	-- Scene 1
	{
		uid = "Gravel-Job";
		letterbox = true;
		{
			action = "General.fade";
			fadein = false;
			time = 0;
			starttick = 0;
		};
		{
			action = "General.weather";
			time = {9,0};
			farclipdistance = 2000;
			fogdistance = 0;
			clouds = false;
			weather = 0;
			starttick = 0;
		};
		{
			action = "Camera.set";
			starttick = 0;
			pos = {745.26, 806.82, 24.60};
			lookat = {590.39, 869.21, -42.50};
		};
		{
			action = "General.fade";
			fadein = true;
			time = 1000;
			starttick = 1000;
		};
		{
			action = "Camera.move"; -- Move Arround
			pos = {745.26, 806.82, 24.60};
			targetpos = {722.51, 873.49, 5.47};
			lookat = {590.39, 869.21, -42.50};
			targetlookat = {590.39, 869.21, -42.50};
			starttick = 1000;
			duration = 8000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 2000;
			duration = 5000;
			text = "There are various tasks in the gravel pit!";
		};
		{
			action = "Camera.move"; -- Move to Step 1
			targetpos = {695.49, 881.45, -13.58};
			targetlookat = {712.10, 813.01, -30.24};
			starttick = 9000;
			duration = 3000;
		};
		{
			action = "Camera.move"; -- Side Move Step 1
			targetpos = {631.99, 806.61, -1.74};
			targetlookat = {712.10, 813.01, -30.24};
			starttick = 12000;
			duration = 6000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 12000;
			duration = 6000;
			text = "The first step is to remove the light-colored rocks with the pickaxe!";
		};
		{
			action = "Camera.move"; -- Move To Target 1
			targetpos = {688.58, 788.26, 4.93};
			targetlookat = {676.88, 826.91, -28.20};
			starttick = 18000;
			duration = 4000;
		};
		{
			action = "Camera.move"; -- Move To Target 2
			targetpos = {729.60, 864.21, 4.93};
			targetlookat = {688.30, 846.68, -28.21};
			starttick = 22000;
			duration = 4000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 19000;
			duration = 6000;
			text = "The extracted stones have to be pushed into these containers with bulldozers!";
		};
		{
			action = "Camera.move"; -- Move To Band
			targetpos = {659.80, 835.39, -32.08};
			targetlookat = {673.70, 828.60, -38.08};
			starttick = 26000;
			duration = 4000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 26000;
			duration = 10000;
			text = "Stones are automatically transported to the warehouse via the conveyor belts!";
		};
		{
			action = "Camera.move"; -- Move To Stock
			targetpos = {621.81, 865.55, -24.58};
			targetlookat = {621.41, 888.76, -35.50};
			starttick = 30000;
			duration = 6000;
		};
		{
			action = "Camera.move"; -- Move Delivery - Start
			targetpos = {515.23, 889.57, -4.97};
			targetlookat = { 574.89, 930.60, -41.12};
			starttick = 36000;
			duration = 5000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 36000;
			duration = 5000;
			text = "The stones can then be loaded into a dumper here,";
		};
		{
			action = "Camera.move"; -- Move Track
			targetpos = {651.22, 824.00, 35.0};
			targetlookat = {734.20, 921.85, -7.37};
			starttick = 41000;
			duration = 7000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 42000;
			duration = 5000;
			text = "and carefully over the path";
		};
		{
			action = "Camera.move"; -- Move Delivery Point
			targetpos = {868.40, 838.76, 52.25};
			targetlookat = {823.04, 882.65, 13.32};
			starttick = 48000;
			duration = 6000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 48000;
			duration = 6000;
			text = "to be brought to this drop-off point!";
		};
		{
			action = "Camera.move"; -- Move Delivery Point
			targetpos = {735.96, 940.40, 40.78};
			targetlookat = {590.39, 869.21, -42.50};
			starttick = 54000;
			duration = 6000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 54000;
			duration = 8000;
			text = "We hope you have fun with this job!";
		};
		{
			action = "General.fade";
			fadein = false;
			time = 1000;
			starttick = 65000;
		};
		{
			action = "General.finish";
			starttick = 66000;
		};
	};
})
