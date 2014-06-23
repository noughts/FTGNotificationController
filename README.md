FTGNotificationController
=========
Simple and safe way to observe notification

How I do it
--
- Modify Facebook 's KVOController to work with NSNotificationCenter

How to use it
--
- Example
```
self.notificationController = [FTGNotificationController controllerWithObserver:self];
    [self.notificationController observeNotificationName:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil
                                                   queue:[NSOperationQueue mainQueue]
                                                   block:^(NSNotification *note, id observer)
    {
        NSLog(@"observer %@ notification payload %@", observer, note);
    }];
```
- To automatically remove observers on observer dealloc, declare FTGNotificationController as strong property
- Unlike KVOController, this allows duplication just like NSNotificationCenter does
