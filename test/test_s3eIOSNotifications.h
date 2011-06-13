
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

#include "s3eIOSNotifications.h"

// utility function for tracing enum values as strings
const char* GetIOSNotificationsCallbackString(s3eIOSNotificationsCallback enumValue)
{
    #define RETURN(c) case c: return #c
    switch(enumValue)
    {
    RETURN(S3E_IOSNOTIFICATIONS_LOCAL);
    RETURN(S3E_IOSNOTIFICATIONS_REMOTE);
    RETURN(S3E_IOSNOTIFICATIONS_CALLBACK_MAX);
    }

    return "ERROR- bad enum value for enum s3eIOSNotificationsCallback";
}

// Utility function for iterating through enum
s3eIOSNotificationsCallback GetIOSNotificationsCallbackAtIndex(int i)
{
    switch(i)
    {
    case 0: return S3E_IOSNOTIFICATIONS_LOCAL;
    case 1: return S3E_IOSNOTIFICATIONS_REMOTE;
    case 2: return S3E_IOSNOTIFICATIONS_CALLBACK_MAX;
    }

    IwTestTrace("Bad Index for enum s3eIOSNotificationsCallback");
    return (s3eIOSNotificationsCallback)0;
}

#define S3EIOSNOTIFICATIONSCALLBACK_COUNT 3
