//
//  ViewController.m
//  h5jiaohu
//
//  Created by ve2 on 2018/5/21.
//  Copyright © 2018年 ve2. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate>
@property (nonatomic,strong) UIWebView *webView;
@property (nonatomic,strong) WKWebView *wkWebView;

@property (nonatomic,strong) UIButton *item;
@end

@implementation ViewController
#define js_showMessage @"showMessage"
#define js_ChangedMessage @"ChangedMessage"

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //    [self configWebView];
    
    
    [self configWKWebView];
    
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(150, 50, 100, 30)];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"Native调JS" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    _item = [[UIButton alloc]initWithFrame:CGRectMake(150, 600, 100, 30)];
    _item.backgroundColor = [UIColor yellowColor];
    [_item setTitle:@"按钮" forState:UIControlStateNormal];
    [_item setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_item addTarget:self action:@selector(itemClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_item];
}

-(void)itemClicked
{
    _item.selected = !_item.selected;
    
    if (_item.selected) {
        [_item setBackgroundColor:[UIColor greenColor]];
        
    }else{
        [_item setBackgroundColor:[UIColor yellowColor]];
    }
}
-(void)btnClicked
{
    NSMutableString *performJSString = [NSMutableString string];
    [performJSString appendString:@"alert('JS被OC调用');"];
    [performJSString appendString:@"document.getElementById('button2').style.backgroundColor='blue';"];
    [performJSString appendString:@"document.getElementById('button1').style.backgroundColor='red';"];
    [performJSString appendString:@"document.getElementById('button2').innerHTML='我被OC调用了';"];
    
    
    //执行JS代码
    [self.wkWebView evaluateJavaScript:performJSString completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        NSLog(@"response: %@ error: %@", response, error);
    }];
    
    //    //调用JS函数
    //    [self.wkWebView evaluateJavaScript:@"buttonOCCallJS()" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
    //        NSLog(@"%@ %@",response,error);
    //    }];
    
    
    //    //调用JS注入代码
    //    [self.wkWebView evaluateJavaScript:@"scriptF()" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
    //                NSLog(@"%@ %@",response,error);
    //            }];
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:js_showMessage];
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:js_ChangedMessage];
    
}

- (void)configWebView{
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:path]];
    [self.webView loadRequest:request];
}

- (void)configWKWebView{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    WKUserContentController *userCC = config.userContentController;
    //注册JS传递回调的方法名
    [userCC addScriptMessageHandler:self name:js_showMessage];
    [userCC addScriptMessageHandler:self name:js_ChangedMessage];
    
    
    self.wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.wkWebView.UIDelegate = self;
    self.wkWebView.navigationDelegate = self;
    [self.view addSubview:self.wkWebView];
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"index.html" withExtension:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:path];
    [self.wkWebView loadRequest:request];
    
    //JS注入
    NSString *scriptString = @"function scriptF(){alert('执行JS注入代码');}";
    WKUserScript *script = [[WKUserScript alloc]initWithSource:scriptString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [self.wkWebView.configuration.userContentController addUserScript:script];
}




//完全加载完网页
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"didFinishNavigation");
    
    
}

-(void)userContentController:(WKUserContentController*)userContentController didReceiveScriptMessage:(WKScriptMessage*)message
{
    NSLog(@"message.body：%@",message.body);
    
    if([message.name isEqualToString:js_showMessage]) {
        UIAlertView *alerView = [[UIAlertView alloc]initWithTitle:nil message:@"JS调用OC" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil];
        [alerView show];
        [self itemClicked];
        if ([message.body isKindOfClass:[NSString class]]) {
            [_item setTitle:message.body forState:UIControlStateNormal];
        }
    }else if ([message.name isEqualToString:js_ChangedMessage] ){
        [self itemClicked];
        if ([message.body isKindOfClass:[NSString class]]) {
            [_item setTitle:message.body forState:UIControlStateNormal];
        }
    }
}




#pragma mark -
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
    
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
@end
