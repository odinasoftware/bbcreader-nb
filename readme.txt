1. Newstand support

If your Newsstand application includes the <UIBackgroundModes> key with the newsstand-content value in its Info.plist file, 
your Newsstand application is launched in the background so that it can start downloading the latest issue. 
The download process itself is managed by the system, which notifies your application when the content is fully downloaded and available.

When your server is alerting your application of a new issue, that server should include the content-available property (with a value of 1) in the JSON payload. 
This property tells the system that it should launch your application so that it can begin downloading the new issue. 
Applications are launched and alerted to new issues once in a 24-hour period at most, although if your application is running when the notification arrives, 
it can begin downloading the content immediately.

In addition to your server providing content for each new issue, it should also provide cover art to present in Newsstand when that issue is available. 

2. Local only newstand is possible???
- cannot start background donwloading?

3. Tweet

4. Add background as much as posbbile

5. Fix facebook API