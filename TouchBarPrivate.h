#ifndef TouchBarPrivate_h
#define TouchBarPrivate_h

#import <AppKit/AppKit.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

// Private category to add a custom item to the system Control Strip tray
@interface NSTouchBarItem (PrivateMethods)
+ (void)addSystemTrayItem:(NSTouchBarItem *)item;
@end

// Private category to present and dismiss a global system modal touch bar
// macOS 10.14+ uses presentSystemModalTouchBar, older used presentSystemModalFunctionBar
@interface NSTouchBar (PrivateMethods)
+ (void)presentSystemModalTouchBar:(NSTouchBar *)touchBar placement:(long long)placement systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalTouchBar:(NSTouchBar *)touchBar;
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar;
@end

#endif /* TouchBarPrivate_h */
