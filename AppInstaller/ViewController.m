//
//  ViewController.m
//  AppInstaller
//
//  Created by Artem on 04/12/14.
//  Copyright (c) 2014 Globus-ltd. All rights reserved.
//

#import "ViewController.h"
#import "DragView.h"
#import "LibraryChecker.h"

@interface ViewController () <DragViewDelegate>
@property (weak) IBOutlet NSButton *installLibrariesButton;
@property (weak) IBOutlet NSTextField *hintLabel;
@property (weak) IBOutlet DragView *dragAndDropView;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet WebView *webView;
@property (strong, nonatomic) NSTask *task;

@end

@implementation ViewController

#pragma mark - 
#pragma mark - DragViewDelegate

- (void)draggedFileAtPath:(NSURL *)path {
    [self uploadIPA:path];
}

#pragma mark -
#pragma mark - Uploading

- (void)uploadIPA:(NSURL *)url {
    
    self.textView.string = @"";
    [self.textView scrollToBeginningOfDocument:nil];
    self.hintLabel.stringValue = @"Processing...";
    self.dragAndDropView.dragAndDropEnabled = YES;
    self.dragAndDropView.hidden = YES;
    [self.progressIndicator startAnimation:nil];
    
    self.task = [[NSTask alloc] init];
    NSString *installerPath = [[NSBundle mainBundle] pathForResource:@"ideviceinstaller" ofType:nil];
    [self.task setLaunchPath:installerPath];
    NSString *path = url.path;
    [self.task setArguments:@[@"-i", path]];
    
    
    NSPipe *p = [NSPipe pipe];
    [self.task setStandardOutput:p];
    NSFileHandle *fh = [p fileHandleForReading];
    [fh waitForDataInBackgroundAndNotify];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:fh];
    
    __weak typeof(self) weakSelf = self;
    [self.task setTerminationHandler:^(NSTask *task) {
        weakSelf.hintLabel.stringValue = @"Drag and Drop IPA here";
        weakSelf.dragAndDropView.dragAndDropEnabled = YES;
        weakSelf.dragAndDropView.hidden = NO;
        [weakSelf.progressIndicator stopAnimation:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:fh];
    }];
//
    [self.task launch];
}

- (void)receivedData:(NSNotification *)notif {
    NSFileHandle *fh = [notif object];

    NSData *data = [fh availableData];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSString *text = self.textView.string;
    self.textView.string = [text stringByAppendingString:str];
    [self.textView scrollLineDown:nil];
    [self.textView scrollLineDown:nil];
    
    if ([str containsString:@"Install - Complete"]) {
        [self.task terminate];
    } else {
        [fh waitForDataInBackgroundAndNotify];
    }
    
}

#pragma mark -
#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self checkLibraries];
    self.hintLabel.stringValue = @"Drag and Drop IPA here";
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AdventureTime" ofType:@"gif"];
    NSURL *url = [NSURL fileURLWithPath:path];
    [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark -
#pragma mark - Library checker

- (void)checkLibraries {
    BOOL librariesInstalled = [LibraryChecker isLibraryInstalled];
    self.installLibrariesButton.hidden = librariesInstalled;
    self.hintLabel.hidden = !librariesInstalled;

}

- (IBAction)installLibraries:(id)sender {

    BOOL success = [LibraryChecker installLibraries];
    self.installLibrariesButton.hidden = success;
    self.hintLabel.hidden = !success;
}


@end
