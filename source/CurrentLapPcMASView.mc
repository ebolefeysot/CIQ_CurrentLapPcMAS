using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class CurrentLapPcMASView extends Ui.SimpleDataField {

  enum {
        STOPPED,
        PAUSED,
        RUNNING
    }

    var mas = Application.getApp().getProperty("mas");

    hidden var mMas = 0;
    hidden var lapMas = 0;
    hidden var nbData = 0;
    hidden var sumMas = 0;
	hidden var newLap = false;
	hidden var newLapTime = 0;
	hidden var timerState = STOPPED;
	hidden var fixedLapTimeOffset;
	hidden var lapTimeOffset = 3; //3s
	hidden var fieldLabel = Ui.loadResource(Rez.Strings.FieldName);

    //! constructor
    function initialize() {
    
    	//calculate the time delay in ms before starting calculating average speed
    	fixedLapTimeOffset = lapTimeOffset * 1000 - 500; //precision is delay + 0-1s, I cut in two by removing 500 ms
    	if (fixedLapTimeOffset < 0){
    		fixedLapTimeOffset = 0;
    	}
    	
        SimpleDataField.initialize();
        setLabel();
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
       	lapMas=0;
    	nbData = 0;
    	sumMas = 0;
    	mMas = 0;
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
        	return 0 + "%";
		}

		if (timerState == PAUSED)
		{
        	return mMas.format("%d") + "%";
		}
 	
 		// start a new calculation ?
 		if (newLap){
 			newLap = false;
 			newLapTime = info.elapsedTime; //save start time
	 	    //Sys.println("Timer lap event at " + newLapTime);
 		}

    	//wait for the delay
        if (info == null || info.currentSpeed == null || (info.elapsedTime - newLapTime) < fixedLapTimeOffset){
        	mMas = 0;
        	return mMas.format("%d") + "%";
        }
	
    	//calculate average speed
		try {
	        	var speedkmh = info.currentSpeed*3.6;
	        	mMas = speedkmh / mas * 100;
		        sumMas += mMas;
		        nbData++;

		        lapMas = sumMas/nbData;
			    //Sys.println("Time: " + info.elapsedTime + "  speed: " + info.currentSpeed + "  %mas: " + mMas + "  nbData: " + nbData);
		        return lapMas.format("%d") + "%";
		 }
		catch( ex ) {
		    return "Err";
		 }
   }
}