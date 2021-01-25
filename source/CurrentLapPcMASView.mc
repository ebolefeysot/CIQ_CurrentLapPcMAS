using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class CurrentLapPcMASView extends Ui.SimpleDataField {

  enum {
        STOPPED,
        PAUSED,
        RUNNING
    }

    var mas = Application.getApp().getProperty("mas");
    var showDecimal = Application.getApp().getProperty("showDecimal");
    var showPercentChar = Application.getApp().getProperty("showPercentChar");

    hidden var lapMas = 0.0; //current lap average speed in % MAS
    hidden var startTime = 0.0; //elapsed time during the 3 second delay
    hidden var startDist = 0.0; //elapsed distance during the 3 second delay
	hidden var newLap = false;
	hidden var newLapTime = 0.0;
	hidden var timerState = STOPPED;
	hidden var fixedLapTimeOffset;
	hidden var lapTimeOffset = 3.0; //3s
	hidden var fieldLabel = Ui.loadResource(Rez.Strings.FieldName);

    //! constructor
    function initialize() {
    
    	//calculate the time delay in ms before starting calculating average speed
    	fixedLapTimeOffset = lapTimeOffset * 1000 - 500; //precision is delay + 0-1s, I cut in two by removing 500 ms
    	if (fixedLapTimeOffset < 0){
    		fixedLapTimeOffset = 0.0;
    	}
    	
        SimpleDataField.initialize();
        setLabel();
   		lapMas = formatResult(lapMas); // remove decimals
    }

    function formatResult(value){
        var result = value;
 
        //if value is a speed value, format it
        if (result == 0){
        	result = "...";
        }
        else
        {
		    var format = "%.0f";
		    if (showDecimal){
		    	format = "%.1f";
		    }
            //Sys.println("format: " + format);
            result = value.format(format);
        }
        
        if (showPercentChar){
            result += "%";
        }
        return result;
    }
    
    function setLabel(){
        //label displayed in top of the field
        label = fieldLabel + " " + mas.format("%.01f");        
    }

    //! settings have changed.
    function onSettingsChanged(){
        mas = Application.getApp().getProperty("mas");
        setLabel();
    }

	// occurs when pressing lap button
   	function onTimerLap() {
        ResetData();
	   	//Sys.println("Timer lap");
	   	newLap = true; //Start a new calculation after the delay 
    }
    
    //! The timer was started, so set the state to running.
	function onTimerStart()
	{
		timerState = RUNNING;
 	    //Sys.println("Timer start");
 	    newLap = true;
	}
	
	/// a workout step is finished, same as pressing lap
	function onWorkoutStepComplete()
	{
 	    //Sys.println("Workout step completed");
 	    onTimerLap();
	}
	
	//! The timer was stopped, so set the state to stopped.
	function onTimerStop()
	{
		timerState = STOPPED;
      	ResetData();
 	    //Sys.println("Timer stopped");
	}
	
	//! The timer was started, so set the state to running.
	function onTimerPause()
	{
		timerState = PAUSED;
 	    //Sys.println("Timer oaused");
	}
	
	//! The timer was stopped, so set the state to stopped.
	// Don't reset calculations
	function onTimerResume()
	{
		timerState = RUNNING;
 	    //Sys.println("Timer Resume");
	}
	
	//! The timer was reeset, so reset all our tracking variables
	function onTimerReset()
	{
		timerState = STOPPED;
 	    //Sys.println("Timer Reset");
	}

   function ResetData() {
       	lapMas=0.0;
        startTime=0.0;
        startDist=0.0;
   }		

    //! Return the field to display.
    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    // called every second    function compute(info) {
   function compute(info) {		
   
 		if (timerState == STOPPED)
 		{
        	return formatResult(0);
		}

		if (timerState == PAUSED)
		{
        	return lapMas;
		}
 	
 		// start a new calculation ?
 		if (newLap){
 			newLap = false;
 			newLapTime = info.elapsedTime; //save start time to calculate the delay
	 	    //Sys.println("Timer lap event at " + newLapTime);
 		}

        if (info == null || info.currentSpeed == null){
        	return formatResult(0);
        }

    	//wait for the delay
        if ((info.elapsedTime - newLapTime) < fixedLapTimeOffset){
        	//display previous lap speed while waiting
        	return formatResult(0);
        }

        //we calculate now
        if (startTime == 0){
            //3s delay ended, we start to calculate. Save the elapsed time and distance.
            startTime = info.elapsedTime;
            startDist = info.elapsedDistance;
	 	    //Sys.println("Start calculation : time = " + startTime + ", dist = " + startDist);
        	return formatResult(0);
        }
	
    	//calculate average speed, but display previous lap speed
		try {
				var fixedDistKm = (info.elapsedDistance - startDist) / 1000.0; //dist in m
				var fixedTimeH = (info.elapsedTime - startTime) / 1000.0 / 3600.0; //time is in ms
                var averageSpeedKmh = fixedDistKm / fixedTimeH;
		        lapMas = averageSpeedKmh / mas * 100.0;
		        lapMas = formatResult(lapMas);
		        //Sys.println("Time: " + info.elapsedTime + " dist: " + info.elapsedDistance + "  speed: " + info.currentSpeed + "fixed dist km: " + fixedDistKm + " fixed time h: " + fixedTimeH + " calcAvgSpeed: " + averageSpeedKmh+ " %mas: " + lapMas  + " ( " + lapMas + "%" + ")");
		        
		        return lapMas;
		 }
		catch( ex ) {
		    return "Err";
		 }
   }
}