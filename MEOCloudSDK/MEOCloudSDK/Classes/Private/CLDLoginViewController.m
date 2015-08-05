//
//  CLDLoginViewController.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/04/14.
//
//

#import "CLDLoginViewController.h"

typedef void(^CLDLoginViewControllerFailureBlock)(NSError *error);

@interface CLDLoginViewController () <UIWebViewDelegate>
@property (strong, nonatomic) CLDSession *session;
@property (strong, nonatomic) CLDSessionConfiguration *configuration;
@property (weak, nonatomic) UIWebView *webView;
@property (copy, nonatomic) CLDSessionValidateCallbackURLBlock validateCallbackURL;
@property (copy, nonatomic) void(^resultBlock)(void);
@property (copy, nonatomic) void(^failureBlock)(NSError *error);
@property (weak, nonatomic) UIButton *backButton;
@property (weak, nonatomic) UIButton *forwardButton;
@end

@implementation CLDLoginViewController

- (instancetype)initWithSession:(CLDSession *)session
                  configuration:(CLDSessionConfiguration *)configuration
                    resultBlock:(void (^)())resultBlock
                   failureBlock:(void (^)(NSError *))failureBlock {
    self = [super init];
    if (self) {
        self.session = session;
        self.title = [self.session _serviceName];
        self.configuration = configuration;
        self.resultBlock = resultBlock;
        self.failureBlock = failureBlock;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;
    [self.view addSubview:webView];
    self.webView = webView;
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(touchedCancelButton)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    UIImage *backButtonImage = [CLDDrawables imageOfLoginNavigationButtonWithRotation:0.0f];
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:backButtonImage forState:UIControlStateNormal];
    backButton.frame = CGRectMake(0.0, 0.0, backButtonImage.size.width, backButtonImage.size.height);
    backButton.enabled = NO;
    [backButton addTarget:self.webView action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    self.backButton = backButton;
    
    UIImage *forwardButtonImage = [CLDDrawables imageOfLoginNavigationButtonWithRotation:180.0f];
    UIButton *forwardButton = [[UIButton alloc] init];
    [forwardButton setImage:forwardButtonImage forState:UIControlStateNormal];
    forwardButton.frame = CGRectMake(0.0, 0.0, forwardButtonImage.size.width, forwardButtonImage.size.height);
    forwardButton.enabled = NO;
    [forwardButton addTarget:self.webView action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
    self.forwardButton = forwardButton;
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = 30.0;
    
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:forwardButton],
                                                spacer,
                                                [[UIBarButtonItem alloc] initWithCustomView:backButton]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.session linkSessionWithConfiguration:self.configuration URLBlock:^(NSURL *url, CLDSessionValidateCallbackURLBlock validateCallbackURL) {
        self.validateCallbackURL = validateCallbackURL;
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    } resultBlock:^{
        RunBlockOnMainThread(self.resultBlock);
    } failureBlock:^(NSError *error) {
        RunBlockOnMainThread(self.failureBlock, error);
    }];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL valid = self.validateCallbackURL(request.URL);
    return !valid;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.backButton.enabled = webView.canGoBack;
    self.forwardButton.enabled = webView.canGoForward;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.backButton.enabled = webView.canGoBack;
    self.forwardButton.enabled = webView.canGoForward;
}

- (void)touchedCancelButton {
    RunBlockOnMainThread(self.failureBlock, [CLDError errorWithCode:CLDErrorCancelledByUser]);
}

@end
