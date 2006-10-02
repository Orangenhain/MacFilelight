/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLScanner.h"


// As defined in stat(2)
#define BLOCK_SIZE 512


// Utility function to make NSFileManager less painful
static NSString *stringPath(NSFileManager *fm, const FTSENT *ent) {
    return [fm stringWithFileSystemRepresentation: ent->fts_path
                                           length: ent->fts_pathlen];
}

@implementation FLScanner

- (id) initWithPath: (NSString *) path
           progress: (NSProgressIndicator *) progress
            display: (NSTextField *) display
{
    if (self = [super init]) {
        m_path = [path retain];
        m_pi = [progress retain];
        m_display = [display retain];
        m_error = nil;
        m_tree = nil;
    }
    return self;
}

- (void) dealloc
{
    [m_path release];
    [m_pi release];
    [m_display release];
    if (m_tree) [m_tree release];
    if (m_error) [m_error release];
    [super dealloc];
}

- (FLDirectory *) scanResult
{
    return m_tree;
}

- (NSString *) scanError
{
    return m_error;
}


#define UPDATE_EVERY 100

- (void) updateProgressWithDir: (FLDirectory *) dir
{
    ++m_seen;
    m_progress += m_increment;
    
    if (m_seen % UPDATE_EVERY == 0) {
        [m_pi setDoubleValue: m_progress];
        [m_display setStringValue: [dir path]];
    }
}

- (BOOL) error: (int) err inFunc: (NSString *) func
{
    m_error = [[NSString alloc] stringWithFormat: @"%@: %s", func,
        strerror(errno)];
    return NO;
}

- (id) test {
     return m_test;
}

- (BOOL) scanWithWorker: (ThreadWorker *) tw
{
    char *fts_paths[2];
    FTS *fts;
    FTSENT *ent;
    NSMutableArray *dirstack;
    NSFileManager *fm;
    FLDirectory *dir;
    
    m_test = [[[NSArray alloc] init] objectEnumerator];
    
    m_progress = [m_pi minValue];
    m_increment = [m_pi maxValue] - m_progress;
    m_seen = 0;
    
    // Silly constness issues
    errno = 0; // Why is this needed?
    fts_paths[0] = strdup([m_path fileSystemRepresentation]);
    fts_paths[1] = NULL;
    fts = fts_open(fts_paths, FTS_PHYSICAL | FTS_XDEV, NULL);
    free(fts_paths[0]);
    if (errno) return [self error: errno inFunc: @"fts_open"];
    
    fm = [NSFileManager defaultManager];
    dirstack = [[[NSMutableArray alloc] init] autorelease];
    dir = NULL;
    
    while (( ent = fts_read(fts) )) {
        if (m_seen % UPDATE_EVERY == 0 && [tw cancelled]) {
            m_error = @"Scan cancelled";
            return NO;
        }
        
        switch (ent->fts_info) {
            case FTS_D: {
                dir = [[FLDirectory alloc] initWithPath: stringPath(fm, ent)];
                [dir autorelease];
                [dirstack addObject: dir];
                if (m_tree) {
                    [self updateProgressWithDir: dir];
                } else {
                    m_tree = dir;
                }
                m_increment /= (ent->fts_statp->st_nlink - 2);
                
                break;
            }
                
            case FTS_DEFAULT:
            case FTS_F:
            case FTS_SL:
            case FTS_SLNONE: {
                FLFile *file = [[FLFile alloc]
                    initWithPath: stringPath(fm, ent)
                            size: ent->fts_statp->st_blocks * BLOCK_SIZE];
                [file autorelease];
                [dir addChild: file];
                [self updateProgressWithDir: dir];
                break;
            }
                
            case FTS_DNR:
                NSLog(@"Can't scan in '%s': %s\n", ent->fts_path, strerror(ent->fts_errno));
                // Fall through!
                
            case FTS_DP: {
                m_increment *= (ent->fts_statp->st_nlink - 2);
                FLDirectory *subdir = dir;
                [dirstack removeLastObject];
                dir = [dirstack lastObject];
                if (dir) {
                    [dir addChild: subdir];
                }
                break;
            }
                
            default:
                NSLog(@"Error scanning '%s': %s\n", ent->fts_path, strerror(ent->fts_errno));
                break;
        }
    }
    if (errno) return [self error: errno inFunc: @"fts_read"];
    
    if (fts_close(fts) == -1) return [self error: errno inFunc: @"fts_close"];    
    return YES;
}

@end
