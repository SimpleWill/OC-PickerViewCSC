//
//  PickerView.m
//  AddressDemo
//
//  Created by BiuKia on 16/12/13.
//  Copyright © 2016年 YEEPAY. All rights reserved.
//

#import "PickerView.h"

CGFloat const kpickerViewHeight = 241;
NSInteger kpickerMaxLen = 8;   //用以记录第二个最大的长度
NSInteger kpickerComponent = 2;  //默认为2

typedef void(^ConfrimBlock)(NSDictionary * confirm);

@interface PickerView ()<UIPickerViewDataSource,UIPickerViewDelegate>
@property (strong, nonatomic) UIView * coverView;
@property (strong, nonatomic) UIView * dateView;
@property (strong, nonatomic) UIButton * ok;
@property (strong, nonatomic) UIButton * cancel;
@property (strong, nonatomic) UIPickerView * picker;

@property (strong, nonatomic) NSDictionary<NSString *, id> *dataDict;
@property (strong, nonatomic) NSArray<NSString *> *firstArr;
@property (strong, nonatomic) NSArray * secondArr;

@property (strong, nonatomic) NSLayoutConstraint * dateViewCst;
@property (assign, nonatomic,getter=isShow) BOOL show;

@property (copy,   nonatomic) ConfrimBlock confirm;
@property (strong, nonatomic) NSMutableDictionary * confirmDic;
@end

@implementation PickerView
@synthesize ok;
@synthesize cancel;
@synthesize picker;

#pragma mark -- Class Method

+(NSString *)filePath:(NSString *)fileName dataType:(ParseDataType)type fileSuffix:(NSString *)suffix{
    return [[NSBundle mainBundle]pathForResource:fileName ofType:suffix];
}
#pragma mark -- Data Filter
+(NSDictionary *)packData:(NSString *)path {
    
    NSArray * arr = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:path] options:NSJSONReadingMutableContainers error:nil];
    if (!arr) {
        @throw [NSException exceptionWithName:@"Parse Error" reason:@"The file can't parse current" userInfo:nil];
    }
    kpickerMaxLen = 8;
    NSMutableDictionary<NSString* ,NSArray*> * packDict = [NSMutableDictionary dictionary];
    for (NSDictionary * dic in arr) {
        NSString * key = [NSString stringWithFormat:@"%@_%@",(dic[@"code"] ? dic[@"code"] : @"00") ,dic[@"name"]];
        if ([packDict.allKeys containsObject:key]) {
            NSMutableArray * info = [NSMutableArray arrayWithArray:packDict[dic[@"name"]]];
            [info addObjectsFromArray:dic[@"child"]];
            [packDict setValue:info forKey:key];
            [PickerView searchMaxLen:info];
        }else{
            NSArray * info = [NSArray arrayWithArray:dic[@"child"]];
            [packDict setValue:info forKey:key];
            [PickerView searchMaxLen:info];
        }
    }
    if([packDict[packDict.allKeys[0]] count] == 0){
        kpickerComponent = 1;
    }else kpickerComponent = 2;
    return packDict;
}

#pragma mark --- Find Max Len
+(void)searchMaxLen:(NSArray *)arr{
    for (NSDictionary * chileDic in arr) {
        NSString * name = chileDic[@"name"];
        if (name.length > kpickerMaxLen) {
            kpickerMaxLen = name.length;
        }
    }
}

#pragma mark -- Sort Data
+(NSArray *)sortData:(NSDictionary<NSString *,id> *)data{
    return [data.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString * key1 = [obj1 componentsSeparatedByString:@"_"][0];
        NSString * key2 = [obj2 componentsSeparatedByString:@"_"][0];
        return [key1 compare:key2 options:NSNumericSearch];
    }];
}

#pragma mark -- Get All Pickers
+ (NSArray *)allPicksForView:(UIView *)view {
    NSMutableArray *picks = [NSMutableArray array];
    NSArray *subviews = view.subviews;
    for (UIView *aView in subviews) {
        if ([aView isKindOfClass:self]) {
            [picks addObject:aView];
        }
    }
    return [NSArray arrayWithArray:picks];
}

#pragma mark -- Hide All Pickers
+(NSInteger)hideAllPicker:(UIView *)view{
    NSArray *picks = [PickerView allPicksForView:view];
    for (PickerView *pickv in picks) {
        [pickv removeFromSuperview];
    }
    return [picks count];
}

+(PickerView *)showPickerAddTo:(UIView *)view
                withDataSource:(NSString *)fileName
                      dataType:(ParseDataType)type
                    fileSuffix:(NSString *)fileSuffix{

    NSString * path = [PickerView filePath:fileName dataType:type fileSuffix:fileSuffix];
    if (!path) {
        @throw [NSException exceptionWithName:@"Parse Error" reason:@"The file can't parse current" userInfo:nil];
    }
    NSAssert(view, @"view can't be nil");
    PickerView * pickerView = [[self alloc]initWithFrame:CGRectZero contentPath:path];
    [view addSubview:pickerView];
    [pickerView addContraints];
    [pickerView setHidden:YES];
    return pickerView;
}

-(instancetype)initWithFrame:(CGRect)frame contentPath:(NSString *)path{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.dataDict = [PickerView packData:path];
        self.firstArr = [PickerView sortData:self.dataDict];
        [self setDateViewContentUI];
        NSInteger selectedFirstIndex = [self.picker selectedRowInComponent:0];
        NSString *seletedFirst = [self.firstArr objectAtIndex:selectedFirstIndex];
        if (kpickerComponent > 1) {
            self.secondArr = [self.dataDict objectForKey:seletedFirst];
        }
        [self initBackdata:selectedFirstIndex];
    }
    return self;
}

-(UIView *)coverView{
    if (!_coverView) {
        _coverView = [[UIView alloc]initWithFrame:CGRectZero];
        _coverView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.3];
        [_coverView setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return _coverView;
}

-(UIView *)dateView{
    if(!_dateView){
        _dateView = [[UIView alloc]initWithFrame:CGRectZero];
        _dateView.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.9];
        [_dateView setTranslatesAutoresizingMaskIntoConstraints:NO];
    }
    return _dateView;
}

-(NSMutableDictionary *)confirmDic{
    if (!_confirmDic) {
        _confirmDic = [NSMutableDictionary dictionary];
    }
    return _confirmDic;
}

#pragma mark --Init back data
-(void)initBackdata:(NSInteger)selectFirstIndex{
    NSString *seletedFirst = [self.firstArr objectAtIndex:selectFirstIndex];
    NSArray * selectFirstArr = [seletedFirst componentsSeparatedByString:@"_"];
    if (kpickerComponent > 1) {
        NSDictionary * subInfo = [self.secondArr objectAtIndex:0];
        [self.confirmDic addEntriesFromDictionary:@{@"name":selectFirstArr[1],@"code":selectFirstArr[0],@"child":subInfo}];
    }else{
        [self.confirmDic addEntriesFromDictionary:@{@"name":selectFirstArr[1],@"code":selectFirstArr[0]}];
    }
    
}


#pragma mark -- TapGesture
-(void)addTapGesture{
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
    [self.coverView addGestureRecognizer:tap];
}

-(void)tap:(UITapGestureRecognizer *)tapGesture{
    [self hide];
}

-(void)addConstraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1 relatedBy:(NSLayoutRelation)relation toItem:(nullable id)view2 attribute:(NSLayoutAttribute)attr2 multiplier:(CGFloat)multiplier constant:(CGFloat)c{
    [self addConstraintWithItem:view1 attribute:attr1 relatedBy:relation toItem:view2 attribute:attr2 multiplier:multiplier constant:c targetView:self];
}

-(void)addConstraintWithItem:(id)view1 attribute:(NSLayoutAttribute)attr1 relatedBy:(NSLayoutRelation)relation toItem:(nullable id)view2 attribute:(NSLayoutAttribute)attr2 multiplier:(CGFloat)multiplier constant:(CGFloat)c targetView:(UIView *)targetItem{
    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:view1 attribute:attr1 relatedBy:relation toItem:view2 attribute:attr2 multiplier:multiplier constant:c];
    [targetItem addConstraint:constraint];
}

#pragma mark -- Initial UI
-(void)setDateViewContentUI{
    
    [self addSubview:self.coverView];
    [self addSubview:self.dateView];
    [self addTapGesture];
    
    cancel = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancel setFrame:CGRectZero];
    cancel.titleLabel.font = [UIFont systemFontOfSize:14];
    [cancel setTitle:@"取消" forState:UIControlStateNormal];
    [cancel setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    cancel.tag = 10;
    cancel.translatesAutoresizingMaskIntoConstraints = NO;
    [cancel addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.dateView addSubview:cancel];
    
    ok = [UIButton buttonWithType:UIButtonTypeCustom];
    [ok setFrame:CGRectZero];
    ok.titleLabel.font = [UIFont systemFontOfSize:14];
    [ok setTitle:@"确定" forState:UIControlStateNormal];
    [ok setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    ok.tag = 20;
    ok.translatesAutoresizingMaskIntoConstraints = NO;
    [ok addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.dateView addSubview:ok];
    
    picker = [[UIPickerView alloc]init];
    picker.tag = 100;
    picker.delegate = self;
    picker.dataSource = self;
    picker.translatesAutoresizingMaskIntoConstraints = NO;
    picker.backgroundColor = [UIColor colorWithRed:153/255.0f green:153/255.0f blue:153/255.0f alpha:0.5];
    [self.dateView addSubview:picker];
    
}

#pragma mark -- Add initial Contraints
-(void)addContraints{
    
    NSArray * consArr = [@[[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:0 metrics:nil views:@{@"view":self}],[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:@{@"view":self}]]valueForKeyPath:@"@unionOfArrays.self"];
    [self.superview addConstraints:consArr];
    
    
    consArr = [@[[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[dateView]-0-|" options:0 metrics:nil views:@{@"dateView":self.dateView}]]valueForKeyPath:@"@unionOfArrays.self"];
    [self addConstraints:consArr];

    self.dateViewCst = [NSLayoutConstraint constraintWithItem:self.dateView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    [self addConstraint:self.dateViewCst];
    
    [self.dateView addConstraint:[NSLayoutConstraint constraintWithItem:self.dateView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kpickerViewHeight]];

    
    consArr = [@[[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[cancel(h)]" options:0 metrics:@{@"h":@(55)} views:@{@"cancel":cancel}],[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[cancel(v)]" options:0 metrics:@{@"v":@(40)} views:@{@"cancel":cancel}]]valueForKeyPath:@"@unionOfArrays.self"];
    [self.dateView addConstraints:consArr];


    consArr = [@[[NSLayoutConstraint constraintsWithVisualFormat:@"H:[ok(h)]-15-|" options:0 metrics:@{@"h":@(55)} views:@{@"ok":ok}],[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[ok(v)]" options:0 metrics:@{@"v":@(40)} views:@{@"ok":ok}]]valueForKeyPath:@"@unionOfArrays.self"];
    [self.dateView addConstraints:consArr];

    consArr = [@[[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[picker]-0-|" options:0 metrics:nil views:@{@"picker":picker}],[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-v-[picker]-0-|" options:0 metrics:@{@"v":@(40)} views:@{@"picker":picker}]]valueForKeyPath:@"@unionOfArrays.self"];
    [self.dateView addConstraints:consArr];
    
    consArr = [@[[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:0 metrics:nil views:@{@"view":self.coverView}],[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:@{@"view":self.coverView}]]valueForKeyPath:@"@unionOfArrays.self"];
    [self addConstraints:consArr];
}

-(void)setDataSource:(NSString *)fileName dataType:(ParseDataType)type fileSuffix:(NSString *)suffix{
    NSString * path = [PickerView filePath:fileName dataType:type fileSuffix:suffix];
    if (!path) {
        @throw [NSException exceptionWithName:@"Parse Error"
                                       reason:@"The file can't parse current"
                                     userInfo:nil];
    }
    self.dataDict = [PickerView packData:path];
    self.firstArr = [PickerView sortData:self.dataDict];
    
    NSInteger selectedFirstIndex = [self.picker selectedRowInComponent:0];
    NSString *seletedFirst = [self.firstArr objectAtIndex:selectedFirstIndex];
    self.secondArr = [self.dataDict objectForKey:seletedFirst];
    [self initBackdata:selectedFirstIndex];
    [self.picker reloadAllComponents];
}

-(void)show:(void (^)(NSDictionary *))confirmResult{
    NSAssert([NSThread isMainThread], @"PickerView needs to be show on the main thread.");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.confirm = confirmResult;
    if (self.isShow) {
        return;
    }
    [NSThread sleepForTimeInterval:0.1];
    [UIView animateWithDuration:0.05 animations:^{
        [self setHidden:NO];
    } completion:^(BOOL finished) {
        [self removeConstraint:self.dateViewCst];
        self.dateViewCst = [NSLayoutConstraint constraintWithItem:self.dateView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-kpickerViewHeight];
        [self addConstraint:self.dateViewCst];
        
        [UIView animateWithDuration:0.25 animations:^{
            [self setNeedsLayout];
            [self layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            self.show = YES;
        }];
    }];

}

-(void)hide{
    NSAssert([NSThread isMainThread], @"PickerView needs to be hide on the main thread.");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (!self.isShow) {
        return;
    }
    [self removeConstraint:self.dateViewCst];
    self.dateViewCst = [NSLayoutConstraint constraintWithItem:self.dateView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    [self addConstraint:self.dateViewCst];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.show = NO;
        [self.picker selectRow:0 inComponent:0 animated:NO];
        [UIView animateWithDuration:0.1 animations:^{
            self.alpha = 0.1;
        } completion:^(BOOL finished) {
            self.alpha = 1.0;
            [self setHidden:YES];
            [self clearAllPropertys];
            [self removeFromSuperview];
        }];
    }];
}

-(void)clearAllPropertys{
    [self.coverView removeFromSuperview];
    [self.ok removeFromSuperview];
    [self.cancel removeFromSuperview];
    [self.dateView removeFromSuperview];
    self.coverView = nil;
    self.ok = nil;
    self.cancel = nil;
    self.picker = nil;
    self.dateView = nil;
    self.dataDict = nil;
    self.firstArr = nil;
    self.secondArr =nil;
    self.dateViewCst = nil;
    self.confirmDic = nil;
}

#pragma mark -- Private Method

-(void)buttonClicked:(UIButton *)button{
    if (button.tag == 20) {//确定
        if (self.confirm) {
            self.confirm(self.confirmDic);
            self.confirm = NULL;
        }
    }else{//取消 取消没有数据返回
    }
    [self hide];
}

#pragma mark -- UIPickerViewDataSource UIPickerViewDelegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return kpickerComponent;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    switch (component) {
        case 0:{
            return self.firstArr.count;
        }
            break;
        case 1:{
            return self.secondArr.count;
        }
            break;
        default:
            break;
    }
    return 0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
    if(kpickerComponent == 1){
        return self.frame.size.width;
    }else{
        if (kpickerMaxLen == 8) {
            return self.frame.size.width/2;
        }else{
            if (component == 1) {
                return self.frame.size.width/3*2;
            }else
                return self.frame.size.width/3;
        }
    }
}
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return 35;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    switch (component) {
        case 0:{
            return [self.firstArr[row]componentsSeparatedByString:@"_"][1];
        }
            break;
        case 1:{
            NSDictionary * childDic = self.secondArr[row];
            return childDic[@"name"];
        }
            break;
        default:
            break;
    }
    return 0;
}
- (nullable NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [[NSAttributedString alloc]initWithString:[self pickerView:pickerView titleForRow:row forComponent:component] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14],NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view{
    UILabel* pickerLabel = (UILabel*)view;
    if (!pickerLabel){
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
        [pickerLabel setBackgroundColor:[UIColor clearColor]];
        [pickerLabel setFont:[UIFont boldSystemFontOfSize:14]];
    }
    pickerLabel.text=[self pickerView:pickerView titleForRow:row forComponent:component];
    return pickerLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if (component == 0) {
        NSString *seletedFirst = [self.firstArr objectAtIndex:row];
        NSArray * arr = [seletedFirst componentsSeparatedByString:@"_"];
        if (kpickerComponent > 1) {  //两个组件
            self.secondArr = [self.dataDict objectForKey:seletedFirst];
            
            [self.picker reloadComponent:1];
            
            NSInteger selectedSecondIndex = [self.picker selectedRowInComponent:1];
            NSDictionary * subInfo = [self.secondArr objectAtIndex:selectedSecondIndex];
            [self.confirmDic addEntriesFromDictionary:@{@"name":arr[1],@"code":arr[0],@"child":subInfo}];
        }else{    //一个组件
            [self.confirmDic addEntriesFromDictionary:@{@"name":arr[1],@"code":arr[0]}];
        }
    }
    else {
        NSInteger selectedFirstIndex = [self.picker selectedRowInComponent:0];
        NSString *seletedFirst = [self.firstArr objectAtIndex:selectedFirstIndex];
        
        NSDictionary * subInfo = [self.secondArr objectAtIndex:row];
        NSArray * arr = [seletedFirst componentsSeparatedByString:@"_"];
        [self.confirmDic addEntriesFromDictionary:@{@"name":arr[1],@"code":arr[0],@"child":subInfo}];
    }
}

/*
+ (BOOL) containChineseCharacter:(NSString *)characters{
    NSString *charactersRegex = @"^[\u4e00-\u9fa5]$";
    NSPredicate *charactersPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",charactersRegex];
    return [charactersPredicate evaluateWithObject:characters];
}

 #pragma mark -- 解析数据取出里面字段为Array的字段
 -(NSArray *)getSubInfoParseChildData:(NSDictionary *)data{
 NSArray * subArr = nil;
 for (NSString * key in data.allKeys) {
 if ([data[key] isKindOfClass:[NSArray class]]) {
 subArr = data[key];
 break;
 }
 }
 return subArr;
 }
 
 //TODO获取层数 有问题
 static inline int getSubInfoParseChildData(NSArray *sourceData){
 NSEnumerator *enumerator = sourceData.objectEnumerator;
 id obj;
 while ((obj = enumerator.nextObject)) {
 if ([obj isKindOfClass:[NSDictionary class]]) {
 NSDictionary * subInfo = (NSDictionary *)obj;
 NSEnumerator *subEnumerator = subInfo.objectEnumerator;
 while ((obj = subEnumerator.nextObject)) {
 if ([obj isKindOfClass:[NSArray class]]) {
 getSubInfoParseChildData((NSArray *)obj);
 }
 }
 }
 }
 return 2;
 }
 */
@end
