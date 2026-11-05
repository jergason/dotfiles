// Bridged operation from https://github.com/Hammerspoon/hammerspoon/pull/3889.
// The legacy window-to-space calls silently do nothing on macOS Tahoe.
#import <Cocoa/Cocoa.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <errno.h>

@interface NSObject (WindowSpaceOperation)
- (instancetype)initWithWindows:(NSArray *)windows spaceID:(uint64_t)spaceID;
@end

typedef int64_t (*PerformOperation)(void *);
static const char *skyLightPath = "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight";

static PerformOperation moveOperation(void) {
    const char *symbolName = "__ZL54SLSPerformAsynchronousBridgedWindowManagementOperationP47SLSAsynchronousBridgedWindowManagementOperation";
    for (uint32_t image = 0; image < _dyld_image_count(); image++) {
        if (strcmp(_dyld_get_image_name(image), skyLightPath) != 0) continue;
        const struct mach_header_64 *header = (const void *)_dyld_get_image_header(image);
        if (header->magic != MH_MAGIC_64) return NULL;
        const struct segment_command_64 *linkedit = NULL;
        const struct symtab_command *symtab = NULL;
        const uint8_t *cursor = (const void *)(header + 1);
        for (uint32_t i = 0; i < header->ncmds; i++) {
            const struct load_command *command = (const void *)cursor;
            if (command->cmd == LC_SEGMENT_64) {
                const struct segment_command_64 *segment = (const void *)command;
                if (strcmp(segment->segname, SEG_LINKEDIT) == 0) linkedit = segment;
            } else if (command->cmd == LC_SYMTAB) {
                symtab = (const void *)command;
            }
            cursor += command->cmdsize;
        }
        if (!linkedit || !symtab) return NULL;
        intptr_t slide = _dyld_get_image_vmaddr_slide(image);
        uintptr_t base = slide + linkedit->vmaddr - linkedit->fileoff;
        const char *strings = (const void *)(base + symtab->stroff);
        const struct nlist_64 *symbols = (const void *)(base + symtab->symoff);
        for (uint32_t i = 0; i < symtab->nsyms; i++) {
            if (symbols[i].n_un.n_strx && strcmp(strings + symbols[i].n_un.n_strx, symbolName) == 0) {
                return (PerformOperation)(slide + symbols[i].n_value);
            }
        }
    }
    return NULL;
}

static uint64_t identifier(const char *text) {
    char *end;
    errno = 0;
    uint64_t value = strtoull(text, &end, 10);
    return errno || end == text || *end || *text == '-' ? 0 : value;
}

int main(int argc, const char **argv) {
    @autoreleasepool {
        dlopen(skyLightPath, RTLD_LAZY);
        PerformOperation perform = moveOperation();
        Class operationClass = NSClassFromString(@"SLSBridgedMoveWindowsToManagedSpaceOperation");
        if (!perform || ![operationClass instancesRespondToSelector:@selector(initWithWindows:spaceID:)]) {
            fprintf(stderr, "This macOS version does not support background desktop placement.\n");
            return 1;
        }
        if (argc == 2 && strcmp(argv[1], "--check") == 0) return 0;
        if (argc < 3 || argc % 2 == 0) {
            fprintf(stderr, "Usage: move-window-space WINDOW_ID SPACE_ID [WINDOW_ID SPACE_ID ...]\n");
            return 2;
        }
        int count = (argc - 1) / 2;
        uint64_t windows[count], spaces[count];
        for (int i = 0; i < count; i++) {
            windows[i] = identifier(argv[2 * i + 1]);
            spaces[i] = identifier(argv[2 * i + 2]);
            if (!windows[i] || windows[i] > UINT32_MAX || !spaces[i]) {
                fprintf(stderr, "Invalid window or space ID: %s %s\n", argv[2 * i + 1], argv[2 * i + 2]);
                return 2;
            }
        }
        int failed = 0;
        for (int i = 0; i < count; i++) {
            id operation = [[operationClass alloc] initWithWindows:@[@(windows[i])] spaceID:spaces[i]];
            if (!operation) {
                fprintf(stderr, "Cannot create a move for window %llu\n", windows[i]);
                failed = 1;
                continue;
            }
            perform((__bridge void *)operation);
        }
        // The operations are asynchronous; one run-loop spin lets all of them reach WindowServer.
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        return failed ? 3 : 0;
    }
}
