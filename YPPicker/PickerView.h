//
//  PickerView.h
//  AddressDemo
//
//  Created by BiuKia on 16/12/13.
//  Copyright © 2016年 YEEPAY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PickerView : UIView

typedef NS_ENUM(NSInteger, ParseDataType){
    ParseDataTypeJSON = 1,
    ParseDataTypePlist = 2,   //TODO暂不支持
};


/**
 展示一个选择器

 @param view container view
 @param fileName filename
 @param type ParseDataType
 @param fileSuffix fileSuffix
 @return pickerView
 */
+(PickerView *)showPickerAddTo:(UIView *)view
                withDataSource:(NSString *)fileName
                      dataType:(ParseDataType)type
                    fileSuffix:(NSString *)fileSuffix;


/**
 隐藏所有的pickerview

 @param view superview
 @return pickerview count
 */
+(NSInteger)hideAllPicker:(UIView *)view;

/**
 show

 @param confirmResult back result {"child":[{"name":"北京","code":"0101"}],"name":"北京","code":"01"}
 */
-(void)show:(void (^)(NSDictionary * result))confirmResult;

/**
 removed when hide
 */
-(void)hide;

@end
