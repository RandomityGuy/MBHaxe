#define SDL_MAIN_HANDLED 1

#import <SDL.h>
#import <SDL_system.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#include <unistd.h>
#include <hl.h>

// ----------------------------------------------------------------------------
// iOS implementations of the src.Settings @:hlNative functions.
// Mirrors hashlink's sys_android.c (hl_open_web_url / hl_export_prefs /
// hl_start_import_prefs / hl_call_import_cb).
//
// The picker / share UI must run on the main (UI) thread, but the import
// callback is an HL closure and must be invoked on the HL game thread. So
// start_import_prefs only launches the picker and stashes the bytes; the
// closure is actually called from hl_call_import_cb, which the game loop runs
// on the HL thread.
// ----------------------------------------------------------------------------

static hl_mutex *import_cb_mutex = NULL;
static vclosure *importPrefsCb = NULL;
static char *importPrefsRes = NULL;        // malloc'd JSON from the UI thread
static bool importPrefsCbRooted = false;

// Walk to the top-most presented view controller so our sheets show above SDL's.
static UIViewController *MBHaxeTopViewController(void) {
    UIWindow *keyWindow = nil;
    for (UIWindow *w in UIApplication.sharedApplication.windows) {
        if (w.isKeyWindow) { keyWindow = w; break; }
    }
    if (keyWindow == nil)
        keyWindow = UIApplication.sharedApplication.windows.firstObject;
    UIViewController *vc = keyWindow.rootViewController;
    while (vc.presentedViewController != nil)
        vc = vc.presentedViewController;
    return vc;
}

@interface MBHaxeImportDelegate : NSObject <UIDocumentPickerDelegate>
@end

// Strong ref kept alive while the picker is on screen (delegate is held weakly).
static MBHaxeImportDelegate *importDelegate = nil;

@implementation MBHaxeImportDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (url != nil && import_cb_mutex != NULL) {
        BOOL scoped = [url startAccessingSecurityScopedResource];
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (scoped) [url stopAccessingSecurityScopedResource];
        if (data != nil) {
            hl_mutex_acquire(import_cb_mutex);
            if (importPrefsRes) free(importPrefsRes);
            importPrefsRes = (char *)malloc(data.length + 1);
            memcpy(importPrefsRes, data.bytes, data.length);
            importPrefsRes[data.length] = 0;
            hl_mutex_release(import_cb_mutex);
        }
    }
    importDelegate = nil;
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    importDelegate = nil;
}
@end

static NSString *MBHaxeSettingsFilePath(void) {
    NSString *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    return [docs stringByAppendingPathComponent:@"MBHaxe-MBU/settings.json"];
}

HL_PRIM void hl_open_web_url(vstring *url) {
    if (url == NULL || url->bytes == NULL) return;
    char *cstr = hl_to_utf8(url->bytes);
    NSString *s = [NSString stringWithUTF8String:cstr];
    NSURL *nsurl = [NSURL URLWithString:s];
    if (nsurl == nil) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:nsurl options:@{} completionHandler:nil];
    });
}

HL_PRIM void hl_export_prefs(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *path = MBHaxeSettingsFilePath();
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            SDL_Log("MBHaxe: export_prefs - no settings file at %s", path.UTF8String);
            return;
        }
        UIViewController *root = MBHaxeTopViewController();
        if (root == nil) return;
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        UIActivityViewController *avc =
            [[UIActivityViewController alloc] initWithActivityItems:@[ fileURL ]
                                             applicationActivities:nil];
        // iPad requires a popover anchor.
        avc.popoverPresentationController.sourceView = root.view;
        avc.popoverPresentationController.sourceRect =
            CGRectMake(CGRectGetMidX(root.view.bounds), CGRectGetMidY(root.view.bounds), 0, 0);
        avc.popoverPresentationController.permittedArrowDirections = 0;
        [root presentViewController:avc animated:YES completion:nil];
    });
}

HL_PRIM void hl_start_import_prefs(vclosure *cb) {
    if (import_cb_mutex == NULL) {
        import_cb_mutex = hl_mutex_alloc(false);
        hl_add_root(&import_cb_mutex);
    }
    hl_mutex_acquire(import_cb_mutex);
    importPrefsCb = cb;
    if (!importPrefsCbRooted) {
        hl_add_root((void **)&importPrefsCb);
        importPrefsCbRooted = true;
    }
    if (importPrefsRes) { free(importPrefsRes); importPrefsRes = NULL; }
    hl_mutex_release(import_cb_mutex);

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *root = MBHaxeTopViewController();
        if (root == nil) return;
        UIDocumentPickerViewController *picker =
            [[UIDocumentPickerViewController alloc]
                initForOpeningContentTypes:@[ UTTypeJSON, UTTypePlainText, UTTypeData ]];
        picker.allowsMultipleSelection = NO;
        importDelegate = [[MBHaxeImportDelegate alloc] init];
        picker.delegate = importDelegate;
        [root presentViewController:picker animated:YES completion:nil];
    });
}

HL_PRIM void hl_call_import_cb(void) {
    if (import_cb_mutex == NULL) return;
    hl_mutex_acquire(import_cb_mutex);
    if (importPrefsRes != NULL && importPrefsCb != NULL) {
        vdynamic arg;
        arg.t = &hlt_bytes;
        arg.v.bytes = (vbyte *)importPrefsRes;
        vdynamic *args[1] = { &arg };
        hl_dyn_call(importPrefsCb, args, 1);

        free(importPrefsRes);
        importPrefsRes = NULL;
        importPrefsCb = NULL;
    }
    hl_mutex_release(import_cb_mutex);
}

#ifdef __cplusplus
extern "C" {
#endif
int hl_unused_hlc_main(int argc, char *argv[]);
#ifdef __cplusplus
}
#endif

static int mbhaxe_sdl_main(int argc, char *argv[]) {
    SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
    SDL_SetHint(SDL_HINT_IOS_HIDE_HOME_INDICATOR, "2");
    SDL_SetHint(SDL_HINT_VIDEO_HIGHDPI_DISABLED, "0");
    SDL_SetHint(SDL_HINT_RETURN_KEY_HIDES_IME, "1");

    SDL_SetMainReady();

    char *base = SDL_GetBasePath();
    if (base != NULL) {
        chdir(base);
        SDL_Log("MBHaxe cwd set to %s", base);
        SDL_free(base);
    }

    char *fake_argv[] = { (char *)"MBHaxe", NULL };
    return hl_unused_hlc_main(1, fake_argv);
}
int main(int argc, char *argv[]) {
    return SDL_UIKitRunApp(argc, argv, mbhaxe_sdl_main);
}
