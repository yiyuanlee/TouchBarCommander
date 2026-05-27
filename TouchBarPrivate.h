#ifndef TouchBarPrivate_h
#define TouchBarPrivate_h

#import <AppKit/AppKit.h>

#ifdef __cplusplus
extern "C" {
#endif

// Private function to register a custom Control Strip identifier
extern void DFRElementSetControlStripPresenceForIdentifier(NSTouchBarItemIdentifier identifier, BOOL presence);

#ifdef __cplusplus
}
#endif

// Private category to add a custom item to the system Control Strip tray
@interface NSTouchBarItem (PrivateMethods)
+ (void)addSystemTrayItem:(NSTouchBarItem *)item;
@end

// Private category to present and dismiss a global system modal touch bar
@interface NSTouchBar (PrivateMethods)
+ (void)presentSystemModalFunctionBar:(NSTouchBar *)touchBar systemTrayItemIdentifier:(NSTouchBarItemIdentifier)identifier;
+ (void)dismissSystemModalFunctionBar:(NSTouchBar *)touchBar;
@end

#endif /* TouchBarPrivate_h */
