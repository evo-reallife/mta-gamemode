-- Scene 1 // Verhalten der Fische
CutscenePlayer:getSingleton():registerCutscene("FishingBehavior", {
	name = "FishingBehavior";
	startscene = "FishingBehavior";
	debug = false;

	{
		uid = "FishingBehavior";
		letterbox = true;
		{
			action = "General.fade";
			fadein = false;
			time = 0;
			starttick = 0;
		};
		{
			action = "General.weather";
			time = {12,0};
			farclipdistance = 2000;
			fogdistance = 0;
			clouds = false;
			weather = 0;
			starttick = 0;
		};
		{
			action = "Camera.set";
			starttick = 0;
			pos = {369.29, -2079.87, 8.75};
			lookat = {369.27, -2078.87, 8.66};
		};
		{
			action = "General.fade";
			fadein = true;
			time = 2000;
			starttick = 50;
		};
		{
			action = "Camera.move";
			pos = {369.29, -2079.87, 8.75};
			targetpos = {423.07, -2114.71, 29.37};
			lookat = {369.27, -2078.87, 8.66};
			targetlookat = {422.54, -2113.94, 29.01};
			starttick = 50;
			duration = 10000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 600;
			duration = 10000;
			text = "Hello dear fishing friend, I am Lutz and I will now explain some fishing basics to you!";
		};
		{
			action = "Camera.move";
			pos = {423.07, -2114.71, 29.37};
			lookat = {422.54, -2113.94, 29.01};
			targetpos = {381.55, -1923.77, 16.78};
			targetlookat = {381.78, -1922.87, 16.4};
			starttick = 11000;
			duration = 9000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 11000;
			duration = 9000;
			text = "Before you can get started, you'll need a fishing rod and somewhere to store your catch.\nYou can get all this in the fishing store, which is near here.";
		};
		{
			action = "Camera.move";
			pos = {381.55, -1923.77, 16.78};
			lookat = {381.78, -1922.87, 16.4};
			targetpos = {349.56, -1880.07, 35.34};
			targetlookat = {350.34, -1880.09, 34.71};
			starttick = 20000;
			duration = 12500;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 20000;
			duration = 12500;
			text = "You will only be able to buy some things once you have gained enough experience.\nA fishing rod and a small cool bag are enough to get you started!";
		};
		{
			action = "General.fade";
			fadein = false;
			time = 2000;
			starttick = 30900;
		};
		{
			action = "General.fade";
			fadein = true;
			time = 2000;
			starttick = 33000;
		};
		{
			action = "Camera.moveCircle";
			pos = {349.56, -1880.07, 65};
			lookat = {349.56, -1880.07, 16};
			distance = 180;
			startangle = -45;
			targetangle = 45;
			starttick = 33000;
			duration = 12000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 33000;
			duration = 3000;
			text = "It does matter where you go fishing!";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 36000;
			duration = 6000;
			text = "A distinction is drawn between\nThe sea (or ocean) ...";
		};
		{
			action = "General.fade";
			fadein = false;
			time = 2000;
			starttick = 43000;
		};
		{
			action = "Camera.move";
			pos = {797.87, -199.15, 18.20};
			lookat = {699.65, -217.85, 16.63};
			targetpos = {417.01, -271.68, 12.11};
			targetlookat = {318.79, -290.38, 10.54};
			starttick = 45000;
			duration = 6000;
		};
		{
			action = "General.fade";
			fadein = true;
			time = 2000;
			starttick = 45000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 46000;
			duration = 4000;
			text = "\n... Rivers ...";
		};
		{
			action = "General.fade";
			fadein = false;
			time = 1000;
			starttick = 50000;
		};
		{
			action = "Camera.move";
			pos = {1785.92, -227.61, 95.31};
			lookat = {1875.96, -202.95, 59.48};
			targetpos = {2101.35, -111.37, 2.69};
			targetlookat = {2146.33, -23.09, -10.87};
			starttick = 51000;
			duration = 15000;
		};
		{
			action = "General.fade";
			fadein = true;
			time = 2000;
			starttick = 51000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 51000;
			duration = 4000;
			text = "\n... and lakes.";
		};

		{
			action = "Graphic.setLetterBoxText";
			starttick = 56000;
			duration = 5000;
			text = "Most fish are independent of the weather.\nHowever, there are fish that can only be caught when it is dry ...";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 61000;
			duration = 8000;
			text = "... or when it rains.";
		};
		{
			action = "General.weather";
			time = {12,0};
			farclipdistance = 2000;
			fogdistance = 0;
			clouds = false;
			weather = 8;
			starttick = 61000;
		};
		{
			action = "General.fade";
			fadein = false;
			time = 2000;
			starttick = 69000;
		};
		{
			action = "General.weather";
			time = {12,0};
			farclipdistance = 2000;
			fogdistance = 0;
			clouds = false;
			weather = 0;
			starttick = 70000;
		};
		{
			action = "General.fade";
			fadein = true;
			time = 2000;
			starttick = 71000;
		};
		{
			action = "Camera.moveCircle";
			pos = {1601.64, -1365.74, 133.46};
			lookat = {1601.64, -1365.74, 133.46};
			distance = 400;
			startangle = 135;
			targetangle = 90;
			starttick = 71000;
			duration = 21000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 71000;
			duration = 5000;
			text = "What? You can't go fishing around the clock?\nThat's it for the professional angler!";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 76000;
			duration = 5000;
			text = "Even fish go to sleep. When? They decide for themselves.\n Some can only be caught during the day ...";
		};
		{
			action = "General.weather";
			time = {0,0};
			farclipdistance = 2000;
			fogdistance = 0;
			clouds = false;
			weather = 0;
			starttick = 81000;
		};
		{
			action = "General.fade";
			fadein = false;
			time = 200;
			starttick = 80800;
		};
		{
			action = "General.fade";
			fadein = true;
			time = 200;
			starttick = 81000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 81000;
			duration = 4000;
			text = "... some only at night ...";
		};
		{
			action = "General.fade";
			fadein = false;
			time = 200;
			starttick = 84800;
		};
		{
			action = "General.fade";
			fadein = true;
			time = 200;
			starttick = 85000;
		};
		{
			action = "General.weather";
			time = {6,0};
			farclipdistance = 2000;
			fogdistance = 0;
			clouds = false;
			weather = 0;
			starttick = 85000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 85000;
			duration = 5000;
			text = "... or very early in the morning!";
		};
		{
			action = "General.fade";
			fadein = false;
			time = 2000;
			starttick = 90000;
		};
		{
			action = "General.finish";
			starttick = 92000;
		};
	};
})

-- Scene 2 // Fangen von Fische
CutscenePlayer:getSingleton():registerCutscene("FishingCatch", {
	name = "FishingCatch";
	startscene = "FishingCatch";
	debug = false;

	{
		uid = "FishingCatch";
		letterbox = true;
		{
			action = "General.fade";
			fadein = false;
			time = 0;
			starttick = 0;
		};
		{
			action = "General.fade";
			fadein = true;
			time = 2000;
			starttick = 50;
		};
		{
			action = "General.weather";
			time = {12,0};
			farclipdistance = 2000;
			fogdistance = 0;
			clouds = false;
			weather = 0;
			starttick = 0;
		};
		{
			action = "Camera.moveCircle";
			pos = {389.9, -2028.44, 40};
			lookat = {389.9, -2028.44, 22};
			distance = 200;
			startangle = 45;
			targetangle = 180;
			starttick = 50;
			duration = 60000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 50;
			duration = 4000;
			text = "Well, the behavior of the fish should now be clear.";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 4050;
			duration = 5950;
			text = "Now you still have to learn how to handle the fishing rod.";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 10000;
			duration = 10000;
			text = "After you have bought a fishing rod, you can equip it in your inventory.\nTo do this, simply press 'i' and click on the fishing rod";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 20000;
			duration = 5000;
			text = "Don't forget the cool bag to store your fish!";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 25000;
			duration = 5000;
			text = "Everything included? Perfect. Now quickly head for the water and cast your line!";
		};
		{
			action = "Graphic.drawImage";
			path = "files/images/CutsceneAssets/tour_power_info.png";
			pos = {0.6, 0.45};
			size = {0.171, 0.185};
			starttick = 31000;
			duration = 8000;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 30000;
			duration = 10000;
			text = "Hold down the left mouse button to cast. You will see an indicator.\nTry to cast the fishing rod as perfectly as possible!";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 40000;
			duration = 5000;
			text = "Once the swimmer lands in the water, it's time to wait ...";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 45000;
			duration = 3500;
			text = "... and wait ...";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 48500;
			duration = 3500;
			text = "... until a fish bites!";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 52000;
			duration = 8000;
			text = "Did you hear something? Or maybe seen something in the water? Perfect!\n Press the left mouse button to retract the fishing rod.";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 60000;
			duration = 5000;
			text = "If you are too slow, the fish will get away.";
		};
		{
			action = "General.fade";
			fadein = false;
			time = 1000;
			starttick = 59000;
		};
		{
			action = "Camera.move";
			pos = {1138.92, -69.45, 33.23};
			lookat = {1042.29, -94.52, 27.4};
			targetpos = {862.45, -141.19, 16.54};
			targetlookat = {765.82, -166.27, 10.71};
			starttick = 60000;
			duration = 60000;
		};
		{
			action = "General.fade";
			fadein = true;
			time = 1000;
			starttick = 60000;
		};
		{
			action = "Graphic.drawImage";
			path = "files/images/CutsceneAssets/tour_bobberbar_info.png";
			pos = {0.7, 0.2};
			size = {0.17, 0.62};
			starttick = 65000;
			duration = 17500;
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 65000;
			duration = 10000;
			text = "Here, too, each fish shows its own behavior.\nBalance the green bar at the height of the fish as shown in the picture.";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 75000;
			duration = 7500;
			text = "To balance, click several times and quickly with the left mouse button.\nIf the right bar is completely filled, you have caught the fish!";
		};
		{
			action = "Graphic.setLetterBoxText";
			starttick = 82500;
			duration = 6500;
			text = "Your experience increases with every catch.\n Your fishing level and progress is visible under F2 -> Points.";
		};
		{
			action = "General.fade";
			fadein = false;
			time = 2000;
			starttick = 88000;
		};
		{
			action = "General.finish";
			starttick = 91000;
		};
	};
})


-- Scene 3 // Handeln mit Fischen
--{
--	uid = "FishingTrading";
--	letterbox = true;
--};
