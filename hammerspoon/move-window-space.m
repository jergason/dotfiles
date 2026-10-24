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
        uint64_t window = argc == 3 ? identifier(argv[1]) : 0;
        uint64_t space = argc == 3 ? identifier(argv[2]) : 0;
        if (!window || window > UINT32_MAX || !space) {
            fprintf(stderr, "Usage: move-window-space WINDOW_ID SPACE_ID\n");
            return 1;
        }
        id operation = [[operationClass alloc] initWithWindows:@[@(window)] spaceID:space];
        if (!operation) return 1;
        perform((__bridge void *)operation);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        return 0;
    }
}
