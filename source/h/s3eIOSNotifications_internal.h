/*
Internal header for the s3eIOSNotifications extension.

This file should be used for any common function definitions etc that need to
be shared between the platform-dependent and platform-indepdendent parts of
this extension.
*/

/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */


#ifndef S3EIOSNOTIFICATIONS_H_INTERNAL
#define S3EIOSNOTIFICATIONS_H_INTERNAL

#include "s3eTypes.h"
#include "s3eIOSNotifications.h"
#include "s3eIOSNotifications_autodefs.h"


/**
 * Initialise the extension.  This is called once then the extension is first
 * accessed by s3eregister.  If this function returns S3E_RESULT_ERROR the
 * extension will be reported as not-existing on the device.
 */
s3eResult s3eIOSNotificationsInit();

/**
 * Platform-specific initialisation, implemented on each platform
 */
s3eResult s3eIOSNotificationsInit_platform();

/**
 * Terminate the extension.  This is called once on shutdown, but only if the
 * extension was loader and Init() was successful.
 */
void s3eIOSNotificationsTerminate();

/**
 * Platform-specific termination, implemented on each platform
 */
void s3eIOSNotificationsTerminate_platform();

s3eIOSNotificationsCallback s3eIOSNotificationsStartedWithNotification_platform();
const char* s3eIOSNotificationsGetRemoteNotificationToken_platform();
int8 s3eIOSNotificationsGetScheduleSize_platform();
void s3eIOSNotificationsCreate_platform(s3eIOSNotificationsToDoItem* item);
s3eResult s3eIOSNotificationsErase_platform(const char* notificationID);
void s3eIOSNotificationsSetAppBadge_platform(int16 badgeNumber);
s3eBool s3eIPhone_AppStartedWithNotification_platform();


#endif /* S3EIOSNOTIFICATIONS_H_INTERNAL */
