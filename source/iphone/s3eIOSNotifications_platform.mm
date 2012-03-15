/*
 * Copyright (C) 2001-2011 Ideaworks3D Ltd.
 * All Rights Reserved.
 *
 * This document is protected by copyright, and contains information
 * proprietary to Ideaworks Labs.
 * This file consists of source code released by Ideaworks Labs under
 * the terms of the accompanying End User License Agreement (EULA).
 * Please do not use this program/source code before you have read the
 * EULA and have agreed to be bound by its terms.
 */
 
#include "s3eIOSNotifications_internal.h"
#include "s3eEdk.h"
#include "s3eEdk_iphone.h"
#include <stdlib.h> // for atoi()

#include "IwDebug.h"

// ------------------------- Push Notification(s) ------------------------
// Delegate just has class (static) methods for global jobs.

@interface PushNotificationDelegate: NSObject
{
}

// TODO: We should use the global ios notification UIApplicationDidFinishLaunchingNotification
// for local/push notifications to completely seperate it from the loader:
// Need to instantiate and release a PushNotificationDelegate in init and term (currently static).
// Probably can't use a static (+) method, so switch to (-)
//+ (void)ApplicationDidFinishLaunching:(NSNotification*)aNotification;

+ (void)ScheduleNotificationWithItem:(s3eIOSNotificationsToDoItem*) item;

@end

@implementation PushNotificationDelegate

/*
+ (void)ApplicationDidFinishLaunching:(NSNotification*)aNotification
{
    m_InitialRemoteNotification = nil;
    m_InitialLocalNotification = nil;
    
    NSDictionary* launchOptions = [aNotification userInfo];
    
    if (launchOptions)
    {
        UILocalNotification *notif = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        if(notif)
        {
            // Setup an initial notification that can be checked when the application has finished setting up its callback
            m_InitialLocalNotification = notif;
            [m_InitialLocalNotification retain];
        }
        else // Set initial notification to nil as an initial notification was not set
            m_InitialLocalNotification = nil;

        // Check if we were launched with a remote notification..
        NSDictionary* pnsDict = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (pnsDict)
        {
            m_InitialRemoteNotification = pnsDict;
            [m_InitialRemoteNotification retain];
        }
    }
}
*/

+ (void)ScheduleNotificationWithItem:(s3eIOSNotificationsToDoItem*) item
{
    NSDate* itemDate = nil;
    
    if (item->m_FireDateS)
    {
        itemDate = [[NSDate alloc] initWithTimeIntervalSince1970:(item->m_FireDateS)];

#ifdef S3E_STORE_ERROR_STRINGS //cheap test for if this is a debug build

        NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents* dateComps = [gregorian components:(NSYearCalendarUnit |
                                                             NSMonthCalendarUnit |
                                                             NSDayCalendarUnit |
                                                             NSHourCalendarUnit |
                                                             NSMinuteCalendarUnit)
                                                             fromDate:itemDate];

        if (item->m_EventName)
            IwTrace(IOSNOTIFICATIONS, ("%s", item->m_EventName));
        if (item->m_EventData)
            IwTrace(IOSNOTIFICATIONS, ("%s", item->m_EventName));
        if (item->m_EventMessage)
            IwTrace(IOSNOTIFICATIONS, ("%s", item->m_EventMessage));

        IwTrace(IOSNOTIFICATIONS, ("Minute = %i", (int)[dateComps minute]));
        IwTrace(IOSNOTIFICATIONS, ("Hour = %i", (int)[dateComps hour]));
        IwTrace(IOSNOTIFICATIONS, ("Day = %i", (int)[dateComps day]));
        IwTrace(IOSNOTIFICATIONS, ("Month = %i", (int)[dateComps month]));
        IwTrace(IOSNOTIFICATIONS, ("Year = %i\n", (int)[dateComps year]));
        IwTrace(IOSNOTIFICATIONS, ("Fire Date in Seconds: %llu", item->m_FireDateS));

        [gregorian release];
#endif
    }

    UILocalNotification* localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
    {
        if (itemDate)
            [itemDate release];
        return;
    }

    localNotif.fireDate = itemDate;
    localNotif.timeZone = [NSTimeZone defaultTimeZone];

    // Alert control options
    localNotif.alertAction = NSLocalizedString(@"View Details", nil); // TODO: use m_AlertAction & m_ShowAlert
    localNotif.soundName = UILocalNotificationDefaultSoundName; // TODO: use m_SoundFile
    localNotif.applicationIconBadgeNumber = item->m_BadgeNo;
    // TODO: m_AlertLaunchImage

    if (item->m_EventMessage)
    {
        NSString* messageString = [NSString stringWithUTF8String:item->m_EventMessage];
        localNotif.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), messageString];
    }
    //else defaults to nil -> no message displayed to user

    // Create a dictionary for the custom data that contains two optional string values:
    // key "name": string to allow app to identify local notifications it has queued up
    // key "data": single string for containing any extra custom data
    //   Note that natively the dictionary can take multiple keys of all plist types but
    //   we arent supporting that. Data (at least for remote notifications) is limited to 256bytes.
    
    NSString* nameString = nil;
    NSString* dataString = nil;
    NSMutableDictionary* infoDict = nil;
    
    if (item->m_EventName || item->m_EventData)
        infoDict = [NSMutableDictionary dictionaryWithCapacity:2];
    
    if (item->m_EventName)
    {
        nameString = [NSString stringWithUTF8String:item->m_EventName];
        [infoDict setValue:nameString forKey:@"name"];
    }
    
    if (item->m_EventData)
    {
        dataString = [NSString stringWithUTF8String:item->m_EventData];
        [infoDict setValue:dataString forKey:@"data"];
    }

    if (infoDict)
        localNotif.userInfo = infoDict;

    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    // NSStrings & dictionary are autoreleased after scheduling
    [localNotif release];

    if (itemDate)
        [itemDate release];
}

@end

// Returns an s3eIOSNotificationsToDoItem created from a given UILocalNotification
s3eIOSNotificationsToDoItem ConvertLocalNotification(UILocalNotification* localNotif)
{
    s3eIOSNotificationsToDoItem toDoItem = {0};
    
    // Strings are valid until autorelease & therefore till end of callback
    NSString* nameString = [localNotif.userInfo objectForKey:@"name"];
    if (nameString)
        toDoItem.m_EventName = strdup([nameString UTF8String]);
    
    // NB: alloc and copy string (strdup) since [NSString UTF8String] appears to get
    // autoreleased even if we retain localNotif. Safer to alloc and free it ourself
    
    NSString* dataString = [localNotif.userInfo objectForKey:@"data"];
    if (dataString)
        toDoItem.m_EventData = strdup([dataString UTF8String]);
        
    if (localNotif.alertBody)
        toDoItem.m_EventMessage = strdup([localNotif.alertBody UTF8String]);

    if (localNotif.fireDate)
        toDoItem.m_FireDateS = [localNotif.fireDate timeIntervalSince1970];
        
    toDoItem.m_BadgeNo = (int16)localNotif.applicationIconBadgeNumber;
    
    //todo:
    //m_AlertAction
    //m_ShowAlert
    //m_AlertLaunchImage
    //m_SoundFile

    return toDoItem;
}

// Returns an s3eIOSNotificationsToDoItem created from a remote notification dictionary
s3eIOSNotificationsToDoItem ConvertRemoteNotification(NSDictionary* remoteNotif)
{
    // remoteNotif contains any custon data entries as keys with their own names from the JSON,
    // plus an "aps" (apple push notification) key which is another dictionary containing
    // "alert", "badge" and "sound" keys:
    // alert: either (1) an NSString for the alert message, or (2) or a dictionary with two keys:
    //        "body"=NSString as above, "show-view"=NSNumber boolean (was a 'view' button shown in the alert?)
    // badge: either (1) badge num as NSNumber, or (2) doesn't exist - indicates badge should be zero'd.
    // sound: NSstring name of sound file played from app bundle to play (may be "default")
    
    s3eIOSNotificationsToDoItem toDoItem = {0};
    
    // allowing remote notifications to use our custom "name" key
    NSString* nameString = [remoteNotif objectForKey:@"name"];
    if (nameString)
        toDoItem.m_EventName = strdup([nameString UTF8String]);
    
    NSString* dataString = [remoteNotif objectForKey:@"data"];
    if (dataString)
        toDoItem.m_EventData = strdup([dataString UTF8String]);
    
    NSDictionary* apsInfo = [remoteNotif objectForKey:@"aps"];
    
    // all dict actions should succeed but maybe message gets truncated or values are null
    if (apsInfo) 
    {
        NSNumber* badge = [apsInfo objectForKey:@"badge"];
        if (badge)
            toDoItem.m_BadgeNo = (int16)[badge intValue];

        NSObject* alert = [apsInfo objectForKey:@"alert"];
        if (alert)
        {
            if ([alert isKindOfClass:[NSString class]])
                toDoItem.m_EventMessage = strdup([(NSString*)alert UTF8String]);
            else
            {
                NSString* message = (NSString*)[(NSDictionary*)alert objectForKey:@"body"];
                if (message)
                    toDoItem.m_EventMessage = strdup([message UTF8String]);
                // m_ShowAlert <- @"show-view"
            }
        }
        
        //NSString sound = [apsInfo objectForKey:@"sound"];
        //if (sound)
        //    toDoItem.m_SoundFile = [sound UTF8String];
    }

    // other values are for local notifications only and remain null

    return toDoItem;
}

// release any strings we allocated with strdup
void releaseNotificationStrings(uint32 extID, int32 notification, void* systemData, void* instance, int32 returnCode, void* completeData)
{
    NSLog(@"releasing local notification strings");
    
    s3eIOSNotificationsToDoItem* toDoItem = (s3eIOSNotificationsToDoItem*)systemData;
    if(toDoItem)
    {
        if (toDoItem->m_EventName)
            free((char*)toDoItem->m_EventName);
        if (toDoItem->m_EventMessage)
            free((char*)toDoItem->m_EventMessage);
        if (toDoItem->m_EventData)
            free((char*)toDoItem->m_EventData);
    }
}

// Informs main application of local notification(Callback function)
int32 LocalNotificationCallback(void* system, void* user)
{
    IwTrace(IOSNOTIFICATIONS, ("Local notification received"));
    UILocalNotification* localNotif = (UILocalNotification*)system;

    if(!localNotif)
    {
        IwTrace(IOSNOTIFICATIONS, ("Local notification was null, ignoring"));
        return 0;
    }

    // Create notification.
    // Note this is declared on the stack but then copied to heap by
    // s3eEdkCallbacksEnqueue since we are passing a pointer to and the size of
    // the item. The callback system will then free this automatically once the
    // callback completes. Any native obj-C objects that toDoItem points to
    // will be freed automatically when their autorelease pools are freed
    // (in s3eDeviceYield, which occurs after all callbacks have fired).
    
    s3eIOSNotificationsToDoItem toDoItem = ConvertLocalNotification(localNotif);

    s3eEdkCallbacksEnqueue(S3E_EXT_IOSNOTIFICATIONS_HASH,
                           S3E_IOSNOTIFICATIONS_LOCAL,
                           &toDoItem,
                           sizeof(toDoItem),
                           NULL,
                           false,
                           releaseNotificationStrings);
    return 1;
}

// Informs main application of remote notification(As Local Notification)(Callback function)
int32 RemoteNotificationCallback(void* system, void* user)
{
    IwTrace(IOSNOTIFICATIONS, ("Remote notification received"));
    NSDictionary* remoteNotif = (NSDictionary*)system;

    if(!remoteNotif)
    {
        IwTrace(IOSNOTIFICATIONS, ("Local notification was null, ignoring"));
        return 0;
    }
    
    s3eIOSNotificationsToDoItem toDoItem = ConvertRemoteNotification(remoteNotif);
    
    s3eEdkCallbacksEnqueue(S3E_EXT_IOSNOTIFICATIONS_HASH,
                           S3E_IOSNOTIFICATIONS_REMOTE,
                           &toDoItem,
                           sizeof(toDoItem),
                           NULL,
                           false,
                           releaseNotificationStrings);
    return 1;
}

// --------------------------- C++ Function(s) ----------------------------
s3eResult s3eIOSNotificationsInit_platform()
{
    s3eEdkCallbacksRegisterInternal(S3E_EDK_INTERNAL, S3E_EDK_CALLBACK_MAX, S3E_EDK_IPHONE_DID_RECEIVE_LOCAL_NOTIFICATION, LocalNotificationCallback, NULL, false);
    s3eEdkCallbacksRegisterInternal(S3E_EDK_INTERNAL, S3E_EDK_CALLBACK_MAX, S3E_EDK_IPHONE_DID_RECEIVE_REMOTE_NOTIFICATION, RemoteNotificationCallback, NULL, false);
 
    //TODO: Init g_NotificationDelegate
    //[[NSNotificationCenter defaultCenter] addObserver:g_NotificationDelegate selector:@selector(ApplicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    return S3E_RESULT_SUCCESS;
}

void s3eIOSNotificationsTerminate_platform()
{
    //[[NSNotificationCenter defaultCenter] removeObserver:g_NotificationDelegate name:UIApplicationDidFinishLaunchingNotification object:nill];

    s3eEdkCallbacksUnRegister(S3E_EDK_INTERNAL, S3E_EDK_CALLBACK_MAX, S3E_EDK_IPHONE_DID_RECEIVE_LOCAL_NOTIFICATION, LocalNotificationCallback, NULL);
    s3eEdkCallbacksUnRegister(S3E_EDK_INTERNAL, S3E_EDK_CALLBACK_MAX, S3E_EDK_IPHONE_DID_RECEIVE_REMOTE_NOTIFICATION, RemoteNotificationCallback, NULL);
}

// Returns type of notification application was launched with (if any)
// and enqueues any notification (will fire during next yield)
s3eIOSNotificationsLaunchNotification s3eIOSNotificationsGetLaunchNotification_platform()
{
    UILocalNotification* localNotif = (UILocalNotification*)s3eEdkAppGetInitialLocalNotification();
    IwTrace(Device, ("Checking for Local Notification on startup"));

    if(localNotif)
    {
        IwTrace(Device, ("Started with local notification"));
        LocalNotificationCallback(localNotif, 0);
        s3eEdkAppReleaseInitialLocalNotification();

        return S3E_IOSNOTIFICATIONS_LAUNCH_LOCAL;
    }

    NSDictionary* remoteNotif = (NSDictionary*)s3eEdkAppGetInitialRemoteNotification();
    IwTrace(Device, ("Checking for Remote Notification on startup"));

    if(remoteNotif)
    {
        IwTrace(Device, ("Started with remote notification"));
        RemoteNotificationCallback(remoteNotif, 0);
        s3eEdkAppReleaseInitialRemoteNotification();

        return S3E_IOSNOTIFICATIONS_LAUNCH_REMOTE;
    }

    IwTrace(Device, ("Was not start with a notification"));
    return S3E_IOSNOTIFICATIONS_LAUNCH_NONE;
}

// Returns the push notification token ID for this device, if there is one.
const char* s3eIOSNotificationsGetRemoteNotificationToken_platform()
{
    return s3eEdkAppGetRemoteNotificationToken();
}

//Returns the current number of scheduled notifications
int8 s3eIOSNotificationsGetScheduleSize_platform()
{
    return [[[UIApplication sharedApplication] scheduledLocalNotifications] count];
}

//Create a push notification Item using s3eToDoItem
void s3eIOSNotificationsCreate_platform(s3eIOSNotificationsToDoItem* item)
{    
    [PushNotificationDelegate ScheduleNotificationWithItem: item];
}

// Clears a specific notification according to its ID. If no ID is provided ALL notifications
// are erased. If multiple ID's using this name are present the latest ID is cleared
s3eResult s3eIOSNotificationsErase_platform(const char* notificationID)
{
    if(notificationID)
    {
        NSString* objID = [NSString stringWithUTF8String: notificationID];
        UILocalNotification* notificationToCancel = nil;
        for(UILocalNotification* localNotif in [[UIApplication sharedApplication] scheduledLocalNotifications])
        {
            if([[localNotif.userInfo objectForKey:@"name"] isEqualToString: objID])
            {
                notificationToCancel = localNotif;
                break;
            }
        }

        if(notificationToCancel)
        {
            [[UIApplication sharedApplication] cancelLocalNotification: notificationToCancel];
            return S3E_RESULT_SUCCESS;
        }
        else
            return S3E_RESULT_ERROR;
    }

    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    return S3E_RESULT_SUCCESS;
}

//Set the badge number of the application. If set to 0 the app will not use a badge
void s3eIOSNotificationsSetAppBadge_platform(int16 badgeNumber)
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = badgeNumber;
}


//Legacy function (which has been replaced by the more general s3eIOSNotificationsGetLaunchNotification)
//Function does not however fire callback(s) to get notifiction information
s3eBool s3eIPhone_AppStartedWithNotification_platform()
{
    return s3eEdkAppStartedWithNotification();
}
