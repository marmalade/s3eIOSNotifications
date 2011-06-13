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

// ------------------------- Push Notification(s) -------------------------
@interface PushNotificationDelegate: NSObject
{
}

+ (void)ScheduleNotificationWithItem:(s3eIOSNotificationsToDoItem*) item;

@end

@implementation PushNotificationDelegate

+ (void)ScheduleNotificationWithItem:(s3eIOSNotificationsToDoItem*) item
{
    NSDate* itemDate = [[NSDate alloc] initWithTimeIntervalSince1970:(item->m_FireDateMS)];

            //// TRACE /////////////////////////////////
            NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents* dateComps = [gregorian components:(NSYearCalendarUnit |
                                                                 NSMonthCalendarUnit |
                                                                 NSDayCalendarUnit |
                                                                 NSHourCalendarUnit |
                                                                 NSMinuteCalendarUnit)
                                                                 fromDate:itemDate];

            IwDebugTraceLinePrintf("%s", item->m_EventName);
            IwDebugTraceLinePrintf("%s", item->m_EventMessage);

            IwDebugTraceLinePrintf("Minute = %i", (int)[dateComps minute]);
            IwDebugTraceLinePrintf("Hour = %i", (int)[dateComps hour]);
            IwDebugTraceLinePrintf("Day = %i", (int)[dateComps day]);
            IwDebugTraceLinePrintf("Month = %i", (int)[dateComps month]);
            IwDebugTraceLinePrintf("Year = %i\n", (int)[dateComps year]);            
            IwDebugTraceLinePrintf("Fire Date in MS: %llu", (item->m_FireDateMS));

            [gregorian release];
            ////////////////////////////////////////////

    UILocalNotification* localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
    {
        [itemDate release];
        return;
    }
    localNotif.fireDate = itemDate;
    localNotif.timeZone = [NSTimeZone defaultTimeZone];

    NSString* EventString = [NSString stringWithUTF8String:item->m_EventMessage];
    localNotif.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), EventString];
    localNotif.alertAction = NSLocalizedString(@"View Details", nil);

    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = item->m_BadgeNo;

    EventString = [NSString stringWithUTF8String:item->m_EventName];
    NSDictionary* infoDict = [NSDictionary dictionaryWithObject:EventString forKey:@"IW3D"];
    localNotif.userInfo = infoDict;

    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    [localNotif release];
    [itemDate release];
}

@end

// Returns a s3eIOSNotificationsToDoItem created from a given UILocalNotification
s3eIOSNotificationsToDoItem ConvertLocalNotification(UILocalNotification* localNotif)
{
    s3eIOSNotificationsToDoItem toDoItem;
    NSString* eventItem = @"\0";

//Event Name
    eventItem = [localNotif.userInfo objectForKey:@"IW3D"];
    toDoItem.m_EventName = [eventItem UTF8String];

//Event Message
    eventItem = localNotif.alertBody;
    toDoItem.m_EventMessage = [eventItem UTF8String];

// Event Date (in Milliseconds)
    toDoItem.m_FireDateMS = [localNotif.fireDate timeIntervalSince1970];

    return toDoItem;
}

// Informs main application of local notification(Callback function)
int32 LocalNotificationCallback(void* system, void* user)
{
    UILocalNotification* localNotif = (UILocalNotification*) system;
    if(localNotif)
    {
        s3eIOSNotificationsToDoItem toDoItem;
        toDoItem = ConvertLocalNotification(localNotif);

        s3eEdkCallbacksEnqueue(S3E_EXT_IOSNOTIFICATIONS_HASH
                                ,S3E_IOSNOTIFICATIONS_LOCAL
                                ,&toDoItem
                                ,sizeof(toDoItem)
                                //,0
                                //,S3E_FALSE
                                //,0
                                //,0
                                );
        return 1;
    }
    return 0;
}

// Informs main application of remote notification(As Local Notification)(Callback function)
int32 RemoteNotificationCallback(void* system, void* user)
{
    NSDictionary* userInfo = [(NSDictionary*) system objectForKey:@"aps"];
    if(userInfo)
    {
        s3eIOSNotificationsToDoItem toDoItem;

        // Implement notification message/name if necessary according to how you send your
        // body/alert message in your push notification
            //e.g.
            if( [userInfo objectForKey:@"alert"] != NULL)
            {
                toDoItem.m_EventName = "Default Remote Notification"; // You may wish to pass this in your notification body/alert
                NSString* alert = [userInfo objectForKey:@"alert"];
                toDoItem.m_EventMessage = [alert cStringUsingEncoding:NSUTF8StringEncoding];
                toDoItem.m_FireDateMS = 0; // You may wish to pass this in your notification body/alert
                
            }

        // Badge number from the notification is also provided in remote notifications
            //e.g.
            if( [userInfo objectForKey:@"badge"] != NULL)
            {
                NSString* badge = [userInfo objectForKey:@"badge"];
                char* chBadgeNo = (char*) [badge cStringUsingEncoding:NSUTF8StringEncoding];

                int iBadgeNo = atoi(chBadgeNo);
                toDoItem.m_BadgeNo = iBadgeNo;
            }


        s3eEdkCallbacksEnqueue(S3E_EXT_IOSNOTIFICATIONS_HASH
                                ,S3E_IOSNOTIFICATIONS_REMOTE
                                ,&toDoItem
                                ,sizeof(toDoItem)
                                //,0
                                //,S3E_FALSE
                                //,0
                                //,0
                                );
        return 1;
    }
    return 0;
}

// --------------------------- C++ Function(s) ----------------------------
s3eResult s3eIOSNotificationsInit_platform()
{
    // Add any platform-specific initialisation code here
    s3eEdkCallbacksRegister(S3E_EDK_INTERNAL, S3E_EDK_CALLBACK_MAX, S3E_EDK_IPHONE_APPLICATIONDIDRECIEVELOCALNOTIFICATION, LocalNotificationCallback, NULL, false);
    s3eEdkCallbacksRegister(S3E_EDK_INTERNAL, S3E_EDK_CALLBACK_MAX, S3E_EDK_IPHONE_APPLICATIONDIDRECIEVEREMOTENOTIFICATION, RemoteNotificationCallback, NULL, false);
    return S3E_RESULT_SUCCESS;
}

void s3eIOSNotificationsTerminate_platform()
{
    // Add any platform-specific termination code here
    s3eEdkCallbacksUnRegister(S3E_EDK_INTERNAL, S3E_EDK_CALLBACK_MAX, S3E_EDK_IPHONE_APPLICATIONDIDRECIEVELOCALNOTIFICATION, LocalNotificationCallback, NULL);
    s3eEdkCallbacksUnRegister(S3E_EDK_INTERNAL, S3E_EDK_CALLBACK_MAX, S3E_EDK_IPHONE_APPLICATIONDIDRECIEVEREMOTENOTIFICATION, RemoteNotificationCallback, NULL);
}

//returns S3E_RESUlT_SUCCESS if the application was started with up by notification
s3eIOSNotificationsCallback s3eIOSNotificationsStartedWithNotification_platform()
{
    UILocalNotification* localNotif = (UILocalNotification*) s3eEdkAppGetInitialLocalNotification();
    IwTrace(Device, ("Checking for Local Notification on startup"));

    if(localNotif)
    {
        IwTrace(Device, ("Started with local notification"));
        LocalNotificationCallback(localNotif, 0);
        s3eEdkAppReleaseInitialLocalNotification();

        return S3E_IOSNOTIFICATIONS_LOCAL;
    }

    NSDictionary* remoteNotif = (NSDictionary*) s3eEdkAppGetInitialRemoteNotification();
    IwTrace(Device, ("Checking for Remote Notification on startup"));

    if(remoteNotif)
    {
        IwTrace(Device, ("Started with remote notification"));
        LocalNotificationCallback(remoteNotif, 0);
        s3eEdkAppReleaseInitialRemoteNotification();

        return S3E_IOSNOTIFICATIONS_REMOTE;
    }

    IwTrace(Device, ("Was not start with a notification"));
    return S3E_IOSNOTIFICATIONS_CALLBACK_MAX;
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
        NSString* eventName = [NSString stringWithUTF8String: notificationID];
        UILocalNotification* notificationToCancel = nil;
        for(UILocalNotification* localNotif in [[UIApplication sharedApplication] scheduledLocalNotifications])
        {
            if([[localNotif.userInfo objectForKey:@"IW3D"] isEqualToString: eventName])
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

//Legacy function does the same as s3eIOSNotificationsStartedWithNotification_platform
//Function does not however fire callback(s) to get notifiction information
s3eBool s3eIPhone_AppStartedWithNotification_platform()
{
    return s3eEdkAppStartedWithNotification();
}
