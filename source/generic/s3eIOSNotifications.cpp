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
/*
 * Generic implementation of the s3eIOSNotifications extension.
 * This file should perform any platform-indepedentent functionality
 * (e.g. error checking) before calling platform-dependent implementations.
 *
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */

#include "s3eIOSNotifications_internal.h"

s3eResult s3eIOSNotificationsInit()
{
    //Add any generic initialisation code here
    return s3eIOSNotificationsInit_platform();
}

void s3eIOSNotificationsTerminate()
{
    //Add any generic termination code here
    s3eIOSNotificationsTerminate_platform();
}

s3eIOSNotificationsLaunchNotification s3eIOSNotificationsGetLaunchNotification()
{
    return s3eIOSNotificationsGetLaunchNotification_platform();
}

const char* s3eIOSNotificationsGetRemoteNotificationToken()
{
    return s3eIOSNotificationsGetRemoteNotificationToken_platform();
}

int8 s3eIOSNotificationsGetScheduleSize()
{
    return s3eIOSNotificationsGetScheduleSize_platform();
}

void s3eIOSNotificationsCreate(s3eIOSNotificationsToDoItem* item)
{
    s3eIOSNotificationsCreate_platform(item);
}

s3eResult s3eIOSNotificationsErase(const char* notificationID)
{
    return s3eIOSNotificationsErase_platform(notificationID);
}

void s3eIOSNotificationsSetAppBadge(int16 badgeNumber)
{
    s3eIOSNotificationsSetAppBadge_platform(badgeNumber);
}

s3eBool s3eIPhone_AppStartedWithNotification()
{
    return s3eIPhone_AppStartedWithNotification_platform();
}
