
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

#include "IwTest.h"
#include "IwTestInteractive.h"
#include "test_s3eIOSNotifications.h"
#include <time.h>

#define CHECK_IOSNOTIFICATIONS_AVAILABLE() \
    if (!s3eIOSNotificationsAvailable()) \
    { \
        IwTestSkip("s3eIOSNotifications extension not present"); \
        return true; \
    } \


// Callback function(s)
int32 LocalNotificationRecieved(void* systemData, void* userData)
{
    s3eIOSNotificationsUnRegister(S3E_IOSNOTIFICATIONS_LOCAL, LocalNotificationRecieved);

    return 1;
}

IW_ITEST bool test_s3eIOSNotifications_StartedWithNotification()
{
    CHECK_IOSNOTIFICATIONS_AVAILABLE()

    if (!IwTestIsRestoring())
    {
        s3eIOSNotificationsRegister(S3E_IOSNOTIFICATIONS_LOCAL, LocalNotificationRecieved, NULL);
        s3eIOSNotificationsToDoItem ToDoItem;
        int dst = 0;

        if(IwTestDialogSimple("DST", "Does the test need to account for Daylight savings time?\n"
                                      "NOTE: Device timeZone MUST be set to GMT for the purpose of "
                                      "this test.\n\n"
                                      "Select \"Ok\" if yes otherwise select \"Skip\"",
                                      IW_TEST_DIALOG_OK_SKIP))
        {
            dst = 1;
        }

        time_t rawtime;
        struct tm * timeinfo;

        time ( &rawtime );
        timeinfo = localtime ( &rawtime );
        timeinfo->tm_hour -= dst;
        timeinfo->tm_min += 1;

        time_t lTimeEpoch = mktime(timeinfo);

        IwTrace(DEVICE, ("Fire Time %s: ", ctime (&rawtime)));

        ToDoItem.m_FireDateMS = (uint64)(lTimeEpoch);
        ToDoItem.m_BadgeNo = 0;
        ToDoItem.m_EventMessage = "Test was successful";
        ToDoItem.m_EventName = "TestName";

        IwTestSaveState();

        // Set Notification
        s3eIOSNotificationsCreate(&ToDoItem);

        if(!IwTestDialogSimple("Restarting", "Please force-exit this application via the OS, e.g. by "
                                             "closing it in a task switcher.\n"
                                             "Please wait for a local notification to fire. If this takes more "
                                             "than 2 mins the test has failed.\n\n"
                                             "Select \"Pass\" if this is correct otherwise select \"Fail\"",
                                             IW_TEST_DIALOG_PASS_FAIL))
        {
            IwTestError("Notification did not open application");
            return false;
        }
    }
    IwTestStopRestoring();
    return true;
}

IW_TEST bool test_s3eIOSNotifications_GetPushNotificationToken()
{
    CHECK_IOSNOTIFICATIONS_AVAILABLE()

    if(s3eIOSNotificationsGetRemoteNotificationToken())
        return true;

    return false;
}

IW_TEST bool test_s3eIOSNotifications_GetScheduleSize()
{
    CHECK_IOSNOTIFICATIONS_AVAILABLE()

    if(S3E_RESULT_ERROR == s3eIOSNotificationsErase())
    {
        IwTestError("Test could not continue as notification schedule could not be emptied");
        return false;
    }
    s3eIOSNotificationsToDoItem ToDoItem;

    // This test is no longer valid after 01/01/3000
    ToDoItem.m_FireDateMS = 32503680000000ULL;
    ToDoItem.m_BadgeNo = 1;
    ToDoItem.m_EventMessage = "Test was successful";
    ToDoItem.m_EventName = "TestName";

    s3eIOSNotificationsCreate(&ToDoItem);

    if(1 != s3eIOSNotificationsGetScheduleSize())
    {
        IwTestError("The schedule size is incorrect. There should currently be only 1 event sheduled");
        return false;
    }

    return true;
}

IW_TEST bool test_s3eIOSNotifications_Create()
{
    CHECK_IOSNOTIFICATIONS_AVAILABLE()

    if(S3E_RESULT_ERROR == s3eIOSNotificationsErase())
    {
        IwTestError("Test could not continue as notification schedule could not be emptied");
        return false;
    }
    s3eIOSNotificationsToDoItem ToDoItem;

    // This test is no longer valid after 01/01/3000
    ToDoItem.m_FireDateMS = 32503680000000ULL;
    ToDoItem.m_BadgeNo = 1;
    ToDoItem.m_EventMessage = "Test was successful";
    ToDoItem.m_EventName = "TestName";

    s3eIOSNotificationsCreate(&ToDoItem);

    if(0 == s3eIOSNotificationsGetScheduleSize())
    {
        IwTestError("Create function has been run yet the notification schedule list has not been updated");
        return false;
    }
    return true;
}

IW_TEST bool test_s3eIOSNotifications_Erase()
{
    CHECK_IOSNOTIFICATIONS_AVAILABLE()

    s3eIOSNotificationsToDoItem ToDoItem;

    // Test Item 1
    // This test is no longer valid after 01/01/3000
    ToDoItem.m_FireDateMS = 32503680000000ULL;
    ToDoItem.m_BadgeNo = 1;
    ToDoItem.m_EventMessage = "Test was successful";
    ToDoItem.m_EventName = "Test1";

    s3eIOSNotificationsCreate(&ToDoItem);

    // Test Item 2
    // This test is no longer valid after 01/01/3000
    ToDoItem.m_FireDateMS = 32503680000000ULL;
    ToDoItem.m_BadgeNo = 2;
    ToDoItem.m_EventMessage = "Test was successful";
    ToDoItem.m_EventName = "Test2";

    s3eIOSNotificationsCreate(&ToDoItem);

    // Test Item 3
    // This test is no longer valid after 01/01/3000
    ToDoItem.m_FireDateMS = 32503680000000ULL;
    ToDoItem.m_BadgeNo = 3;
    ToDoItem.m_EventMessage = "Test was successful";
    ToDoItem.m_EventName = "Test3";

    s3eIOSNotificationsCreate(&ToDoItem);


    // Test Erase SINGLE Notification
    uint8 oldNotificationScheduleSize = s3eIOSNotificationsGetScheduleSize();
    if(0 == oldNotificationScheduleSize)
    {
        IwTestError("Test could not continue as notification schedule list update failed");
        return false;
    }

    if(S3E_RESULT_ERROR == s3eIOSNotificationsErase("Test1"))
    {
        IwTestError("Notification erase function was run but scheduled notification has not been erased");
        return false;
    }

    if(s3eIOSNotificationsGetScheduleSize() >= oldNotificationScheduleSize)
    {
        IwTestError("Test failed: Single notification was not erased");
        return false;
    }

    // Test Erase MULTIPLE Notification
    if(S3E_RESULT_ERROR == s3eIOSNotificationsErase())
    {
        IwTestError("Notification erase function was run but notification schedule list has not been emptied");
        return false;
    }

    if(0 != s3eIOSNotificationsGetScheduleSize())
    {
        IwTestError("Test failed: Full notification list was not erased");
        return false;
    }

    return true;
}

IW_ITEST bool test_s3eIOSNotifications_SetAppBadge()
{
    CHECK_IOSNOTIFICATIONS_AVAILABLE()

    s3eIOSNotificationsSetAppBadge(0);
    if(!IwTestDialogSimple("SetAppBadge", "Please minimse the application and check that the badge number is no longer visible.\n\n"
    "Select \"Pass\" if this is correct otherwise select \"Fail\".", IW_TEST_DIALOG_PASS_FAIL))
    {
        IwTestError("User indicated that badge number was set incorrectly");
        return false;
    }

    s3eIOSNotificationsSetAppBadge(10);

    if(!IwTestDialogSimple("SetAppBadge", "Please minimse the application and check that the badge number is now 10.\n\n"
    "Select \"Pass\" if this is correct otherwise select \"Fail\".", IW_TEST_DIALOG_PASS_FAIL))
    {
        IwTestError("User indicated that badge number was set incorrectly");
        return false;
    }

    s3eIOSNotificationsSetAppBadge(0);

    return true;
}
