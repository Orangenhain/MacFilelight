/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLScanner.h"
#import "FLFile.h"

#include <sys/mount.h>
#include <sys/stat.h>
#include <fts.h>

// As defined in stat(2)
#define BLOCK_SIZE 512

#define UPDATE_EVERY 1000


// Utility function to make NSFileManager less painful
static NSString *stringPath(NSFileManager *fm, const FTSENT *ent) {
    return [fm stringWithFileSystemRepresentation: ent->fts_path
                                           length: ent->fts_pathlen];
}

@interface FLScanner ()

@property (strong) NSProgressIndicator *pi;
@property (strong) NSTextField *display;

@property (copy) NSString      *path;
@property (strong) FLDirectory *tree;
@property (strong) NSString    *error;

@property (assign) double    increment;
@property (assign) double    progress;
@property (strong) NSString *lastPath;

@property (assign) NSUInteger files;
@property (assign) NSUInteger seen;

@property (assign) SEL postSel;
@property (unsafe_unretained) id  postObj;

@property (strong) NSLock *lock;
@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;

@end

@implementation FLScanner

- (id) initWithPath: (NSString *) path
           progress: (NSProgressIndicator *) progress
            display: (NSTextField *) display
{
    if (self = [super init]) {
        self.path = path;
        self.pi = progress;
        self.display = display;
        self.lock = [[NSLock alloc] init];
        self.cancelled = NO;
    }
    return self;
}


- (FLDirectory *) scanResult
{
    return self.tree;
}

- (NSString *) scanError
{
    return self.error;
}

- (BOOL) isCancelled
{
    BOOL b;
    [self.lock lock];
    b = _cancelled;
    [self.lock unlock];
    return b;
}

- (void) cancel
{
    [self.lock lock];
    _cancelled = YES;
    [self.lock unlock];
}

- (void) updateProgress
{
    ++self.seen;
    self.progress += self.increment;
    
    if (self.seen % UPDATE_EVERY == 0) {
        double real_prog = self.files ? (100.0 * self.seen / self.files) : self.progress;
        NSDictionary *data = @{@"progress": @(real_prog), @"path": self.lastPath};
        
        SEL sel = @selector(updateProgressOnMainThread:);
        [self performSelectorOnMainThread: sel
                               withObject: data
                            waitUntilDone: NO];
    }
}

- (void) updateProgressOnMainThread: (NSDictionary *) data
{
    [self.pi setDoubleValue: [data[@"progress"] doubleValue]];
	NSString *p;
	if ((p = data[@"path"]))
		[self.display setStringValue: p];
}

- (BOOL) error: (int __attribute__ ((unused))) err inFunc: (NSString *) func
{
    self.error = [[NSString alloc] initWithFormat: @"%@: %s", func, strerror(errno)];
    return NO;
}

- (void) scanThenPerform: (SEL) sel on: (id) obj
{
    self.postSel = sel;
    self.postObj = obj;
    
    [NSThread detachNewThreadSelector: @selector(scanOnWorkerThread:)
                             toTarget: self
                           withObject: nil];
}

- (NSUInteger) numberOfResourcesOnVolume:(NSString *)volumePath
{
    NSURL   *volumeURL = [NSURL fileURLWithPath:volumePath];
    id       value     = nil;
    NSError *error     = nil;
    
    // resourceCount = kFSVolInfoDirCount + kFSVolInfoFileCount
    [volumeURL getResourceValue:&value
                         forKey:NSURLVolumeResourceCountKey
                          error:&error];
    
    if (error || ( [value isKindOfClass:[NSNumber class]] == NO ) )
    {
        NSLog(@"ERROR: could not get numberOfResourcesOnVolume: %@ - %@\n%@", volumePath, value, error);
        return NSNotFound;
    }
    
    return [(NSNumber *)value unsignedIntegerValue];
}

+ (BOOL) isMountPoint: (NSString *) path
{
    return [self isMountPointCPath: [path fileSystemRepresentation]];
}

+ (BOOL) isMountPointCPath: (const char *) cpath
{
    struct statfs st;
    int err = statfs(cpath, &st);
    return !err && strcmp(cpath, st.f_mntonname) == 0;
}

// We can give more accurate progress if we're working on a complete disk
- (void) checkIfMount: (const char *) cpath
{
    self.files = 0;
    if ([FLScanner isMountPointCPath: cpath]) {
        NSUInteger resourceCount = [self numberOfResourcesOnVolume:@(cpath)];
        if (resourceCount != NSNotFound) {
            self.files = resourceCount;
        }
    }
}

- (BOOL) realScan
{
    char *fts_paths[2];
    FTS *fts;
    FTSENT *ent;
    NSMutableArray *dirstack;
    NSFileManager *fm;
    FLDirectory *dir;
    char *cpath;
    
    self.progress = 0.0;
    self.increment = 100.0;
	self.lastPath = nil;
    self.seen = 0;
    
    errno = 0; // Why is this non-zero here?
    
    // Silly constness issues
    cpath = strdup([self.path fileSystemRepresentation]);
    [self checkIfMount: cpath];
    fts_paths[0] = cpath;
    fts_paths[1] = NULL;
    fts = fts_open(fts_paths, FTS_PHYSICAL | FTS_XDEV, NULL);
    free(fts_paths[0]);
    if (errno) return [self error: errno inFunc: @"fts_open"];
    
    fm = [NSFileManager defaultManager];
    dirstack = [[NSMutableArray alloc] init];
    dir = NULL;
    
    while (( ent = fts_read(fts) )) {
        if (self.seen % UPDATE_EVERY == 0 && [self isCancelled]) {
            self.error = @"Scan cancelled";
            return NO;
        }
        
		BOOL err = NO, pop = NO;
		
        switch (ent->fts_info) {
            case FTS_D: {
                dir = [[FLDirectory alloc] initWithPath: stringPath(fm, ent)
                                                 parent: dir];
				self.lastPath = [dir path];
                [dirstack addObject: dir];
                self.increment /= ent->fts_statp->st_nlink; // pre, children, post
                if (!self.tree) {
                    self.tree = dir;
                }
                break;
            }
                
            case FTS_DEFAULT:
            case FTS_F:
            case FTS_SL:
            case FTS_SLNONE: {
                FLFile *file = [[FLFile alloc]
                    initWithPath: stringPath(fm, ent)
                            size:(FLFile_size)(ent->fts_statp->st_blocks * BLOCK_SIZE)];
                self.lastPath = [file path];
                [dir addChild: file];
				break;
            }
			
			case FTS_DNR:
				err = pop = YES;
				break;
                
            case FTS_DP:
				pop = YES;
                break;
                
            default:
				err = YES;
				// we can get an error on exiting a dir!
				pop = ent->fts_path && [[dir path] isEqualToString:
					stringPath(fm, ent)];
        }
		
		if (err) {
			NSLog(@"Error scanning '%s': %s\n", ent->fts_path, strerror(ent->fts_errno));
		}
		
		[self updateProgress];
		if (pop) {
				self.increment *= ent->fts_statp->st_nlink;
                FLDirectory *subdir = dir;
                [dirstack removeLastObject];
                dir = [dirstack lastObject];
                if (dir) {
                    [dir addChild: subdir];
                }
		}
    }
    if (errno) return [self error: errno inFunc: @"fts_read"];
    
    if (fts_close(fts) == -1) return [self error: errno inFunc: @"fts_close"];    
    return YES;
}

- (void) scanOnWorkerThread: (id __attribute__ ((unused))) data
{
    @autoreleasepool {
        [self realScan];
        [self.postObj performSelectorOnMainThread: self.postSel
                                       withObject: nil
                                    waitUntilDone: YES];
    }
}


@end
