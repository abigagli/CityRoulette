##CityRoulette
#Capstone project for Udacity iOS Nanodegree

This iOS Application is intended to allow the user to collect some basic information (e.g. the position, population and wikipedia info when available, current weather conditions) of cities around the world.

Using the http://geonames.org API, the application can obtain the coordinates, the name, population and specific wikipedia links of many cities around the world.

Leveraging CoreData, this information can be imported in a local persistent storage and reorganized by marking cities as favorites, while at the same time looking at the position on a map and accessing the relative wikipedia article, when available, through a dedicated webview that allows full browsing.

Finally, using the http://openweather.org API, the current weather condition is looked up for each city and a corresponding icon representing the weather status is shown.

The interface consists of:

* A main welcome screen that smoothly takes over the launch screen and gradually fades into a B&W image of the city of *Florence*, Italy (my city) where some buttons are added with an animation.

* A combined Map/Table view that is used for both adding new cities and browsing the archived ones

* A webview that allows navigation starting from the wikipedia link associated to a particular city

A more detailed description of the various scenes follows:

1. The initial scene presents 2 buttons for adding new cities and 1 button (**which dynamically appears only when there is at least one archived city**) for browsing already collected cities.
The first two buttons give access to the "import" functionality, i.e. they allow the user to add new cities to its persisten collection and in particular:

  * The *"Around Me"* button takes the current user location as the starting point to query the geonames API for a maximum of 30 nearby cities in a 10Km radius area
  
  * The *"Surprise Me"* button uses the geonames API to first retrieve (and persist) the list of all available countries with their names and geographical bounding box.
    After that, it randomly chooses one country and generates a random coordinate pair inside its bounding box which is then used as the starting point to again find at most 30 nearby cities.
    The algorithm is such that it tries to avoid obtaining the same results by storing the history of the previous 10 searches, and if it cannot find anything it automatically picks up a new country and tries again for a maximum of 4 times after which alerts the user.
  
  The third button gives access to the "browsing" functionality, where the user can browse through the archived cities and favorite/unfavorite/delete them, with all changes being persisted should the user choose to do so
  * The *"Browse <N> archived cities"* button is dynamically displayed when there are some archived cities that can be browsed/edited.

2. The importing/browsing scene is realized through the same interface but serves 2 different purposes:
  
  * From either *"Around me"* or *"Surprise Me"*, the interface segues to the combined Map/Table view that displays the results of the geonames API query.
      
      Through this scene the user can select cities on the map or on the table and have them briefly highlighted in the corresponding table or map view, displaying the population (when available).
    
      A star on the table view cells can be tapped to mark the city as a "favorite" and have it automatically moved at the top of the list where entries are ordered by favorite, population and city name.
    
      The current weather condition for each city is initially retrieved through the openweather API and a corresponding status icon (as specified in http://openweathermap.org/weather-conditions), is downloaded, cached and displayed at the leftmost position in the tableview cell.
      The current weather condition for every displayed city can be refreshed by using a pull-to-refresh gesture on the table view (please see NOTES below)
    
      The table view offers a search bar that allows to live-search the cities by either case-insensitive part of the name, or favorite/unfavorite status.
      Entries in the table view can be removed one by one through swipe gestures or by enabling the edit mode.
    
      When in edit mode, if there are any "unfavorite" entries (i.e. not starred) a button appears at the bottom that allows to bulk-delete all of them.
    
      Finally, when a wikipedia link is available, the table view cell displays a detail/accessory button that leads to the webview for the wikipedia article.
    
      Once the user is happy with the list of cities and their favorite/unfavorite state, it can tap the "import" top left button and have them persisted in the local store

  * From the *"Browse <N> archived cities"* button, the user is presented with the same map/table view combined interface. All the functionality is pretty much the same, but this time it offers a view on the already imported entries and any edit will be applied to them. This is reflected by the top left button being now named "save" instead of "import".

3. The wikipedia browsing scene is accessed by tapping on the detail/accessory button displayed on table view cells for cities that have an official wikipedia article linked to them.
       This is a webview that starts from the linked wikipedia article, but then allows full browsing, with support for backward/forward navigation



**EXAMPLE FLOW:**

You start the application and choose "Surprise Me" so that you're presented with the "importing" screen showing a cluster of nearby cities randomly choosen by the application.

From the importing scene you can search by name, have a look at some wikipedia info, and mark some cities as favorites. Through the edit mode you can then quickly delete all unfavorite cities and then tap "import" to permanently store your favorites.

Coming back to the initial screen, you can now browse all the cities imported up to now and from the browsing interface you can maybe remove some cities that you don't want to keep anymore.


##ACCESSING AND RUNNING THE APPLICATION:
The project is written in swift 2.1 using Xcode 7.2.
Access to the network APIs is done with keys hard-coded in the source, as all used APIs are free, you can test the application with the current API keys with no problem, but in any case they are defined as follows:

1. geonames API: KEY is `GeoNamesClient.Constants.Username`

2. openweather API: KEY is `OpenWeatherClient.Constants.APIKey`

After cloning the repository, open the CityRoulette/CityRoulette.xcodeproj with Xcode and simply build either for the simulator or a real iOS9 device.
If running on the simulator, you want to activate the "simulate location" functionality in Xcode to be able to try the "Around Me" functionality.

When using the "Around Me" functionality for the first time, the application will ask for permission to access the user location when in use, as that is required to choose a random cluster of cities around the user location.


#NOTES:
- As briefly explained under a `MARK:- HACK` at the end of ShowCitiesViewController.swift, I had several problems in making tableview's pull-to-refresh work correctly.

  As it turns out, the stock UIRefreshControl is officially designed to only work with UITableViewControllers and no guarantee is made for a UITableView inside a "normal" UIViewController.

  By searching around I found some workaround on Stack Overflow (see link in the code comments), where it was suggested to just create a temporary UITableViewController whose role is just to offer something upon which to set the refreshControl property.

  I did that, and to make it clear it is a hack, I've encapsulated the relevant code in an extension.

  It mostly works, but there's a glitch that I wasn't able to remove that causes the view of the refresh control to sometimes "jump" a bit vertically when the action has been triggered just before releasing the drag on the table view.

  I'm now aware that the proper solution might be to encapsulated a UITableViewController in a container view, but that would require some heavy refactoring of both the UI and the ViewController code
