//
//  ViewController.m
//  ReadReativeCocoa
//
//  Created by Bryant Reyn on 2020/4/7.
//  Copyright © 2020 Bryant Reyn. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface ViewController ()
@property (nonatomic,strong)RACCommand *command;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self RACSubject];
}

- (void)RACSignal{
    //1.创建信号
    RACSignal *singal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        //3.发送信号
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        [subscriber sendCompleted];
        
        return [RACDisposable disposableWithBlock:^{
            NSLog(@"RACDisposable...");
        }];
    }];
    
    //2.订阅信号
    [singal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

- (void)RACSubject{
    //1.Subject信号
    RACSubject *subject = [RACSubject subject];
    
    //2.订阅信号
    [subject subscribeNext:^(id x) {
        NSLog(@"订阅者1:%@",x);
    }];
    
    //3.发送信号
    [subject sendNext:@"1"];
    
    [subject subscribeNext:^(id x) {
        NSLog(@"订阅者2:%@",x);
    }];
    [subject sendNext:@"2"];
    
    [subject subscribeNext:^(id x) {
        NSLog(@"订阅者3:%@",x);
    }];
    [subject sendNext:@"3"];
    
    [subject sendCompleted];
}

- (void)RACReplaySubject{
    //1.重复信号
    RACReplaySubject *replaySubject = [RACReplaySubject subject];
    
    //3.发送信号
    [replaySubject sendNext:@"1"];
    
    //2.订阅信号
    [replaySubject subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

- (void)RacArray{
    NSArray *numbers = @[@1,@2,@3,@4];
    //1.把数组转换为集合RACSequence,在转换成为信号 -- 内部signal已经发送了数据
    [numbers.rac_sequence.signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];

    RACSequence *seq = numbers.rac_sequence;
    NSLog(@"%@",seq.head);
    seq.name = @"CreaterOS";
    NSLog(@"%@",seq.tail);
}

- (void)RacDictionary{
    NSDictionary *dict = @{@"name":@"CreaterOS",@"age":@20};
    [dict.rac_sequence.signal subscribeNext:^(id x) {
        //NSLog(@"%@",x);
        //解包成为元组
        RACTupleUnpack(NSString *key,NSString *value) = x;
        NSLog(@"%@ %@",key,value);
    }];
}

- (void)RACMulticastConnection{
    //1.创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"热门模块的数据"];
        
        return nil;
    }];
    
    //2.把信号转换为连接类
    //    RACMulticastConnection *connection = [signal publish];
    
    /* publish调用时候，实际上调用multicast方法 */
    /* 订阅信号，也不能激活信号，只是保存订阅者到数组，必须通过连接,当调用连接，就会一次性调用所有订阅者的sendNext */
    RACMulticastConnection *connection = [signal multicast:[RACReplaySubject subject]];
    
    
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"订阅者1:%@",x);
    }];
    
    
    [connection.signal subscribeNext:^(id x) {
        NSLog(@"订阅者2:%@",x);
    }];
    
    
    [connection connect];
}

- (void)RACCommand{
    RACCommand *command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@"请求数据"];
            [subscriber sendCompleted];
            return nil;
        }];
    }];
    self.command = command;
    
    [command.executionSignals subscribeNext:^(id x) {
        [x subscribeNext:^(id x) {
            NSLog(@"%@",x);
        }];
    }];
    [self.command execute:@1];
}

- (void)rac_textSignal{
    UITextField *textField = [[UITextField alloc] init];
    textField.text = @"rac_textSignal";
    [textField.rac_textSignal subscribeNext:^(id x) {
        NSLog(@"Show the rac text");
        NSLog(@"%@",x);
    }];
}
@end
