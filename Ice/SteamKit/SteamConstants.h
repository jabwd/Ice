#import "MsgType.h"

typedef NS_ENUM(UInt32, SKPersonaState)
{
	SKPersonaStateOffline	= 0,
	SKPersonaStateOnline	= 1,
	SKPersonaStateBusy		= 2,
	SKPersonaStateAway		= 3,
	SKPersonaStateSnooze	= 4,
	SKPersonaStateLookingToTrade	= 5,
	SKPersonaStateLookingToPlay		= 6,
	SKPersonaStateMax				= 7
};

typedef NS_ENUM(SInt32, SKChatEntryType)
{
	SKChatEntryTypeMessage	= 1,
	SKChatEntryTypeTyping	= 2,
};

typedef NS_ENUM(UInt32, SKOSType)
{
	SKOSTypeUnknown = -1,
	SKOSTypeUMQ			= -400,
	SKOSTypePS3			= -300,
	SKOSTypeMacOSX		= -102,
	SKOSTypeMacOS104	= -101,
	SKOSTypeMacOS105	= -100,
	SKOSTypeMacOS1058	= -99,
	SKOSTypeMacOS106	= -95,
	SKOSTypeMacOS1063	= -94,
	SKOSTypeMacOS1064	= -93,
	SKOSTypeMacOS1067	= -92,
	SKOSTypeMacOS107	= -90,
	SKOSTypeMacOS108	= -89,
	SKOSTypeMacOS109	= -88,
	SKOSTypeLinuxUnknown = -203,
	SKOSTypeLinux22		= -202,
	SKOSTypeLinux24		= -201,
	SKOSTypeLinux26		= -200,
	SKOSTypeLinux32		= -199,
	SKOSTypeLinux35		= -198,
	SKOSTypeLinux36		= -197,
	SKOSTypeLinux310	= -196,
	SKOSTypeWinUnknown	= 0,
	SKOSTypeWin311		= 1,
	SKOSTypeWin95		= 2,
	SKOSTypeWin98		= 3,
	SKOSTypeWinME		= 4,
	SKOSTypeWinNT		= 5,
	SKOSTypeWin200		= 6,
	SKOSTypeWinXP		= 7,
	SKOSTypeWin2003		= 8,
	SKOSTypeWinVista	= 9,
	SKOSTypeWin7		= 10,
	SKOSTypeWindows7	= 10,
	SKOSTypeWin2008		= 11,
	SKOSTypeWin2012		= 12,
	SKOSTypeWindows8	= 13,
	SKOSTypeWindows81	= 14,
	SKOSTypeWinMAX		= 15,
	SKOSTypeMax			= 26,
};

typedef NS_ENUM(UInt32, SKPlatformType)
{
	SKPlatformTypeUnknown	= 0,
	SKPlatformTypeWin32		= 1,
	SKPlatformTypeWin64		= 2,
	SKPlatformTypeLinux		= 3,
	SKPlatformTypeOSX		= 4,
	SKPlatformTypePS3		= 5,
	SKPlatformTypeMax		= 6,
};

typedef NS_ENUM(UInt8, SKRegionCode)
{
	SKRegionCodeUSEast			= 0x00,
	SKRegionCodeUSWest			= 0x01,
	SKRegionCodeSouthAmerica	= 0x02,
	SKRegionCodeEurope			= 0x03,
	SKRegionCodeAsia			= 0x04,
	SKRegionCodeAustralia		= 0x05,
	SKRegionCodeMiddleEast		= 0x06,
	SKRegionCodeAfrica			= 0x07,
	SKRegionCodeWorld			= 0xFF,
};

typedef NS_ENUM(UInt32, SKResultCode)
{
	SKResultCodeInvalid = 0,
	SKResultCodeOK		= 1,
	SKResultCodeFail	= 2,
	SKResultCodeNoConnection		= 3,
	SKResultCodeInvalidPassword		= 5,
	SKResultCodeLoggedInElsewhere	= 6,
	SKResultCodeInvalidProtocolVer	= 7,
	SKResultCodeInvalidParam		= 8,
	SKResultCodeFileNotFound		= 9,
	SKResultCodeBusy				= 10,
	SKResultCodeInvalidState	= 11,
	SKResultCodeInvalidName		= 12,
	SKResultCodeInvalidEmail	= 13,
	SKResultCodeDuplicateName	= 14,
	SKResultCodeAccessDenied	= 15,
	SKResultCodeTimeout			= 16,
	SKResultCodeBanned			= 17,
	SKResultCodeAccountNotFound			= 18,
	SKResultCodeInvalidSteamID			= 19,
	SKResultCodeServiceUnavailable		= 20,
	SKResultCodeNotLoggedOn				= 21,
	SKResultCodePending					= 22,
	SKResultCodeEncryptionFailure		= 23,
	SKResultCodeInsufficientPrivilege	= 24,
	SKResultCodeLimitExceeded			= 25,
	SKResultCodeRevoked					= 26,
	SKResultCodeExpired					= 27,
	SKResultCodeAlreadyRedeemed			= 28,
	SKResultCodeDuplicateRequest		= 29,
	SKResultCodeAlreadyOwned			= 30,
	SKResultCodeIPNotFound				= 31,
	SKResultCodePersistFailed			= 32,
	SKResultCodeLockingFailed			= 33,
	SKResultCodeLogonSessionReplaced	= 34,
	SKResultCodeConnectFailed			= 35,
	SKResultCodeHandshakeFailed			= 36,
	SKResultCodeIOFailure				= 37,
	SKResultCodeRemoteDisconnect		= 38,
	SKResultCodeShoppingCartNotFound	= 39,
	SKResultCodeBlocked				= 40,
	SKResultCodeIgnored				= 41,
	SKResultCodeNoMatch				= 42,
	SKResultCodeAccountDisabled		= 43,
	SKResultCodeServiceReadOnly		= 44,
	SKResultCodeAccountNotFeatured	= 45,
	SKResultCodeAdministratorOK		= 46,
	SKResultCodeContentVersion		= 47,
	SKResultCodeTryAnotherCM		= 48,
	SKResultCodePasswordRequiredToKickSession	= 49,
	SKResultCodeAlreadyLoggedInElsewhere		= 50,
	SKResultCodeSuspended					= 51,
	SKResultCodeCancelled					= 52,
	SKResultCodeDataCorruption				= 53,
	SKResultCodeDiskFull					= 54,
	SKResultCodeRemoteCallFailed			= 55,
	SKResultCodePasswordNotSet				= 56,
	SKResultCodeExternalAccountUnlinked		= 57,
	SKResultCodePSNTicketInvalid			= 58,
	SKResultCodeExternalAccountAlreadyLinked	= 59,
	SKResultCodeRemoteFileConflict				= 60,
	SKResultCodeIllegalPassword					= 61,
	SKResultCodeSameAsPreviousValue				= 62,
	SKResultCodeAccountLogonDenied				= 63,
	SKResultCodeCannotUseOldPassword			= 64,
	SKResultCodeInvalidLoginAuthCode			= 65,
	SKResultCodeAccountLogonDeniedNoMailSent	= 66,
	SKResultCodeHardwareNotCapableOfIPT			= 67,
	SKResultCodeIPTInitError					= 68,
	SKResultCodeParentalControlRestricted		= 69,
	SKResultCodeFacebookQueryError				= 70,
	SKResultCodeExpiredLoginAuthCode			= 71,
	SKResultCodeIPLoginRestrictionFailed		= 72,
	SKResultCodeAccountLocked					= 73,
	SKResultCodeAccountLogonDeniedVerifiedEmailRequired = 74,
	SKResultCodeNoMatchingURL			= 75,
	SKResultCodeBadResponse				= 76,
	SKResultCodeRequirePasswordReEntry	= 77,
	SKResultCodeValueOutOfRange			= 78,
	SKResultCodeUnexpectedError			= 79,
	SKResultCodeDisabled				= 80,
	SKResultCodeInvalidCEGSubmission	= 81,
	SKResultCodeRestrictedDevice		= 82,
	SKResultCodeRegionLocked			= 83,
	SKResultCodeRateLimitExceeded		= 84,
	SKResultCodeAccountLogonDeniedNeedTwoFactorCode = 85,
	SKResultCodeItemOrEntryHasBeenDeleted			= 86,
	SKResultCodeItemDeleted							= 86,
	SKResultCodeAccountLoginDeniedThrottle			= 87,
	SKResultCodeTwoFactorCodeMismatch				= 88,
};