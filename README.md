## What is the ideal outcome for this project?
This Project should produce an iOS App that can be used to increase an individual's productivity. To this end, it will be able to record various 'Activity' entities and a user can configure these activities to be repeated a certain number of times within a time frame. Example, a task could be 'long distance run' and a person can set this to be completed once every week. 
Within the task, it has the capability to capture a timed sequence (eg: brisk walk for 10 mins- jog for 5 mins- run for 30 mins - jog for 5 mins - run for another 30 mins -jog for 5 mins - brisk walk for 10 mins etc..) Once completed, the user can also later on see their level of compliance with the planned schedule. The best way to present this info is TBD.
This data will be saved to a User's profile and is synced with an online backup. Even if the person uninstalls app, deletes data from phone, then reinstalls the app, once they log back into their account, they will be able to access their historical data.

In broad strokes, this App may have some similarities with the 'Productive' App. Note that here the objective is not really to get a lot of users or income from this project- the primary objective is 'learning by doing'.<img width="1480" height="438" alt="image" src="https://github.com/user-attachments/assets/bba3e1eb-6aba-4d76-8380-07c01536386e" />


## What are the Priorities for the project?

| Feature Serial Number | Priority | Feature Name | Feature Description |
|----------------------|----------|--------------|-------------------|
| F1 | P0 | Ability to create 'Activity' items | A user must be able to create an 'Activity'. They must be able to plan execution of that Activity as a one-off or at a desired frequency (eg: Once a day or once a week) |
| F2 | P0 | Timed sequence with audio cues to alert transitions between timed segments. | An Activity will have a timed sequence feature/attribute.<br><br>When executing the timed sequence, there will be a large countdown that displays the hours/mins/seconds till the end of the current session and the whole sequence (smaller).<br><br>The timer should give ample audible and visual notifications so that the user can recognize that a specific segment is ending and another is starting. These can also be read out so that the user does not have to look at the phone screen. |
| F3 | P1 | Extend timer by 15 seconds | The user should be able to hit a button that can increase or decrease the time allocation for a session by 15 seconds |
| F4 | P2 | Enable all interactions on Apple Watch as well | Some of these actions (eg: extending timer or marking something as done) are one-time actions and should not require the user to pickup a phone to do these. Easier to be able to do it on the App. |
| F5 | P2 | Ability to record notes (Diary) | Users should be able to record notes for each day. The application of this could be like a daily diary or like a set of things to do or just notes that come to mind. |
| F6 | P3 | Tasks within an Activity segment | Within an Activity, there are timed segments. Within each timed segments, there will be capability to record two pieces of information - name and count.<br>The name could be a free text field or a standardized (enum) value.<br>The could be integral or non-negative rational numbers. |
| F6 | P1 | User needs to create a profile | User will need to provide an email ID, name, etc. Optionally, weight, height etc.. |
| F7 | P1 | User data syncs with cloud | User data will also be backed up separate from their device so that it can easily be retrieved on a different device/fresh install by simply logging into the user's account |


## Success Criterion:
	1. The App should be installable and uninstallable without any issues
	2. The App should be able to create new 'task' and create a way to schedule a task within a time frame (day or week)
	3. The App should be able to display that certain tasks are completed whereas others are not yet completed. 
	4. Tasks should have timed segments. These should work as expected.

## Topics not touched upon:
	- Aesthetics of the app
	- UX of the App
	- May have to revamp the terminology here 'task' to something else. In my mind, it is like a class definition and instantiation of the class (as in OOP)


 ## Current status of the project (2025-07-13)
I worked on this project to try and gain experience in building Apps in Apple ecosystem. Getting the App to run on my devices. As on 2025-07-13, I am able to install the 


	- A few weeks back, I discovered that there are plenty of Apps that give workout+recovery timers
	  - Today, I also realized that Apple's very own 'Workout' app on the watch allows creation of custom workouts that meet my requirements elegantly
	- So, the only value addition from my app will be for non-workout applications. But this was a secondary purpose even in my mind.
	- This means I am unlikely to use my own app if it is available via Apple Store. 
	- Moreover, to just make the app available on Apple store, I have to pay $99 per year. Apple Developer Program membership.
	- Also, considering I am able to get the App installed on my iphone and Apple Watch - I think I have learned **most** of what I expected to learn from this exercise. This is:
		○ Create an iPhone App (+Watch App companion). Since AI could do it WAAAAY faster that I could do it on my own, I chose to use Claude+CLINE setup to get this done. 
		○ Sure, the app still has plenty of issues still. But for me to iron these out, it will take me a lot of time - I will have to dig into the code and straighten out things on my own. Claude has not been able to clear this up despite multiple tries on my part. 
			§ Maybe asking Claude to create a whole new app - this time iPhone+Watch App right from the start - may get things working just fine. But I have lost the excitement and motivation for this project due to the above cited reasons and some other reasons (want to ensure I am using my time on the highest value yielding projects/tasks).

All to say that I have lost the excitement that I ought to experience from doing this project. Moreover, I have mostly obtained the exposure I hoped to gain from it - 
	- Figured out how to set up an App (even though Claude did almost all the work)
	- Got the App to work on Phone+Watch (albeit with glitches)

And I feel I should use my time on other high yield stuff.

